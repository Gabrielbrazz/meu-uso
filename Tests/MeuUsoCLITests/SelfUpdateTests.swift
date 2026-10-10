import XCTest
@testable import MeuUsoCLI

/// `SelfUpdate` refuses to run for copies that don't update from the terminal, before it ever starts
/// the installer. These tests stop at those checks and never launch a process.
final class SelfUpdateTests: XCTestCase {
    private var root: URL!

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent("SelfUpdateTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root)
    }

    /// A minimal app bundle with the given distribution key (or none) and an optional bundled installer;
    /// returns the path of the CLI helper inside it.
    private func makeApp(distribution: String?, withInstaller: Bool) throws -> URL {
        let contents = root.appendingPathComponent("MeuUso.app/Contents")
        try FileManager.default.createDirectory(
            at: contents.appendingPathComponent("Resources"), withIntermediateDirectories: true)
        var info: [String: Any] = ["CFBundleIdentifier": "io.github.gabrielbrazz.meuuso"]
        info["MeuUsoDistribution"] = distribution
        XCTAssertTrue((info as NSDictionary).write(to: contents.appendingPathComponent("Info.plist"), atomically: true))
        if withInstaller {
            try Data("exit 0\n".utf8).write(to: contents.appendingPathComponent("Resources/install.sh"))
        }
        return contents.appendingPathComponent("Helpers/meu-uso")
    }

    private func assertUnavailable(_ executable: URL, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertThrowsError(try SelfUpdate.run(force: false, executableURL: executable), file: file, line: line) { error in
            guard case CLIError.updateUnavailable = error else {
                return XCTFail("expected updateUnavailable, got \(error)", file: file, line: line)
            }
        }
    }

    func testRefusesOutsideAnApp() {
        assertUnavailable(root.appendingPathComponent("bin/meu-uso"))
    }

    func testRefusesDevBuilds() throws {
        assertUnavailable(try makeApp(distribution: "dev", withInstaller: true))
    }

    func testRefusesSparkleUpdatedBuilds() throws {
        assertUnavailable(try makeApp(distribution: nil, withInstaller: true))
    }

    func testRefusesTerminalBuildWithoutBundledInstaller() throws {
        assertUnavailable(try makeApp(distribution: "terminal", withInstaller: false))
    }

    func testInstallerArgumentsTargetThisAppAndForwardForce() {
        XCTAssertEqual(
            SelfUpdate.installerArguments(scriptPath: "/tmp/i.sh", appPath: "/Applications/MeuUso.app", force: false),
            ["/tmp/i.sh", "--app", "/Applications/MeuUso.app"]
        )
        XCTAssertEqual(
            SelfUpdate.installerArguments(scriptPath: "/tmp/i.sh", appPath: "/Applications/MeuUso.app", force: true),
            ["/tmp/i.sh", "--app", "/Applications/MeuUso.app", "--force"]
        )
    }
}
