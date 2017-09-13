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

    var newCrawlables: [CrawlableObject] = []

    guard let html = Kanna.HTML(html: data, encoding: .utf8) else {
        throw CrawlError(url: objectUrl, info: "Unable to parse HTML")
    }

    let name = html.xpath("//li[@class='toolbar-title']//span[@itemprop='name']").first?.text
//
//    let author: Profile? = {
//        if let urlString = html.xpath("//div[@id='profile_top']/a/@href").first?.text,
//            let url = URL(string: urlString, relativeTo: baseUrl) {
//            let a = repo.getAuthor(forUrl: url)
//            if !a.objectIsCrawled {
//                crawlables.append(a)
//            }
//            return a
//        } else {
//            return nil
//        }
//    }()
//
//    let rating = html.xpath("//div[@id='profile_top']/span/a[@target='rating']").first?.text
//
//    let metadata = Array(html.xpath("//div[@id='profile_top']/span/a[@target='rating']/..")).first?.text
//
//    let filterInt = { (s: String) -> String in
//        s.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: "")
//    }
//
//    let language: String?
//    let genre: String?
//    let characters: [String]?
//    let chapters: Int?
//    let words: Int?
//    let favs: Int?
//    let follows: Int?
//
//    if let ms = metadata?.components(separatedBy: " - ") {
//        language = ms[safe: 1]
//        genre = ms[safe: 2]
//        characters = ms[safe: 3]?.components(separatedBy: ", ")
//        if let s = ms[safe: 4]?.components(separatedBy: ":")[safe: 1] {
//            chapters = Int(filterInt(s))
//        } else {
//            chapters = nil
//        }
//        if let s = ms[safe: 5]?.components(separatedBy: ":")[safe: 1] {
//            words = Int(filterInt(s))
//        } else {
//            words = nil
//        }
//        if let s = ms[safe: 7]?.components(separatedBy: ":")[safe: 1] {
//            favs = Int(filterInt(s))
//        } else {
//            favs = nil
//        }
//        if let s = ms[safe: 8]?.components(separatedBy: ":")[safe: 1] {
//            follows = Int(filterInt(s))
//        } else {
//            follows = nil
//        }
//    } else {
//        (language, genre, characters, chapters, words, favs, follows) = (nil, nil, nil, nil, nil, nil, nil)
//    }
//
//    let reviews: ReviewPage? = {
//        if let urlString = Array(html.xpath("//div[@id='profile_top']/span/a/@href"))[safe: 1]?.text,
//            let url = URL(string: urlString, relativeTo: baseUrl) {
//            let a = repo.getReviewPage(forUrl: url)
//            if !a.objectIsCrawled {
//                crawlables.append(a)
//            }
//            return a
//        } else {
//            return nil
//        }
//    }()
//
//    let lastUpdate: Date?
//    let published: Date?
//
//    if let dtstring = Array(html.xpath("//div[@id='profile_top']/span/span/@data-xutime"))[safe: 0]?.text,
//        let time = TimeInterval(dtstring) {
//        lastUpdate = Date(timeIntervalSince1970: time)
//    } else {
//        lastUpdate = nil
//    }
//
//    if let dtstring = Array(html.xpath("//div[@id='profile_top']/span/span/@data-xutime"))[safe: 1]?.text,
//        let time = TimeInterval(dtstring) {
//        published = Date(timeIntervalSince1970: time)
//    } else {
//        published = nil
//    }

    repo.perform {
        object.name = name

        object.objectIsCrawled = true
    }
}

