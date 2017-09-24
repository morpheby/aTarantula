//
//  crawlDrugPatients.swift
//  ATARCrawlExampleWebsite
//
//  Created by Ilya Mikhaltsou on 9/24/17.
//  Copyright © 2017 morpheby. All rights reserved.
//

import Foundation
import Kanna
import Regex
import TarantulaPluginCore

func crawlDrugPatients(_ object: DrugPatients, usingRepository repo: Repository, withPlugin plugin: ATARCrawlExampleWebsiteCrawlerPlugin) throws {

    let objectUrl = repo.performAndWait {
        object.objectUrl
    }

    guard !(repo.performAndWait { object.objectIsCrawled }) else {
        return
    }

    let data = try plugin.networkManager?.stringData(url: objectUrl) ?? String(contentsOf: objectUrl)

    var relatedCrawlables: [CrawlableObject] = []

    guard let html = Kanna.HTML(html: data, encoding: .utf8) else {
        throw CrawlError(url: objectUrl, info: "Unable to parse HTML")
    }


}
