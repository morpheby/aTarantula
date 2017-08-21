//
//  TestPlugin.swift
//  ATARCsvExporterPlugin
//
//  Created by Ilya Mikhaltsou on 8/20/17.
//  Copyright © 2017 morpheby. All rights reserved.
//

import Foundation
import TarantulaPluginCore

@objc(TestPlugin) public class TestPlugin: NSObject, CrawlingPluginProtocol {
    public override init() {
        super.init()
    }

    public func testMe() -> String {
        return "Hi from plugin!"
    }
}

