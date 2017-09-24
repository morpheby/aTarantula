//
//  crawlTreatmentPurposes.swift
//  ATARCrawlExampleWebsite
//
//  Created by Ilya Mikhaltsou on 9/20/17.
//  Copyright © 2017 morpheby. All rights reserved.
//

import Foundation
import Kanna
import Regex
import TarantulaPluginCore

func crawlTreatmentPurposes(_ object: TreatmentPurposes, usingRepository repo: Repository, withPlugin plugin: ATARCrawlExampleWebsiteCrawlerPlugin) throws {

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

    let purposes: [DrugTreatmentPurpose] = {
        html.xpath("//tr[@data-yah-key='purpose']").flatMap { element in
            guard let id_value = element.xpath("@data-yah-value").first?.text else { return nil }

            let tmpArray = element.xpath("td | th")

            guard tmpArray.count == 4,
            let purpose: TreatmentPurpose = (tmpArray[0].xpath(".//a/@href").flatMap { element in
                guard let urlString = element.text,
                let url = URL(string: urlString, relativeTo: plugin.baseUrl) else { return nil }

                let relatedObject = repo.performAndWait {
                    repo.readAllObjects(TreatmentPurpose.self, withSelection: .object(url: url)).first ??
                        repo.newObject(forUrl: url, type: TreatmentPurpose.self)
                }
                relatedCrawlables.append(relatedObject)
                return relatedObject
            }) .first,
            let countStr = tmpArray[1].text?.trimmingCharacters(in: .whitespacesAndNewlines),
            let count = Int(countStr) else { return nil }
            let effectivenesses: [DrugTreatmentPurposeEffectiveness] = tmpArray[3].xpath(".//li").flatMap { element in
                guard let effectivenessRegex = "See (\\d+) evaluations from (\\d+) patients with (\\w+) perceived effectiveness".r else { fatalError("Wrong regex")}
                guard let text = element.text,
                let reResult = effectivenessRegex.findFirst(in: text),
                let effectivenessCountStr = reResult.group(at: 2),
                let effectivenessCount = Int(effectivenessCountStr),
                let effectivenessName = reResult.group(at: 3) else { return nil }

                let relatedObject: DrugTreatmentPurposeEffectiveness = repo.performAndWait {
                    let o = repo.newObject(type: DrugTreatmentPurposeEffectiveness.self)
                    o.name = effectivenessName
                    o.count = Int64(effectivenessCount)
                    return o
                }

                return relatedObject
            }

            let relatedObject: DrugTreatmentPurpose = repo.performAndWait {
                let o = repo.newObject(type: DrugTreatmentPurpose.self)
                o.effectivenesses = Set(effectivenesses) as NSSet
                o.patients_count = Int64(count)
                o.id_value = id_value
                o.purpose = purpose
                return o
            }
            return relatedObject
        }
    }() .flatMap { x in x }

    // Store object
    repo.perform {
        object.originalHtml = data

        object.purposes = Set(purposes) as NSSet

        object.objectIsCrawled = true

        if needsToBeFiltered(object: object, method: plugin.filterMethod) {
            object.filter(newObjects: relatedCrawlables)
        } else {
            object.unfilter(newObjects: relatedCrawlables)
        }

    }
}

