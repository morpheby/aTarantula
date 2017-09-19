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
        html.xpath("//div[@id='overview']//div[@data-widget='treatment_report_section']/table[caption='Reported purpose & perceived effectiveness']/tbody/@data-url").flatMap { element in
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
        html.xpath("//div[@id='overview']//div[@class='glass-panel']/a[contains(normalize-space(text()),'See all')]/@href").flatMap { element in
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

            let tmpArray = element.xpath("td")
            guard tmpArray.count == 3,
            let name = (tmpArray[0].xpath("text()").flatMap { x in x.text?.trimmingCharacters(in: .whitespacesAndNewlines) } .filter { x in x.count != 0 }.first),
            let countStr = tmpArray[2].xpath("a").first?.text,
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

    let sideeffects: DrugSideEffects? = {
        html.xpath("//div[@id='overview']//div[@data-widget='treatment_report_section']/table[contains(@summary,'Side effects')]/tbody/@data-url").flatMap { element in
            guard let urlString = element.text,
                let url = URL(string: urlString, relativeTo: plugin.baseUrl) else { return nil }

            let relatedObject = repo.performAndWait {
                repo.readAllObjects(DrugSideEffects.self, withSelection: .object(url: url)).first ??
                    repo.newObject(forUrl: url, type: DrugSideEffects.self)
            }
            relatedCrawlables.append(relatedObject)
            return relatedObject
        }
    }() .flatMap { x in x } .first

    let dosages: [DrugDosageCount] = {
        html.xpath("//div[@id='overview']//div[h2='Dosages']//tr[@data-yah-key='dosage']").flatMap { element in
            guard let id_value = element.xpath("@data-yah-value").first?.text else { return nil }

            let tmpArray = element.xpath("td | th")
            guard tmpArray.count == 3,
                let name = (tmpArray[0].xpath("text()").flatMap { x in x.text?.trimmingCharacters(in: .whitespacesAndNewlines) } .filter { x in x.count != 0 }.first),
                let countStr = tmpArray[1].xpath("a").first?.text,
                let count = Int(countStr) else { return nil }

            let relatedObject: DrugDosageCount = repo.performAndWait {
                let object = repo.newObject(type: DrugDosageCount.self)
                object.id_value = id_value
                object.name = name
                object.patients_count = Int64(count)
                return object
            }
            return relatedObject
        }
    }() .flatMap { x in x }

    let stop_reasons: [DrugStopReason] = {
        html.xpath("//div[@id='overview']//div[contains(h2,'Why patients stopped taking')]//tr[@data-yah-key='stop_reason']").flatMap { element in
            guard let id_value_str = element.xpath("@data-yah-value").first?.text,
                let id_value = Int(id_value_str) else { return nil }

            let tmpArray = element.xpath("td | th")
            guard tmpArray.count == 3,
                let name = (tmpArray[0].xpath("text()").flatMap { x in x.text?.trimmingCharacters(in: .whitespacesAndNewlines) } .filter { x in x.count != 0 }.first),
                let countStr = tmpArray[1].xpath("a").first?.text,
                let count = Int(countStr) else { return nil }

            let relatedObject: DrugStopReason = repo.performAndWait {
                let object = repo.newObject(type: DrugStopReason.self)
                object.id_value = Int64(id_value)
                object.name = name
                object.patients_count = Int64(count)
                return object
            }
            return relatedObject
        }
    }() .flatMap { x in x }

    let current_durations: [DrugDuration] = {
        html.xpath("//div[@id='overview']//div[h2='Duration']//tr[@data-yah-key='duration_current']").flatMap { element in
            guard let id_value_str = element.xpath("@data-yah-value").first?.text,
                let id_value = Int(id_value_str) else { return nil }

            let tmpArray = element.xpath("td | th")
            guard tmpArray.count == 3,
                let name = (tmpArray[0].xpath("text()").flatMap { x in x.text?.trimmingCharacters(in: .whitespacesAndNewlines) } .filter { x in x.count != 0 }.first),
                let countStr = tmpArray[1].xpath("a").first?.text,
                let count = Int(countStr) else { return nil }

            let relatedObject: DrugDuration = repo.performAndWait {
                let object = repo.newObject(type: DrugDuration.self)
                object.id_value = Int64(id_value)
                object.name = name
                object.patients_count = Int64(count)
                return object
            }
            return relatedObject
        }
    }() .flatMap { x in x }

    let stopped_durations: [DrugDuration] = {
        html.xpath("//div[@id='overview']//div[h2='Duration']//tr[@data-yah-key='duration_stopped']").flatMap { element in
            guard let id_value_str = element.xpath("@data-yah-value").first?.text,
                let id_value = Int(id_value_str) else { return nil }

            let tmpArray = element.xpath("td | th")
            guard tmpArray.count == 3,
                let name = (tmpArray[0].xpath("text()").flatMap { x in x.text?.trimmingCharacters(in: .whitespacesAndNewlines) } .filter { x in x.count != 0 }.first),
                let countStr = tmpArray[1].xpath("a").first?.text,
                let count = Int(countStr) else { return nil }

            let relatedObject: DrugDuration = repo.performAndWait {
                let object = repo.newObject(type: DrugDuration.self)
                object.id_value = Int64(id_value)
                object.name = name
                object.patients_count = Int64(count)
                return object
            }
            return relatedObject
        }
    }() .flatMap { x in x }

    let adherences: [DrugAdherence] = {
        html.xpath("//div[@id='overview']//div[contains(caption,'Adherence')]//tr[@data-yah-key='adherence']").flatMap { element in
            guard let id_value_str = element.xpath("@data-yah-value").first?.text,
                let id_value = Int(id_value_str) else { return nil }

            let tmpArray = element.xpath("td | th")
            guard tmpArray.count == 3,
                let name = (tmpArray[0].xpath("text()").flatMap { x in x.text?.trimmingCharacters(in: .whitespacesAndNewlines) } .filter { x in x.count != 0 }.first),
                let countStr = tmpArray[1].xpath("a").first?.text,
                let count = Int(countStr) else { return nil }

            let relatedObject: DrugAdherence = repo.performAndWait {
                let object = repo.newObject(type: DrugAdherence.self)
                object.id_value = Int64(id_value)
                object.name = name
                object.patients_count = Int64(count)
                return object
            }
            return relatedObject
        }
    }() .flatMap { x in x }

    let burdens: [DrugBurden] = {
        html.xpath("//div[@id='overview']//div[contains(caption,'Burden')]//tr[@data-yah-key='burden']").flatMap { element in
            guard let id_value_str = element.xpath("@data-yah-value").first?.text,
                let id_value = Int(id_value_str) else { return nil }

            let tmpArray = element.xpath("td | th")
            guard tmpArray.count == 3,
                let name = (tmpArray[0].xpath("text()").flatMap { x in x.text?.trimmingCharacters(in: .whitespacesAndNewlines) } .filter { x in x.count != 0 }.first),
                let countStr = tmpArray[1].xpath("a").first?.text,
                let count = Int(countStr) else { return nil }

            let relatedObject: DrugBurden = repo.performAndWait {
                let object = repo.newObject(type: DrugBurden.self)
                object.id_value = Int64(id_value)
                object.name = name
                object.patients_count = Int64(count)
                return object
            }
            return relatedObject
        }
    }() .flatMap { x in x }

    let costs: [DrugCost] = {
        html.xpath("//div[@id='overview']//div[contains(caption,'Cost per month')]//tr[@data-yah-key='cost']").flatMap { element in
            guard let id_value_str = element.xpath("@data-yah-value").first?.text,
                let id_value = Int(id_value_str) else { return nil }

            let tmpArray = element.xpath("td | th")
            guard tmpArray.count == 3,
                let name = (tmpArray[0].xpath("text()").flatMap { x in x.text?.trimmingCharacters(in: .whitespacesAndNewlines) } .filter { x in x.count != 0 }.first),
                let countStr = tmpArray[1].xpath("a").first?.text,
                let count = Int(countStr) else { return nil }

            let relatedObject: DrugCost = repo.performAndWait {
                let object = repo.newObject(type: DrugCost.self)
                object.id_value = Int64(id_value)
                object.name = name
                object.patients_count = Int64(count)
                return object
            }
            return relatedObject
        }
    }() .flatMap { x in x }

    let switched_from: [DrugSwitch] = {
        html.xpath("//div[@id='overview']//div[h2='What people switch to and from']//tr[@data-yah-key='switched_from_treatment']").flatMap { element in
            guard let id_value_str = element.xpath("@data-yah-value").first?.text,
                let id_value = Int(id_value_str) else { return nil }

            let tmpArray = element.xpath("td | th")
            guard tmpArray.count == 3,
                let name = (tmpArray[0].xpath("text()").flatMap { x in x.text?.trimmingCharacters(in: .whitespacesAndNewlines) } .filter { x in x.count != 0 }.first),
                let countStr = tmpArray[1].xpath("a").first?.text,
                let count = Int(countStr) else { return nil }

            guard let assembledUrl = URL(string: "https://examplewebsite/treatments/show/\(id_value)") else { return nil }

            let relatedObject = repo.performAndWait {
                repo.readAllObjects(Treatment.self, withSelection: .object(url: assembledUrl)).first ??
                    repo.newObject(forUrl: assembledUrl, type: Treatment.self)
            }
            assert(relatedObject.name == nil || relatedObject.name == name, "Invalid DrugSwitch parameters: Treatment names mismatch")
            relatedCrawlables.append(relatedObject)

            let otherObject: DrugSwitch = repo.performAndWait {
                if let o = repo.readAllObjects(DrugSwitch.self,
                                               withPredicate: NSPredicate(format: "\(#keyPath(DrugSwitch.switched_from)) == %@ && \(#keyPath(DrugSwitch.switched_to)) == %@", argumentArray: [relatedObject, object])).first {
                    assert(o.patients_count == Int64(count), "Invalid DrugSwitch parameters: patient_count mismatch")
                    assert(o.switched_from == relatedObject, "Invalid DrugSwitch parameters: switch values mismatch")
                    assert(o.switched_to == object, "Invalid DrugSwitch parameters: switch values mismatch")
                    return o
                } else {
                    let o = repo.newObject(type: DrugSwitch.self)
                    o.patients_count = Int64(count)
                    o.switched_from = relatedObject
                    o.switched_to = object
                    return o
                }
            }
            return otherObject
        }
    }() .flatMap { x in x }

    let switched_to: [DrugSwitch] = {
        html.xpath("//div[@id='overview']//div[h2='What people switch to and from']//tr[@data-yah-key='switched_to_treatment']").flatMap { element in
            guard let id_value_str = element.xpath("@data-yah-value").first?.text,
                let id_value = Int(id_value_str) else { return nil }

            let tmpArray = element.xpath("td | th")
            guard tmpArray.count == 3,
                let name = (tmpArray[0].xpath("text()").flatMap { x in x.text?.trimmingCharacters(in: .whitespacesAndNewlines) } .filter { x in x.count != 0 }.first),
                let countStr = tmpArray[1].xpath("a").first?.text,
                let count = Int(countStr) else { return nil }

            guard let assembledUrl = URL(string: "https://examplewebsite/treatments/show/\(id_value)") else { return nil }

            let relatedObject = repo.performAndWait {
                repo.readAllObjects(Treatment.self, withSelection: .object(url: assembledUrl)).first ??
                    repo.newObject(forUrl: assembledUrl, type: Treatment.self)
            }
            assert(relatedObject.name == nil || relatedObject.name == name, "Invalid DrugSwitch parameters: Treatment names mismatch")
            relatedCrawlables.append(relatedObject)

            let otherObject: DrugSwitch = repo.performAndWait {
                if let o = repo.readAllObjects(DrugSwitch.self, withPredicate: NSPredicate(format: "\(#keyPath(DrugSwitch.switched_from)) == %@ && \(#keyPath(DrugSwitch.switched_to)) == %@", argumentArray: [object, relatedObject])).first {
                    assert(o.patients_count == Int64(count), "Invalid DrugSwitch parameters: patient_count mismatch")
                    assert(o.switched_from == object, "Invalid DrugSwitch parameters: switch values mismatch")
                    assert(o.switched_to == relatedObject, "Invalid DrugSwitch parameters: switch values mismatch")
                    return o
                } else {
                    let o = repo.newObject(type: DrugSwitch.self)
                    o.patients_count = Int64(count)
                    o.switched_from = object
                    o.switched_to = relatedObject
                return o
                }
            }
            return otherObject
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
        object.sideeffects = sideeffects

        object.dosages = Set(dosages) as NSSet
        object.stop_reasons = Set(stop_reasons) as NSSet
        object.current_durations = Set(current_durations) as NSSet
        object.stopped_durations = Set(stopped_durations) as NSSet
        object.adherences = Set(adherences) as NSSet
        object.burdens = Set(burdens) as NSSet
        object.costs = Set(costs) as NSSet
        object.switched_from = Set(switched_from) as NSSet
        object.switched_to = Set(switched_to) as NSSet

        object.objectIsCrawled = true
    }
}

