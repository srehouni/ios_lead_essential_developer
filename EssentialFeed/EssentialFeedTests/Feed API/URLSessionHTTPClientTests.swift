//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Said Rehouni on 18/5/22.
//

import XCTest
import EssentialFeed

class URLSessionHTTPClient {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    struct UnexpectedValuesRepresentation: Error {}
    
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { _, _, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.failure(UnexpectedValuesRepresentation()))
            }
        }.resume()
    }
}

class URLSessionHTTPClientTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptingRequests()
    }
    
    override class func tearDown() {
        super.tearDown()
        URLProtocolStub.stopInterceptingRequests()
    }
    
    func test_getFromURL_performancesGetRequestWithURL() {
        let url = anyURL()
        let expectation = expectation(description: "ObserveRequests was executed")
        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            expectation.fulfill()
        }
        
        makeSUT().get(from: url) { _ in }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_getFromURL_failsOnRequestError() throws {
        let requestError = NSError(domain: "any error", code: 1, userInfo: nil)
        let receivedError = try XCTUnwrap(resultErrorFor(data: nil, response: nil, error: requestError) as? NSError)
        XCTAssertEqual(receivedError.domain, requestError.domain)
        XCTAssertEqual(receivedError.code, requestError.code)
    }
    
    func test_getFromURL_failsOnAllInvalidRepresentationCases() {
        let anyError = NSError(domain: "any error", code: 0)
        let anyData = Data("any data".utf8)
        let nonHTTPURLResponse = URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        let anyHTTPResponse = HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)
        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPResponse, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nil, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPResponse, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nonHTTPURLResponse, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: anyHTTPResponse, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nonHTTPURLResponse, error: nil))
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> URLSessionHTTPClient {
        let sut = URLSessionHTTPClient()
        trackForMemoryLeadks(sut, file: file, line: line)
        return sut
    }
    
    private func resultErrorFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt =  #line) -> Error? {
        URLProtocolStub.stub(data: data, response: response, error: error)
        let expectation = expectation(description: "Wait for completion")
        let sut = makeSUT()
        
        var receivedError: Error?
        sut.get(from: anyURL()) { result in
            switch result {
                case let .failure(error):
                    receivedError = error
                default:
                    XCTFail("Expected failure, got \(result) instead", file: file, line: line)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        return receivedError
    }
    
    private func anyURL() -> URL {
        URL(string: "http://any-url.com")!
    }
    
    private class URLProtocolStub: URLProtocol {
        private static var stub: Stub?
        private static var requestObserver: ((URLRequest) -> Void)?
        
        private struct Stub {
            let response: URLResponse?
            let data: Data?
            let error: Error?
        }
        
        static func stub(data: Data?, response: URLResponse?, error: Error? = nil) {
            stub = Stub(response: response, data: data, error: error)
        }
        
        static func observeRequests(observer: @escaping (URLRequest) -> Void) {
            requestObserver = observer
        }
        
        static func startInterceptingRequests() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }
        
        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stub = nil
            requestObserver = nil
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            requestObserver?(request)
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {}
    }
}
