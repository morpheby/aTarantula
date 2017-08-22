//
//  PluginLoader.swift
//  aTarantula
//
//  Created by Ilya Mikhaltsou on 8/20/17.
//  Copyright © 2017 morpheby. All rights reserved.
//

import Foundation
import TarantulaPluginCore

class PluginLoader {
    func listAllPluginPaths() -> [String] {
        return []
    }

    func loadPlugin(fromPath path: String) {

    }

    var exporters: [Any] = []
    var crawlers: [TarantulaCrawlingPlugin] = []

}
