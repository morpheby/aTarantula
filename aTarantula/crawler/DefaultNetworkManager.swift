//
//  DefaultNetworkManager.swift
//  aTarantula
//
//  Created by Ilya Mikhaltsou on 9/24/17.
//  Copyright © 2017 morpheby. All rights reserved.
//

import Foundation
import TarantulaPluginCore

public class DefaultNetworkManager: NetworkManager {

    let configuration: URLSessionConfiguration
    let session: URLSession
    let sessionQueue = NSApplication.shared.controller.backgroundQueue()

    init() {
        configuration = URLSessionConfiguration.default.copy() as! URLSessionConfiguration
        session = URLSession(configuration: configuration)
    }

    public func data(url: URL) throws -> Data {
        return try data(url: url, beforeRequest: {$0})
    }

    public func data(url: URL, beforeRequest: (URLRequest) -> (URLRequest)) throws -> Data {
        let condition = NSCondition()
        var completed: Bool = false
        var data: Data?
        var response: URLResponse?
        var error: Error?

        var request = beforeRequest(URLRequest(url: url))

        request.setValue("User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Safari/604.1.38", forHTTPHeaderField: "User-Agent")

        condition.lock()
        defer {
            condition.unlock()
        }

        let task = session.dataTask(with: request, completionHandler: { (data_, response_, error_) in
            condition.lock()
            defer {
                condition.unlock()
            }
            data = data_
            response = response_
            error = error_
            completed = true
            condition.signal()
        })

        sessionQueue.addOperation {
            task.resume()
        }

        while !completed {
            condition.wait()
        }

        if let e = error {
            throw URLSessionError(urlSessionError: e, response: response, data: data)
        }

        if let d = data {
            return d
        }

        throw UnknownURLSessionError(response: response)
    }

    public func stringData(url: URL) throws -> String {
        let dataValue = try data(url: url)
        if let result = String(data: dataValue, encoding: .utf8) {
            return result
        }

        throw StringConversionError(problematicData: dataValue)
    }

    struct URLSessionError: LocalizedError {
        let urlSessionError: Error
        let response: URLResponse?
        let data: Data?

        var errorDescription: String? {
            return "URLSession returned error \(urlSessionError)"
        }

        var failureReason: String? {
            return "Received \(String(describing: response)) and \(String(describing: data))"
        }
    }

    struct UnknownURLSessionError: LocalizedError {
        let response: URLResponse?

        var errorDescription: String? {
            return "No data returned by URLSession"
        }

        var failureReason: String? {
            return "\(String(describing: response))"
        }
    }

    struct StringConversionError: LocalizedError {
        let problematicData: Data?

        var errorDescription: String? {
            return "Unable to transform data to UTF-8 string"
        }

        var failureReason: String? {
            return "Problem appeared while reading \(String(describing: problematicData)) as UTF-8 String"
        }
    }

}
