import Darwin
import Foundation
import MeuUso

@main
struct MeuUsoCLI {
    static func main() async {
        do {
            let arguments = try CLIArguments.parse(Array(CommandLine.arguments.dropFirst()))
            if arguments.showHelp {
                print(help)
                return
            }

            let app = AppBundleLocator.locate()
            if arguments.showVersion {
                print(app.version.map { "meu-uso \($0)" } ?? "meu-uso (versão de desenvolvimento)")
                return
            }

            guard let defaults = UserDefaults(suiteName: app.bundleIdentifier) else {
                throw CLIError.appDefaultsUnavailable
            }
            let result = try await UsageReader(userDefaults: defaults).read(
                providerID: arguments.providerID,
                force: arguments.force
            )
            FileHandle.standardOutput.write(result.data)
            FileHandle.standardOutput.write(Data("\n".utf8))
            if !result.warnings.isEmpty {
                result.warnings.forEach { writeError("aviso: \($0)") }
                exit(4)
            }
        } catch CLIError.usage(let message) {
            fail("\(message)\nRode 'meu-uso --help' para ver como usar.", code: 2)
        } catch CLIError.appDefaultsUnavailable {
            fail("Não foi possível abrir o domínio de ajustes do Meu Uso.", code: 4)
        } catch UsageReaderError.unknownProvider(let providerID) {
            fail("Provedor desconhecido: \(providerID)", code: 2)
        } catch {
            fail(error.localizedDescription, code: 4)
        }
    }

    private static func writeError(_ message: String) {
        FileHandle.standardError.write(Data("meu-uso: \(message)\n".utf8))
    }

    private static func fail(_ message: String, code: Int32) -> Never {
        writeError(message)
        exit(code)
    }

    /// Human-facing text is written directly in Portuguese: `L10n` lives inside the MeuUso module.
    /// Flags, the command name, exit codes and the JSON output stay as they are.
    private static let help = """
    Uso: meu-uso [provedor] [--force]

    Lê os limites pelo cache compartilhado de cinco minutos do Meu Uso e sai. A saída é sempre JSON.

    Opções:
      --force      Atualiza mesmo quando o cache compartilhado ainda está válido
      -v, --version
      -h, --help
    """
}
