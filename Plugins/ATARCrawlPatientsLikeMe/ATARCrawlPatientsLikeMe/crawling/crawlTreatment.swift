//
//  crawlTreatment.swift
//  ATARCrawlExampleWebsite
//
//  Created by Ilya Mikhaltsou on 9/11/17.
//  Copyright © 2017 morpheby. All rights reserved.
//

import Foundation
import Kanna
import Regex
import TarantulaPluginCore

func crawlTreatment(_ object: Treatment, usingRepository repo: Repository, withPlugin plugin: ATARCrawlExampleWebsiteCrawlerPlugin) throws {

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

    let name = html.xpath("//li[@class='toolbar-title']//span[@itemprop='name']").first?.text

    let category: DrugCategory? = {
        html.xpath("//div[@id='overview']//header[@id='summary']/../p[strong='Category:']/a/@href").flatMap { element in
            guard let urlString = element.text,
            let url = URL(string: urlString, relativeTo: plugin.baseUrl) else { return nil }

            let relatedObject = repo.performAndWait {
                repo.readAllObjects(DrugCategory.self, withSelection: .object(url: url)).first ??
                    repo.newObject(forUrl: url, type: DrugCategory.self)
            }
            relatedCrawlables.append(relatedObject)
            return relatedObject
        }
    }() .flatMap { x in x } .first

    let types: [Treatment] = {
        html.xpath("//div[@id='overview']//header[@id='summary']/../p[strong='Most popular types:']//a/@href").flatMap { element in
            guard let urlString = element.text,
            let url = URL(string: urlString, relativeTo: plugin.baseUrl) else { return nil }

            let relatedObject = repo.performAndWait {
                repo.readAllObjects(Treatment.self, withSelection: .object(url: url)).first ??
                    repo.newObject(forUrl: url, type: Treatment.self)
            }
            relatedCrawlables.append(relatedObject)
            return relatedObject
        }
    }() .flatMap { x in x }

    let generic: Treatment? = {
        html.xpath("//div[@id='overview']//header[@id='summary']/../p[strong='Generic name:']//a/@href").flatMap { element in
            guard let urlString = element.text,
            let url = URL(string: urlString, relativeTo: plugin.baseUrl) else { return nil }

            let relatedObject = repo.performAndWait {
                repo.readAllObjects(Treatment.self, withSelection: .object(url: url)).first ??
                    repo.newObject(forUrl: url, type: Treatment.self)
            }
            relatedCrawlables.append(relatedObject)
            return relatedObject
        }
    }() .flatMap { x in x } .first

    let description = html.xpath("//div[@id='overview']//header[@id='summary']/../p[@itemprop='description']").first?.text

    let purposes: TreatmentPurposes? = {
        html.xpath("//div[@id='overview']//div[@data-widget='treatment_report_section']//tbody/@data-url").flatMap { element in
            guard let urlString = element.text,
            let url = URL(string: urlString, relativeTo: plugin.baseUrl) else { return nil }

            let relatedObject = repo.performAndWait {
                repo.readAllObjects(TreatmentPurposes.self, withSelection: .object(url: url)).first ??
                    repo.newObject(forUrl: url, type: TreatmentPurposes.self)
            }
            relatedCrawlables.append(relatedObject)
            return relatedObject
        }
    }() .flatMap { x in x } .first

    let patients: DrugPatients? = {
        html.xpath("//div[@id='overview']//div[@class='glass-panel' and a='See all ']/a/@href").flatMap { element in
            guard let urlString = element.text,
            let url = URL(string: urlString, relativeTo: plugin.baseUrl) else { return nil }

            let relatedObject = repo.performAndWait {
                repo.readAllObjects(DrugPatients.self, withSelection: .object(url: url)).first ??
                    repo.newObject(forUrl: url, type: DrugPatients.self)
            }
            relatedCrawlables.append(relatedObject)
            return relatedObject
        }
        }() .flatMap { x in x } .first

    let sideeffect_severities: [DrugSideEffectSeverity] = {
        html.xpath("//div[@id='overview']//div[h2='Side effects']//tr[@data-yah-key='overall_side_effects']").flatMap { element in
            guard let id_value_str = element.xpath("@data-yah-value").first?.text,
            let id_value = Int(id_value_str) else { return nil }

            let tmpArray = element.xpath("td").map { e in e.text }
            guard tmpArray.count == 3,
            let name = tmpArray[0],
            let countStr = tmpArray[2],
            let count = Int(countStr) else { return nil }

            let relatedObject: DrugSideEffectSeverity = repo.performAndWait {
                let object = repo.newObject(type: DrugSideEffectSeverity.self)
                object.id_value = Int64(id_value)
                object.name = name
                object.patients_count = Int64(count)
                return object
            }
            return relatedObject
        }
    }() .flatMap { x in x }


    // Store object
    repo.perform {
        object.originalHtml = data

        object.name = name
        object.drug_description = description
        object.category = category
        object.types = Set(types) as NSSet

        assert(generic == nil || object.generic == nil || object.generic == generic,
               "Generic for Treatment \(name ?? "nil") (\(generic?.id ?? "nil"): \(generic?.name ?? "nil")) does not equal previously known generic (\(object.generic?.id ?? "nil"): \(object.generic?.name ?? "nil"))")
        object.generic = generic

        object.purposes = purposes
        object.patients = patients
        object.sideeffect_severities = Set(sideeffect_severities) as NSSet

        object.objectIsCrawled = true
    }
}

