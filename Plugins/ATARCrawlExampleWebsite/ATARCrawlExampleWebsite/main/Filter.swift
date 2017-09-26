//
//  Filter.swift
//  ATARCrawlExampleWebsite
//
//  Created by Ilya Mikhaltsou on 9/19/17.
//  Copyright © 2017 morpheby. All rights reserved.
//

import Foundation
import TarantulaPluginCore

enum FilterMethod {
    case none
    case closure((CrawlableObject) -> Bool)
}

// Returns true if the object needs to be included in the output with the given filter method
func needsToBeSelected(object: CrawlableObject, filterMethod method: FilterMethod) -> Bool {
    switch method {
    case .none:
        return true
    case let .closure(f):
        return f(object)
    }
}

