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
    case let o as DrugSwitches:
        try crawlDrugSwitches(o, usingRepository: repository, withPlugin: plugin)
    case let o as TreatmentPurposes:
        try crawlTreatmentPurposes(o, usingRepository: repository, withPlugin: plugin)
    case let o as DrugSideEffects:
        try crawlDrugSideEffects(o, usingRepository: repository, withPlugin: plugin)
    case let o as DrugPatients:
        try crawlDrugPatients(o, usingRepository: repository, withPlugin: plugin)
    case let o as Patient:
        try crawlPatient(o, usingRepository: repository, withPlugin: plugin)
    case let o as PatientForumPosts:
        try crawlForumPosts(o, usingRepository: repository, withPlugin: plugin)
    default:
        let url = repository.performAndWait { object.objectUrl }
        throw CrawlError(url: url, info: "Unsupported object type \(type(of: object)) for \(type(of: plugin))")
    }
}

func checkLoggedIn(in data: String) -> Bool {
    return !data.contains("/users/sign_in")
}
