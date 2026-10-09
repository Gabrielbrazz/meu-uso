import Foundation

struct CLIArguments: Equatable, Sendable {
    var providerID: String?
    var force = false
    var showHelp = false
    var showVersion = false

    static func parse(_ arguments: [String]) throws -> CLIArguments {
        var parsed = CLIArguments()
        for argument in arguments {
            switch argument {
            case "--force": parsed.force = true
            case "-h", "--help": parsed.showHelp = true
            case "-v", "--version": parsed.showVersion = true
            default:
                if argument.hasPrefix("-") {
                    throw CLIError.usage("Opção desconhecida: \(argument)")
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
}
