import Foundation

struct CLIArguments: Equatable, Sendable {
    enum Command: Equatable, Sendable {
        /// Print the limits JSON (the default).
        case read
        /// `meu-uso update`: install the newest release over this app (see `SelfUpdate`).
        case update
    }

    var command: Command = .read
    var providerID: String?
    var force = false
    var showHelp = false
    var showVersion = false

    static func parse(_ arguments: [String]) throws -> CLIArguments {
        var parsed = CLIArguments()
        var remaining = arguments[...]
        // `update` is a subcommand only in first position, so no provider ID can ever shadow it.
        if remaining.first == "update" {
            parsed.command = .update
            remaining = remaining.dropFirst()
        }
        for argument in remaining {
            switch argument {
            case "--force": parsed.force = true
            case "-h", "--help": parsed.showHelp = true
            case "-v", "--version": parsed.showVersion = true
            default:
                if argument.hasPrefix("-") {
                    throw CLIError.usage("Opção desconhecida: \(argument)")
                }
                guard parsed.command == .read else {
                    throw CLIError.usage("O comando update não recebe provedor.")
                }
                guard parsed.providerID == nil else {
                    throw CLIError.usage("Só é possível pedir um provedor por vez.")
                }
                parsed.providerID = argument.lowercased()
            }
        }
        return parsed
    }
}

enum CLIError: Error, Equatable {
    case usage(String)
    case appDefaultsUnavailable
    /// `meu-uso update` can't run for this copy of the app; the message says why and what to do.
    case updateUnavailable(String)
}
