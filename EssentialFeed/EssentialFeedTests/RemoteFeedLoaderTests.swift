//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Said Rehouni on 27/7/21.
//

import XCTest
import EssentialFeed

class RemoteFeedLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let (_ ,client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestsDataFromURL() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut ,client) = makeSUT(url: url)
        
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadTwice_requestsDataFromURLTwice() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut ,client) = makeSUT(url: url)
        
        sut.load { _ in }
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWithResult: .failure(.connectivity)) { [weak client] in
            let clientError = NSError(domain: "Test", code: 0, userInfo: nil)
            client?.complete(with: clientError)
        }
    }
    
    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        let samples = [199, 201, 300, 400, 500]
        
        samples.enumerated().forEach { [weak client] index, code in
            expect(sut, toCompleteWithResult: .failure(.invalidData)) {
                client?.complete(withStatusCode: code, at: index)
            }
        }
    }
    
    func test_load_deliversErrorOn200HTTPResponeWithInvalidJSON() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWithResult: .failure(.invalidData)) { [weak client] in
            let invalidJSON = Data("invalid json".utf8)
            client?.complete(withStatusCode: 200, data: invalidJSON)
        }
    }
    
    // MARK: - Helpers
    
    private func makeSUT(url: URL = URL(string: "https://a-given-url.com")!) -> (sut: RemoteFeedLoader, client: HttpClientSpy) {
        let client = HttpClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        
        return (sut: sut, client: client)
    }
    
    private func expect(_ sut: RemoteFeedLoader, toCompleteWithResult result: RemoteFeedLoader.Result, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        var capturedResult = [RemoteFeedLoader.Result]()
        sut.load() { capturedResult.append($0) }
        
        action()
        
        XCTAssertEqual(capturedResult, [result], file: file, line: line)
    }
    
    private class HttpClientSpy: HTTPClient {
        var requestedURLs: [URL] {
            return messages.map { $0.url }
        }
        
        private var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()
        
        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
            messages.append((url, completion))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
        
        func complete(withStatusCode code: Int, data: Data = Data(), at index: Int = 0) {
            let response = HTTPURLResponse(url: messages[index].url,
                                           statusCode: code,
                                           httpVersion: nil,
                                           headerFields: nil)!
            
            messages[index].completion(.success(data, response))
        }
    }
}
