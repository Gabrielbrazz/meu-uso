import Foundation
import MeuUso

/// `meu-uso update`: runs the installer bundled in the app (`Contents/Resources/install.sh`, the same
/// `script/install.sh` used for the first install) against this app, so it downloads the newest GitHub
/// release, checks it and swaps it in place. Only the terminal release (`MeuUsoDistribution` =
/// `terminal`) updates this way; a dev build or a Sparkle-updated release says how it updates instead.
enum SelfUpdate {
    /// Runs the installer with this process's terminal attached and returns its exit status.
    static func run(force: Bool, executableURL: URL) throws -> Int32 {
        guard let appURL = ContainingAppBundle.url(for: executableURL),
              let info = NSDictionary(contentsOf: appURL.appendingPathComponent("Contents/Info.plist"))
        else {
            throw CLIError.updateUnavailable(
                "Este meu-uso não está dentro do app. Instale com o comando do README."
            )
        }
        switch info["MeuUsoDistribution"] as? String {
        case "terminal":
            break
        case "dev":
            throw CLIError.updateUnavailable(
                "Este é um build de desenvolvimento. Atualize compilando de novo ou baixando um artefato novo do CI."
            )
        default:
            throw CLIError.updateUnavailable(
                "Este Meu Uso se atualiza pelo próprio app, em Ajustes → Atualizações."
            )
        }

        let bundledScript = appURL.appendingPathComponent("Contents/Resources/install.sh")
        guard FileManager.default.fileExists(atPath: bundledScript.path) else {
            throw CLIError.updateUnavailable(
                "O instalador não está dentro do app. Reinstale com o comando do README."
            )
        }
        // Run a copy: the installer replaces this very bundle, script included.
        let script = FileManager.default.temporaryDirectory
            .appendingPathComponent("meu-uso-update-\(UUID().uuidString).sh")
        try FileManager.default.copyItem(at: bundledScript, to: script)
        defer { try? FileManager.default.removeItem(at: script) }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = installerArguments(scriptPath: script.path, appPath: appURL.path, force: force)
        // stdin/stdout/stderr stay unset, so the installer talks to this terminal directly.
        try process.run()
        process.waitUntilExit()
        return process.terminationStatus
    }

    static func installerArguments(scriptPath: String, appPath: String, force: Bool) -> [String] {
        [scriptPath, "--app", appPath] + (force ? ["--force"] : [])
    }
}
