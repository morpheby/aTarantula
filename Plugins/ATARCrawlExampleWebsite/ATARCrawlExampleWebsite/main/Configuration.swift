//
//  Configuration.swift
//  ATARCrawlExampleWebsite
//
//  Created by Ilya Mikhaltsou on 10/17/17.
//  Copyright © 2017 morpheby. All rights reserved.
//

import Foundation

internal struct Configuration {
    static let websiteBaseUrl = "https://www.example.com"

    static let specialButton: (ATARCrawlExampleWebsiteCrawlerPlugin) -> () = { plugin in
        // Input here any code for the "Special Button" in Settings dialog
    }
}
