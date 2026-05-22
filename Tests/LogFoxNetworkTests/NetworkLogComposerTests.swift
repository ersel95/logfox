import XCTest
@testable import LogFoxNetwork
import LogFoxCore

final class NetworkLogComposerTests: XCTestCase {

    private func event(status: Int? = 200, error: String? = nil) -> NetworkLogEvent {
        NetworkLogEvent(
            method: "POST",
            url: "https://api.example.com/transfer",
            statusCode: status,
            durationMs: 123,
            requestBytes: 10,
            responseBytes: 20,
            error: error,
            requestBody: nil,
            responseBody: nil
        )
    }

    func testLevelMapping() {
        XCTAssertEqual(NetworkLogComposer.level(statusCode: 200, error: nil), .info)
        XCTAssertEqual(NetworkLogComposer.level(statusCode: 301, error: nil), .info)
        XCTAssertEqual(NetworkLogComposer.level(statusCode: 404, error: nil), .warning)
        XCTAssertEqual(NetworkLogComposer.level(statusCode: 500, error: nil), .error)
        XCTAssertEqual(NetworkLogComposer.level(statusCode: nil, error: "timeout"), .error)
        XCTAssertEqual(NetworkLogComposer.level(statusCode: nil, error: nil), .info)
    }

    func testMessageContainsMethodURLAndStatus() {
        let message = NetworkLogComposer.message(for: event(status: 200))
        XCTAssertTrue(message.contains("POST"))
        XCTAssertTrue(message.contains("https://api.example.com/transfer"))
        XCTAssertTrue(message.contains("200"))
        XCTAssertTrue(message.contains("123ms"))
    }

    func testMetadataKeys() {
        let metadata = NetworkLogComposer.metadata(for: event(status: 200))
        XCTAssertEqual(metadata["method"], "POST")
        XCTAssertEqual(metadata["status"], "200")
        XCTAssertEqual(metadata["durationMs"], "123")
        XCTAssertNil(metadata["error"])
    }

    func testMetadataIncludesErrorWhenPresent() {
        let metadata = NetworkLogComposer.metadata(for: event(status: nil, error: "timed out"))
        XCTAssertEqual(metadata["error"], "timed out")
        XCTAssertNil(metadata["status"])
    }

    func testConfigurationDefaults() {
        let config = LogFoxNetworkConfiguration.default
        XCTAssertFalse(config.capturesBodies) // banking-grade: gövde default kapalı
        XCTAssertEqual(config.category, .network)
    }
}
