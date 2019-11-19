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
import Alamofire

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
        config.timeoutIntervalForRequest = 3.0
        if config.protocolClasses?.contains(where: { $0 is NFXProtocol.Type }) == true {
            print("Netfox is running")
        }

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

        XCTAssertNotNil(response)
        XCTAssertEqual(response?.response?.url?.absoluteString, urlString)
        let httpResponse = response?.response as? HTTPURLResponse
        let headerLocation = httpResponse?.allHeaderFields["Location"] as? String
        XCTAssertNotNil(headerLocation)
        XCTAssertNil(response?.error)
    }

    /// From Alamofire Tests
    /// https://github.com/Alamofire/Alamofire/blob/4.9.1/Tests/SessionDelegateTests.swift
    func testThatTaskOverrideClosureCanCancelHTTPRedirection() {
        // Given
        let timeout: TimeInterval = 5.0
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 3.0
        let manager = SessionManager(configuration: config)
        let redirectURLString = "https://www.apple.com"
        let urlString = "https://httpbin.org/redirect-to?url=\(redirectURLString)"

        let expectation = self.expectation(description: "Request should not redirect to \(redirectURLString)")
        let callbackExpectation = self.expectation(description: "Redirect callback should be made")
        let delegate: SessionDelegate = manager.delegate

        delegate.taskWillPerformHTTPRedirectionWithCompletion = { _, _, _, _, completion in
            callbackExpectation.fulfill()
            completion(nil)
        }

        var response: DefaultDataResponse?

        // When
        manager.request(urlString)
            .response { resp in
                response = resp
                expectation.fulfill()
            }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        XCTAssertNotNil(response?.request)
        XCTAssertNotNil(response?.response)
        XCTAssertNotNil(response?.data)
        XCTAssertNil(response?.error)

        XCTAssertEqual(response?.response?.url?.absoluteString, urlString)
        XCTAssertEqual(response?.response?.statusCode, 302)
    }
}

// MARK: - Private

private final class MyURLSessionDelegate: NSObject, URLSessionDataDelegate {

    var followRedirects: Bool = false

    var hasInvokedWillPerformHTTPRedirection: Bool = false

    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        print(#function, request)
        self.hasInvokedWillPerformHTTPRedirection = true
        completionHandler(self.followRedirects ? request : nil)
    }

    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, challenge.protectionSpace.serverTrust.flatMap { URLCredential(trust: $0) } )
    }
}
