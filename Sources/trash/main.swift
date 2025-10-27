import Foundation

let VERSION = "2.1.0"

func trash(_ urls: [URL]) {
	// Ensures the user's trash is used.
	CLI.revertSudo()

	for url in urls {
		CLI.tryOrExit {
			try FileManager.default.trashItem(at: url, resultingItemURL: nil)
		}
	}
}

func prompt(question: String) -> Bool {
	print(question, terminator: " ")

	guard
		let input = readLine(),
		!input.isEmpty
	else {
		return false
	}

	return ["y", "yes"].contains(input.lowercased())
}

// Filter out rm-compatible flags that should be ignored.
func filterRmFlags(_ arguments: [String]) -> [String] {
    arguments.compactMap { arg in
        if arg.hasPrefix("-") && !arg.hasPrefix("--") {
            let flags = arg.dropFirst()
            let filtered = flags.filter { $0 != "r" && $0 != "R" && $0 != "f" }
            if !filtered.isEmpty {
                return "-" + String(filtered)
            } else {
                return nil
            }
        }
        return arg
    }
}


let arguments = filterRmFlags(CLI.arguments)

guard let argument = arguments.first else {
    print("Specify one or more paths", to: .standardError)
    exit(1)
}

// Handle positionals, at the point when no other flags will be accepted.
// If there is a leading `--` argument, it will be removed (but not any subsequent `--` arguments).
func collectPaths(arguments: some Collection<String>) -> any Collection<String> {
	if
		arguments.count > 0,
		arguments[arguments.startIndex] == "--"
	{
		return arguments.dropFirst()
	}

	return arguments
}

switch argument {
case "--help", "-h":
	print("Usage: trash [--help | -h] [--version | -v] [--interactive | -i] <path> […]")
	print("\nNote: -r, -R, and -f flags are accepted and ignored for rm compatibility.")
	exit(0)
case "--version", "-v":
	print(VERSION)
	exit(0)
case "--interactive", "-i":
	for url in (collectPaths(arguments: arguments.dropFirst()).map { URL(fileURLWithPath: $0) }) {
		guard FileManager.default.fileExists(atPath: url.path) else {
			print("The file “\(url.relativePath)” doesn't exist.")
			continue
		}

		guard prompt(question: "Trash “\(url.relativePath)”?") else {
			continue
		}

		trash([url])
	}
default:
	// TODO: Use `URL(filePath:` when tarrgeting macOS 15.
	trash(collectPaths(arguments: arguments).map { URL(fileURLWithPath: $0) })
}
