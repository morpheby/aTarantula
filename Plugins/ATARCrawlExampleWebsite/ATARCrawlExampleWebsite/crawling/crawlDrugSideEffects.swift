//
//  crawlDrugSideEffects.swift
//  ATARCrawlExampleWebsite
//
//  Created by Ilya Mikhaltsou on 9/24/17.
//  Copyright © 2017 morpheby. All rights reserved.
//

import Foundation
import Kanna
import Regex
import TarantulaPluginCore

func crawlDrugSideEffects(_ object: DrugSideEffects, usingRepository repo: Repository, withPlugin plugin: ATARCrawlExampleWebsiteCrawlerPlugin) throws {

    let objectUrl = repo.performAndWait {
        object.objectUrl
    }

    guard !(repo.performAndWait { object.objectIsCrawled }) else {
        return
    }

    let data = try String(contentsOf: objectUrl)

    var relatedCrawlables: [CrawlableObject] = []

    guard let html = Kanna.HTML(html: data, encoding: .utf8) else {
        throw CrawlError(url: objectUrl, info: "Unable to parse HTML")
    }

    let sideeffects: [DrugSideEffect] = {
        html.xpath("//tr[@data-yah-key='side_effect']").flatMap { element in
            guard let id_value = element.xpath("@data-yah-value").first?.text else { return nil }

            let tmpArray = element.xpath("td | th")

            guard tmpArray.count == 3,
            let sideeffect: Condition = (tmpArray[0].xpath(".//a/@href").flatMap { element in
                guard let urlString = element.text,
                    let url = URL(string: urlString, relativeTo: plugin.baseUrl) else { return nil }

                let relatedObject: Condition = repo.performAndWait {
                    if url.absoluteString.contains("symptoms") {
                        return repo.readAllObjects(Symptom.self, withSelection: .object(url: url)).first ??
                            repo.newObject(forUrl: url, type: Symptom.self)
                    } else if url.absoluteString.contains("treatment_purposes") {
                        return repo.readAllObjects(TreatmentPurpose.self, withSelection: .object(url: url)).first ??
                            repo.newObject(forUrl: url, type: TreatmentPurpose.self)
                    } else {
                        return repo.readAllObjects(Condition.self, withSelection: .object(url: url)).first ??
                            repo.newObject(forUrl: url, type: Condition.self)
                    }
                }
                relatedCrawlables.append(relatedObject)
                return relatedObject
            }) .first,
            let countStr = tmpArray[1].text?.trimmingCharacters(in: .whitespacesAndNewlines),
            let count = Int(countStr) else { return nil }

            let relatedObject: DrugSideEffect = repo.performAndWait {
                let o = repo.newObject(type: DrugSideEffect.self)
                o.patients_count = Int64(count)
                o.id_value = id_value
                o.sideeffect = sideeffect
                return o
            }
            return relatedObject
        }
        }() .flatMap { x in x }

    // Store object
    repo.perform {
        object.originalHtml = data

        object.sideeffects = Set(sideeffects) as NSSet

        object.objectIsCrawled = true

        if needsToBeFiltered(object: object, method: plugin.filterMethod) {
            object.filter(newObjects: relatedCrawlables)
        } else {
            object.unfilter(newObjects: relatedCrawlables)
        }

    }
}

