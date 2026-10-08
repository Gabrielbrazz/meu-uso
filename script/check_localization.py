#!/usr/bin/env python3
"""Checks that every user-facing string in the Swift sources has a pt-BR translation.

Collects the English keys the app looks up at runtime and compares them with
assets/Localization/pt-BR.lproj/Localizable.strings. Fails (exit 1) when a key is missing, when a
translation's format specifiers don't match its key, or when a SwiftUI literal mixes text with
interpolation (its runtime key depends on the interpolated types; use L10n.format instead).

Keys come from:
  - L10n.tr / L10n.format / L10n.plural calls;
  - SwiftUI literal initializers and modifiers (Text, Button, Label, Toggle, .help, ...);
  - helpers that translate their argument internally (see TRANSLATING_HELPERS);
  - model fields translated at display time (descriptor titles, unit words, value words, notes).

Run from the repo root: python3 script/check_localization.py [--list-missing | --lint] [path prefix...]
--lint lists sentence-like literals no translation path covers (review aid; never fails).
"""
import os
import re
import sys

TABLE = "assets/Localization/pt-BR.lproj/Localizable.strings"
# Work-in-progress translation fragments (one per contributor), merged into TABLE before commit.
FRAGMENTS_DIR = "assets/Localization/fragments"
SOURCE_ROOTS = ["Sources/MeuUso", "Sources/MeuUsoApp"]

# SwiftUI initializers/modifiers whose first literal argument is a LocalizedStringKey.
SWIFTUI_CALLS = [
    r"\bText", r"\bButton", r"\bLabel", r"\bToggle", r"\bPicker", r"\bSection", r"\bMenu",
    r"\bLink", r"\bLocalizedStringKey", r"\.help", r"\.accessibilityLabel", r"\.accessibilityHint",
    r"\.accessibilityValue", r"\.navigationTitle", r"\.alert", r"\.confirmationDialog",
]
# Helpers that call L10n.tr on their String argument (first literal argument).
TRANSLATING_HELPERS = [
    r"\.hoverTooltip", r"\brow", r"\bsection", r"\blogButton", r"\binlineNotice",
    r"\bClosureMenuItem\(\s*title:", r"\bDismissableHintCard\(\s*title:", r"\bTransientPill\(\s*text:",
    r"\bScreenCrossLink\(\s*title:", r"\bCustomizeRow\(\s*title:",
]
# Model fields translated at display time: the literal itself is the key.
MODEL_FIELDS = ["title", "traySuffix", "sourceNote", "infoNote", "valueTooltipNote", "unitLabel"]
# Model fields that become part of a phrase key.
PHRASE_FIELDS = {"valueWord": "%@ {}", "limitNoun": "%@ {}"}
# Unit labels: count formats (`.count(suffix: "requests")`) and lowercase value labels
# (`label: "credits"`); capitalized `label:` values are metric-line keys, never shown directly.
UNIT_PATTERNS = [r"\.count\(\s*suffix:\s*", r"\blabel:\s*"]

SPEC_RE = re.compile(r"%(?:(\d+)\$)?(lld|ld|lu|llu|d|i|u|f|lf|@|s|x|X|%)")


# ---------------------------------------------------------------- Swift lexing

def scan_string(text, i):
    n = len(text)
    j, hashes = i, 0
    while j < n and text[j] == "#":
        hashes += 1
        j += 1
    multiline = text.startswith('"""', j)
    j += 3 if multiline else 1
    closer = ('"""' if multiline else '"') + "#" * hashes
    escape = "\\" + "#" * hashes
    while j < n:
        if text.startswith(escape, j):
            k = j + len(escape)
            if k < n and text[k] == "(":
                depth, k2 = 0, k
                while k2 < n:
                    ch = text[k2]
                    if ch == "(":
                        depth += 1
                        k2 += 1
                    elif ch == ")":
                        depth -= 1
                        k2 += 1
                        if depth == 0:
                            break
                    elif ch == '"' or (ch == "#" and re.match(r'#+"', text[k2:k2 + 8])):
                        k2 = scan_string(text, k2)
                    else:
                        k2 += 1
                j = k2
                continue
            j = k + 1
            continue
        if text.startswith(closer, j):
            return j + len(closer)
        if not multiline and text[j] == "\n":
            return j
        j += 1
    return n


def code_view(text):
    """Returns (code with string literals replaced by __S<n>__ and comments blanked, [literals])."""
    out, literals = [], []
    i, n = 0, len(text)
    while i < n:
        if text.startswith("//", i):
            j = text.find("\n", i)
            j = n if j < 0 else j
            out.append(" " * (j - i))
            i = j
            continue
        if text.startswith("/*", i):
            depth, j = 0, i
            while j < n:
                if text.startswith("/*", j):
                    depth += 1
                    j += 2
                elif text.startswith("*/", j):
                    depth -= 1
                    j += 2
                    if depth == 0:
                        break
                else:
                    j += 1
            out.append(re.sub(r"[^\n]", " ", text[i:j]))
            i = j
            continue
        if text[i] == '"' or (text[i] == "#" and re.match(r'#+"', text[i:i + 8])):
            j = scan_string(text, i)
            literals.append(text[i:j])
            out.append(f"__S{len(literals) - 1}__")
            i = j
            continue
        out.append(text[i])
        i += 1
    return "".join(out), literals


def literal_value(raw):
    """Contents of a plain (non-raw, single-line) Swift literal, or None for raw/multiline ones."""
    if not raw.startswith('"') or raw.startswith('"""'):
        return None
    body = raw[1:-1] if raw.endswith('"') else raw[1:]
    if "\\(" in body:
        return ("INTERPOLATED", body)
    return (body.replace('\\"', '"').replace("\\n", "\n").replace("\\t", "\t").replace("\\\\", "\\"))


# ---------------------------------------------------------------- table parsing

def parse_strings(path):
    text = open(path, encoding="utf-8").read()
    entries, i, n = {}, 0, len(text)

    def read_quoted(k):
        assert text[k] == '"', (path, k)
        k += 1
        buf = []
        while text[k] != '"':
            if text[k] == "\\":
                nxt = text[k + 1]
                buf.append({"n": "\n", "t": "\t", '"': '"', "\\": "\\"}.get(nxt, nxt))
                k += 2
            else:
                buf.append(text[k])
                k += 1
        return "".join(buf), k + 1

    while i < n:
        if text.startswith("/*", i):
            i = text.index("*/", i) + 2
        elif text.startswith("//", i):
            i = text.find("\n", i)
            i = n if i < 0 else i
        elif text[i] == '"':
            key, i = read_quoted(i)
            i = text.index("=", i) + 1
            while text[i].isspace():
                i += 1
            value, i = read_quoted(i)
            i = text.index(";", i) + 1
            if key in entries:
                raise SystemExit(f"{path}: duplicate key {key!r}")
            entries[key] = value
        else:
            i += 1
    return entries


def specifiers(text):
    found = []
    for m in SPEC_RE.finditer(text):
        if m.group(2) == "%":
            continue
        kind = m.group(2)
        kind = {"ld": "lld", "d": "lld", "i": "lld", "lu": "lld", "llu": "lld", "u": "lld", "lf": "f"}.get(kind, kind)
        found.append(kind)
    return sorted(found)


def lone_percent(text):
    stripped = SPEC_RE.sub("", text)
    return "%" in stripped


# ---------------------------------------------------------------- key collection

def collect(paths):
    keys = {}  # key -> first location
    problems = []

    def add(key, where):
        if key and re.search(r"[A-Za-z]", key):
            keys.setdefault(key, where)

    for path in paths:
        text = open(path, encoding="utf-8").read()
        code, literals = code_view(text)

        def line_of(pos):
            return code.count("\n", 0, pos) + 1

        def literal_after(pattern):
            for m in re.finditer(pattern + r"\(?\s*__S(\d+)__", code):
                yield m, literals[int(m.group(1))]

        # 1. L10n calls (every literal argument of plural, the first of tr/format).
        for m, raw in literal_after(r"\bL10n\.(?:tr|format)\("):
            value = literal_value(raw)
            where = f"{path}:{line_of(m.start())}"
            if isinstance(value, tuple):
                problems.append(f"{where}: interpolated key passed to L10n; use a format string")
            elif value is not None:
                add(value, where)
        for m in re.finditer(r"\bL10n\.plural\([^,]+,\s*__S(\d+)__\s*,\s*__S(\d+)__", code):
            for idx in (m.group(1), m.group(2)):
                value = literal_value(literals[int(idx)])
                if isinstance(value, str):
                    add(value, f"{path}:{line_of(m.start())}")

        # 2. SwiftUI literals and translating helpers.
        for pattern in SWIFTUI_CALLS + TRANSLATING_HELPERS:
            for m, raw in literal_after(pattern + r"\(\s*" if not pattern.endswith(":") else pattern):
                # Skip `Text(verbatim:)` and similar labeled forms; the pattern only matches a bare literal.
                value = literal_value(raw)
                where = f"{path}:{line_of(m.start())}"
                if isinstance(value, tuple):
                    body = re.sub(r"\\\((?:[^()]|\([^()]*\))*\)", "", value[1])
                    if re.search(r"[A-Za-z]{2,}", body):
                        problems.append(f"{where}: SwiftUI literal mixes text and interpolation; use L10n.format")
                elif value is not None:
                    add(value, where)

        # 3. Model fields translated at display time.
        if "/Providers/" in path or "/Models/" in path or "/Pricing/" in path:
            for field in MODEL_FIELDS:
                for m, raw in literal_after(rf"\b{field}:\s*"):
                    value = literal_value(raw)
                    if isinstance(value, str):
                        add(value, f"{path}:{line_of(m.start())}")
            for field, template in PHRASE_FIELDS.items():
                for m, raw in literal_after(rf"\b{field}:\s*"):
                    value = literal_value(raw)
                    if isinstance(value, str):
                        add(template.format(value), f"{path}:{line_of(m.start())}")
            for pattern in UNIT_PATTERNS:
                for m, raw in literal_after(pattern):
                    value = literal_value(raw)
                    if isinstance(value, str) and value == value.lower():
                        add(value, f"{path}:{line_of(m.start())}")
    return keys, problems


def lint(paths, known):
    """Sentence-like literals that no translation path covers: likely untranslated UI text."""
    hits = []
    skip_line = re.compile(r"AppLog\.|Logger\(|fatalError|precondition|assert|XCT|debugDescription|"
                           r"forKey|storageKey|UserDefaults|NSRegularExpression|#Preview|\.log\(")
    for path in paths:
        text = open(path, encoding="utf-8").read()
        code, literals = code_view(text)
        lines = code.split("\n")
        for idx, raw in enumerate(literals):
            value = literal_value(raw)
            if not isinstance(value, str) or value in known:
                continue
            if not re.search(r"[A-Za-z]{3,} [A-Za-z]{2,}", value) or "://" in value:
                continue
            pos = code.index(f"__S{idx}__")
            line_no = code.count("\n", 0, pos)
            if skip_line.search(lines[line_no]):
                continue
            hits.append(f"{path}:{line_no + 1}: {value[:90]!r}")
    return hits


def main():
    paths = []
    for root in SOURCE_ROOTS:
        for dirpath, _, names in os.walk(root):
            paths += [os.path.join(dirpath, n) for n in names if n.endswith(".swift")]
    keys, problems = collect(sorted(paths))
    table = parse_strings(TABLE)
    if os.path.isdir(FRAGMENTS_DIR):
        for name in sorted(os.listdir(FRAGMENTS_DIR)):
            if not name.endswith(".strings"):
                continue
            for key, value in parse_strings(os.path.join(FRAGMENTS_DIR, name)).items():
                if key in table and table[key] != value:
                    problems.append(f"{FRAGMENTS_DIR}/{name}: {key!r} translated differently elsewhere: "
                                    f"{value!r} vs {table[key]!r}")
                table.setdefault(key, value)

    # Optional path prefixes narrow the report (e.g. `--lint Sources/MeuUso/Views`).
    prefixes = [a for a in sys.argv[1:] if not a.startswith("--")]

    def wanted(line):
        return not prefixes or any(line.startswith(prefix) for prefix in prefixes)

    if "--lint" in sys.argv[1:]:
        hits = [h for h in lint(sorted(paths), set(keys) | set(table)) if wanted(h)]
        print("\n".join(hits) or "No untranslated-looking literals.")
        return 0

    missing = sorted(k for k in keys if k not in table)
    for key in missing:
        problems.append(f"{keys[key]}: no pt-BR translation for {key!r}")
    for key, value in table.items():
        if specifiers(key) != specifiers(value):
            problems.append(f"{TABLE}: format specifiers differ for {key!r}: {value!r}")
        if lone_percent(value):
            problems.append(f"{TABLE}: lone % in translation of {key!r} (write %%)")

    if "--list-missing" in sys.argv[1:]:
        for key in missing:
            if wanted(keys[key]):
                print(f"{keys[key]}: {key}")
        return 0
    problems = [p for p in problems if wanted(p) or p.startswith(TABLE) or p.startswith(FRAGMENTS_DIR)]
    if problems:
        print("\n".join(problems))
        print(f"\n{len(problems)} localization problem(s). See docs/glossario.md.")
        return 1
    print(f"Localization OK: {len(keys)} keys used, {len(table)} translations.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
