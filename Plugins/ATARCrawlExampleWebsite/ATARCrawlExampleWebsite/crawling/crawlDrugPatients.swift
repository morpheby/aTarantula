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

    var relatedCrawlables: [CrawlableObject] = []

    var patientsAll: [Patient] = []
    var pageNum: Int = 1
    var allPages: [Int] = [1]
    var pageCount: Int? = nil
    var allPagesFound = false

    repeat {
        guard var objectUrlComponents = URLComponents(url: objectUrl, resolvingAgainstBaseURL: true) else {
            fatalError("Unable to decompose URL \(objectUrl)")
        }
        if pageNum > 1 {
            if objectUrlComponents.queryItems == nil { objectUrlComponents.queryItems = [] }
            objectUrlComponents.queryItems?.append(URLQueryItem(name: "page", value: "\(pageNum)"))
        }

        guard let actualUrl = pageNum > 1 ? objectUrlComponents.url : objectUrl else {
            fatalError("Unable to reconstruct URL \(objectUrlComponents)")
        }
        let data = try plugin.networkManager?.stringData(url: actualUrl) ?? String(contentsOf: actualUrl)

        guard let html = Kanna.HTML(html: data, encoding: .utf8) else {
            throw CrawlError(url: objectUrl, info: "Unable to parse HTML")
        }

        let patients: [Patient] = {
            html.xpath("//div[@id='patient-search-table']//div[@class='tertiary-title']/a/@href").flatMap { element in
                guard let urlString = element.text,
                    let url = URL(string: urlString, relativeTo: plugin.baseUrl) else { return nil }

                let relatedObject = repo.performAndWait {
                    repo.readAllObjects(Patient.self, withSelection: .object(url: url)).first ??
                        repo.newObject(forUrl: url, type: Patient.self)
                }
                relatedCrawlables.append(relatedObject)
                return relatedObject
            }
        }() .flatMap { x in x }

        patientsAll.append(contentsOf: patients)

        if !allPagesFound {
            let pages: [Int] = {
                html.xpath("//div[contains(@class, 'paging-ui')]//div[@class='pagination']/a[position() > 1 and position() < last()]").flatMap { element in
                    guard let pageNumStr = element.text,
                    let pageNum = Int(pageNumStr) else { return nil }

                    return pageNum
                }
            }() .flatMap { x in x }

            allPages = Array(Set(allPages + pages)).sorted()

            allPagesFound = {
                for (prevPage, page) in zip([1] + pages.dropLast(), pages) {
                    if prevPage + 1 != page {
                        return false
                    }
                }
                return true
            }()

            if let lastPage = pages.last {
                pageCount = lastPage
            } else {
                pageCount = 1
            }
        }

        pageNum += 1
    } while pageNum <= pageCount!

    // Store object
    repo.perform {
        // We don't have one single HTML document for the multi-page data,
        // so we just set it to nil
        object.originalHtml = nil

        object.patients = Set(patientsAll) as NSSet

        object.objectIsCrawled = true

        if needsToBeSelected(object: object, filterMethod: plugin.filterMethod) {
            object.select(newObjects: relatedCrawlables)
        } else {
            object.unselect(newObjects: relatedCrawlables)
        }
    }
}
