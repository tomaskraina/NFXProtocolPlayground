//
//  NFXProtocolPlaygroundTests.swift
//  NFXProtocolPlaygroundTests
//
//  Created by Tom Kraina on 18/11/2019.
//  Copyright © 2019 Tom Kraina. All rights reserved.
//

import XCTest
//@testable import NFXProtocolPlayground
import netfox

class NFXProtocolPlaygroundTests: XCTestCase {

    override class func setUp() {
        super.setUp()

        // Try comment out the following line and see the test pass
        NFX.sharedInstance().start()
    }

    func testRequestHeaderWithoutAlamofireJustURLSession() {
        // Given
        let redirectURLString = "https://www.apple.com"
        let urlString = "https://httpbin.org/redirect-to?url=\(redirectURLString)"

        let config = URLSessionConfiguration.default
        let delegate = MyURLSessionDelegate()
        let session = URLSession(configuration: config, delegate: delegate, delegateQueue: OperationQueue.main)
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "HEAD"

        var response: (data: Data?, response: URLResponse?, error: Error?)?
        let expectation = self.expectation(description: "URLSessionDataTask callback should be made")

        // When
        let task = session.dataTask(with: request) { (data, urlResponse, error) in
            response = (data, urlResponse, error)
            expectation.fulfill()
        }
        task.resume()

        self.waitForExpectations(timeout: 5.0, handler: nil)

        // Then
        XCTAssertTrue(delegate.hasInvokedWillPerformHTTPRedirection, "hasInvokedWillPerformHTTPRedirection")

        let httpResponse = response?.response as? HTTPURLResponse
        let headerLocation = httpResponse?.allHeaderFields["Location"] as? String
        XCTAssertNotNil(headerLocation)
        XCTAssertNil(response?.error)
    }
}

// MARK: - Private

private final class MyURLSessionDelegate: NSObject, URLSessionDataDelegate {

    private var isRedirectEnabled: Bool = false

    var hasInvokedWillPerformHTTPRedirection: Bool = false

    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        completionHandler(self.isRedirectEnabled ? request : nil)
        self.hasInvokedWillPerformHTTPRedirection = true
    }

    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, challenge.protectionSpace.serverTrust.flatMap { URLCredential(trust: $0) } )
    }
}
