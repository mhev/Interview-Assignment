import XCTest
@testable import NeverGone

final class StreamingServiceTests: XCTestCase {
    
    func testStreamChunkDecoding() throws {
        let json = #"{"chunk": "Hello", "done": false}"#
        let data = json.data(using: .utf8)!
        
        let chunk = try JSONDecoder().decode(StreamChunk.self, from: data)
        
        XCTAssertEqual(chunk.chunk, "Hello")
        XCTAssertFalse(chunk.done)
        XCTAssertNil(chunk.error)
    }
    
    func testStreamChunkDoneDecoding() throws {
        let json = #"{"done": true}"#
        let data = json.data(using: .utf8)!
        
        let chunk = try JSONDecoder().decode(StreamChunk.self, from: data)
        
        XCTAssertNil(chunk.chunk)
        XCTAssertTrue(chunk.done)
    }
    
    func testStreamChunkErrorDecoding() throws {
        let json = #"{"error": "Something went wrong", "done": false}"#
        let data = json.data(using: .utf8)!
        
        let chunk = try JSONDecoder().decode(StreamChunk.self, from: data)
        
        XCTAssertEqual(chunk.error, "Something went wrong")
        XCTAssertFalse(chunk.done)
    }
    
    func testChatStreamRequestEncoding() throws {
        let request = ChatStreamRequest(sessionId: "test-session", message: "Hello")
        let data = try JSONEncoder().encode(request)
        let json = String(data: data, encoding: .utf8)!
        
        XCTAssertTrue(json.contains("session_id"))
        XCTAssertTrue(json.contains("test-session"))
        XCTAssertTrue(json.contains("Hello"))
    }
}
