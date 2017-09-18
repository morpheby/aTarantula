//
//  crawl.swift
//  ATARCrawlExampleWebsite
//
//  Created by Ilya Mikhaltsou on 9/11/17.
//  Copyright © 2017 morpheby. All rights reserved.
//

import Foundation
import TarantulaPluginCore

func crawl(object: CrawlableObject, usingRepository repository: Repository, withPlugin plugin: ATARCrawlExampleWebsiteCrawlerPlugin) throws {
    switch (object) {
    case let o as Treatment:
        try crawlTreatment(o, usingRepository: repository, withPlugin: plugin)
    default:
        let url = repository.performAndWait { object.objectUrl }
        throw CrawlError(url: url, info: "Unsupported object type for \(type(of: plugin))")
    }
}
