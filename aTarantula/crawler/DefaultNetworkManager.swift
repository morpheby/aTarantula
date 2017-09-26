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

    public func stringData(url: URL) throws -> String {
        let condition = NSCondition()
        var completed: Bool = false
        var data: Data?
        var response: URLResponse?
        var error: Error?

        let task = session.dataTask(with: url, completionHandler: { (data_, response_, error_) in
            data = data_
            response = response_
            error = error_
            completed = true
            condition.signal()
        })

        sessionQueue.addOperation {
            task.resume()
        }

        condition.lock()
        while !completed {
            condition.wait()
        }
        condition.unlock()

        if let e = error {
            throw URLSessionError(urlSessionError: e, response: response, data: data)
        }

        if let d = data, let result = String(data: d, encoding: .utf8) {
            return result
        }

        throw UnknownURLSessionError(response: response)
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

}
