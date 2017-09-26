//
//  crawlDrugSwitches.swift
//  ATARCrawlExampleWebsite
//
//  Created by Ilya Mikhaltsou on 9/18/17.
//  Copyright © 2017 morpheby. All rights reserved.
//

import Foundation
import Kanna
import Regex
import TarantulaPluginCore

func crawlDrugSwitches(_ object: DrugSwitches, usingRepository repo: Repository, withPlugin plugin: ATARCrawlExampleWebsiteCrawlerPlugin) throws {

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

    let switch_selector = ["switched_from_treatment", "switched_to_treatment"]

    enum Selection: Int {
        case from = 0
        case to = 1
        case error = -1
    }

    let selected = repo.performAndWait {
        object.drug_from != nil ? Selection.from :
        object.drug_to != nil ? Selection.to : Selection.error
    }
    guard selected != .error else {
        // Discard the object — some drugs don't have one of those
        repo.perform { repo.delete(object: object) }
        return
    }

    let switched: [DrugSwitch] = {
        html.xpath("//tr[@data-yah-key='\(switch_selector[selected.rawValue])']").flatMap { element in
            guard let id_value_str = element.xpath("@data-yah-value").first?.text,
            let id_value = Int(id_value_str) else { return nil }

            let tmpArray = element.xpath("td | th")

            guard tmpArray.count == 3,
            let name = (tmpArray[0].xpath("text()").flatMap { x in x.text?.trimmingCharacters(in: .whitespacesAndNewlines) } .filter { x in x.count != 0 }.first),
            let countStr = tmpArray[1].text?.trimmingCharacters(in: .whitespacesAndNewlines),
            let count = Int(countStr) else { return nil }

            guard let assembledUrl = URL(string: "https://examplewebsite/treatments/show/\(id_value)") else { return nil }

            let relatedObject: Treatment = repo.performAndWait {
                let o = repo.readAllObjects(Treatment.self, withSelection: .object(url: assembledUrl)).first ??
                    repo.newObject(forUrl: assembledUrl, type: Treatment.self)
                precondition(o.name == nil || o.name == name, "Invalid DrugSwitch parameters: Treatment names mismatch")
                return o
            }
            relatedCrawlables.append(relatedObject)

            let otherObject: DrugSwitch = repo.performAndWait {
                let from: Treatment, to: Treatment
                switch selected {
                case .from:
                    from = object.drug_from!
                    to = relatedObject
                case .to:
                    from = relatedObject
                    to = object.drug_to!
                default:
                    fatalError("Unreachable")
                }
//                if let o = repo.readAllObjects(DrugSwitch.self,
//                                               withPredicate: NSPredicate(format: "\(#keyPath(DrugSwitch.switched_from)) == %@ && \(#keyPath(DrugSwitch.switched_to)) == %@", argumentArray: [from, to])).first {
//                    assert(o.patients_count == Int64(count), "Invalid DrugSwitch parameters: patient_count mismatch. DS from \(from) to \(to). Original value: \(o.patients_count), New value: \(count)")
//                    return o
//                } else {
                // Apparently, those numbers are taken almost like if from the air. It is "normal"
                // for one drug to list another here, and not vice versa, have different values, etc.
                // So for the time being, we just make duplicates. We can decide what to do later.
                    let o = repo.newObject(type: DrugSwitch.self)
                    o.patients_count = Int64(count)

                    o.switched_from = from
                    o.switched_to = to
                    return o
//                }
            }
            return otherObject
        }
    }() .flatMap { x in x }

    // Store object
    repo.perform {
        object.originalHtml = data

        object.drug_switch = Set(switched) as NSSet

        object.objectIsCrawled = true

        if needsToBeSelected(object: object, filterMethod: plugin.filterMethod) {
            object.select(newObjects: relatedCrawlables)
        } else {
            object.unselect(newObjects: relatedCrawlables)
        }
    }
}

