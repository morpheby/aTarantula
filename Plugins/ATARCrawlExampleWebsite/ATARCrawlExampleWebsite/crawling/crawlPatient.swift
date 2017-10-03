//
//  crawlPatient.swift
//  ATARCrawlExampleWebsite
//
//  Created by Ilya Mikhaltsou on 10/3/17.
//  Copyright © 2017 morpheby. All rights reserved.
//

import Foundation
import Kanna
import Regex
import TarantulaPluginCore

func crawlPatient(_ object: Patient, usingRepository repo: Repository, withPlugin plugin: ATARCrawlExampleWebsiteCrawlerPlugin) throws {

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

    guard let id: Int = ({
        guard let components = URLComponents(url: objectUrl, resolvingAgainstBaseURL: true) else { return nil }
        let path = components.path

        guard let idRegex = ".*(\\d+)$".r else { fatalError("Wrong regex")}
        guard let reResult = idRegex.findFirst(in: path),
        let idStr = reResult.group(at: 1),
        let id = Int(idStr) else { return nil }
        return id
    }()) else {
        throw CrawlError(url: objectUrl, info: "Unable to extract id from the URL")
    }

    guard case let (.some(csrfTokenParam), .some(csrfTokenValue)) = ({
        return (html.xpath("//meta[@name='csrf-param']/@content").first?.text,
                html.xpath("//meta[@name='csrf-token']/@content").first?.text)
    }()) else {
        throw CrawlError(url: objectUrl, info: "Patient crawling requires CSRF token, which was not found in HTML data")
    }

    // Fetching JSON data seems like not an obvious task here.
    //
    // Option 1: Simple Separate Job for each of JSON URLs
    // Even though it would be best to fetch JSON data as a separate job, CSRF token may already expire.
    // Generally, we can't predict when CSRF token is going to expire. What more, we also can't predict when
    // the JSON fetch job would've been executed (or even will it have the same cookie — user may have paused).
    // And if the CSRF token happens to be invalidated, we will need to fetch a new one — from here, — and that
    // will require this whole procudure to re-run.
    //
    // Option 2: Special CSRF Separate Job for each of JSON URLs
    // Here, each JSON request will be accompanied by a special URL of parent HTML, which would contain
    // CSRF token, and the latest CSRF token. This way, if the CSRF token stored works — we will have
    // successfuly fetched the data; if it doesn't — we fetch the original URL.
    // Interestingly enough, the Genetic System Architecture would've hepled a lot (and in fact, this whole
    // project would've been so much simpler...).
    //
    // Option 3: Fetch JSON inside this job
    // If we fetch all the data in here, we have a guarantee that CSRF token is still valid (and if it's not,
    // we can gracefully fail the whole job and restart it eventually). As a potential problem — the time for
    // all the requests may be quite long, and the logic may get quite complicated.
    //
    // For now, let's try with option 2.

    // Create a CSRFToken object
    let csrfToken: CSRFToken = repo.performAndWait {
        let object = repo.newObject(type: CSRFToken.self)

        object.original_url = string(url: objectUrl)
        object.token_param = csrfTokenParam
        object.token_value = csrfTokenValue
        return object
    }

    // Despite the chosen option, we would still need one JSON object to be fetched right here:
    // registry of available objects.

    struct JsonChartRef: Codable {
        let name: String
        let url: String
    }

    let specificUrls: [JsonChartRef]? = try {
        guard let assembledUrl: URL = ({
            guard let url = URL(string: "/members/\(id)/chart_json.json", relativeTo: plugin.baseUrl),
            var urlComponents = URLComponents(url: url,
                                              resolvingAgainstBaseURL: true) else { return nil }
            urlComponents.queryItems = [
                URLQueryItem(name: csrfTokenParam, value: csrfTokenValue)
            ]
            return urlComponents.url
        }()) else { return nil }

        let jsonData = try plugin.networkManager?.data(url: objectUrl) ?? Data(contentsOf: objectUrl)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode([String: [String: JsonChartRef]].self, from: jsonData)
        return decoded.flatMap { key, value in
            return value.map { key, value in
                return value
            }
        }
    }()

    // Store object
    repo.perform {
        object.originalHtml = data

        object.objectIsCrawled = true

        if needsToBeSelected(object: object, filterMethod: plugin.filterMethod) {
            object.select(newObjects: relatedCrawlables)
        } else {
            object.unselect(newObjects: relatedCrawlables)
        }
    }
}
