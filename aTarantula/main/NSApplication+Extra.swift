//
//  NSApplication+Extra.swift
//  aTarantula
//
//  Created by Ilya Mikhaltsou on 9/2/17.
//  Copyright © 2017 morpheby. All rights reserved.
//

import Foundation

fileprivate class SharedApplicationExtension {
    lazy var name: String = {
        return Bundle.main.object(forInfoDictionaryKey: kCFBundleNameKey as String) as! String
    }()

    lazy var controller: ApplicationController = ApplicationController()

    static let shared: SharedApplicationExtension = {
        return SharedApplicationExtension()
    }()
}

extension NSApplication {
    var name: String {
        return SharedApplicationExtension.shared.name
    }

    var controller: ApplicationController {
        return SharedApplicationExtension.shared.controller
    }
}
