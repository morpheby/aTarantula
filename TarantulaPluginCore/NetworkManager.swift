//
//  RetrieveData.swift
//  TarantulaPluginCore
//
//  Created by Ilya Mikhaltsou on 9/24/17.
//  Copyright © 2017 morpheby. All rights reserved.
//

import Foundation

public protocol NetworkManager {
    func stringData(url: URL) throws -> String
    func data(url: URL, beforeRequest: (URLRequest) -> (URLRequest)) throws -> Data
    func data(url: URL) throws -> Data
}
