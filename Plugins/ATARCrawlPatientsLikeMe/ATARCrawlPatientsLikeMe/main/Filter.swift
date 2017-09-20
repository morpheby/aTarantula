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

func needsToBeFiltered(object: CrawlableObject, method: FilterMethod) -> Bool {
    switch method {
    case .none:
        return false
    case let .closure(f):
        return f(object)
    }
}

