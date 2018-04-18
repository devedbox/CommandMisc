import XCTest
@testable import CommandMisc

final class CommandMiscTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(CommandMisc().text, "Hello, World!")
    }


    static var allTests = [
        ("testExample", testExample),
    ]
}
