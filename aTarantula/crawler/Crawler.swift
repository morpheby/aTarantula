//
//  Crawler.swift
//  CrossroadRegex
//
//  Created by Ilya Mikhaltsou on 6/16/17.
//
//

import Foundation
import TarantulaPluginCore

@objc class Crawler: NSObject {
    @objc dynamic var discoveredCount: Int = 0
    @objc dynamic var crawledCount: Int = 0
    @objc dynamic var filteredCount: Int = 0
    @objc dynamic var name: String?


    private var crawllist: SynchronizedBox<Deque<CrawlableObject>> = SynchronizedBox(Deque())

    func resolvePlugin(for object: CrawlableObject) -> TarantulaCrawlingPlugin {
        let appController = NSApplication.shared.controller
        let result = appController.pluginLoader.crawlers.filter { plugin in plugin.crawlableObjectTypes.contains { o in o == type(of: object as Any) } } .first
        assert(result != nil, "Object not present in plugins")
        return result!
    }

    func crawlerSingleTask() {
        guard let crawlingObject = (crawllist.modify { c in c.popFirst() }) else {
            return
        }

        let plugin = resolvePlugin(for: crawlingObject)

        try plugin.crawlObject(object: crawlingObject)


        switch (crawlingObject) {
//        case let s as Book:
//            // Books
//            if let result = try? crawlBook(book: s, repository: repo) {
//                if bookFilter(s) {
//                    synchronized(obj) { crawllist += result }
//                }
//            } else {
//                synchronized(obj) { failedlist.append(s) }
//            }
//        case let s as ReviewPage:
//            // Reviews
//            if let result = try? crawlReviews(reviewPage: s, repository: repo) {
//                if reviewFilter(s) {
//                    synchronized(obj) { crawllist += result }
//                }
//            } else {
//                synchronized(obj) { failedlist.append(s) }
//            }
//        case let s as Profile:
//            // Profiles
//            if let result = try? crawlProfile(profile: s, repository: repo) {
//                if authorFilter(s) {
//                    synchronized(obj) { crawllist += result }
//                }
//            } else {
//                synchronized(obj) { failedlist.append(s) }
//            }
        default:
            break
        }
//        synchronized(obj) {
//            processed += 1
//            continueFlag = statusCallback(crawllist.count, processed, failedlist.count)
//        }
    }
}

//
//func crawler(inRepository repo: Repository, withBaseUrl baseUrl: URL,
//             themesFilter: @escaping (Int) -> (Bool),
//             pageLimit: Int?,
//             bookFilter: @escaping (Book) -> (Bool),
//             authorFilter: @escaping (Profile) -> (Bool),
//             reviewFilter: @escaping (ReviewPage) -> (Bool),
//             statusCallback: @escaping (_ remaining: Int, _ done: Int, _ failed: Int) -> (Bool)) {
//    let listUrl = baseUrl.appendingPathComponent("book/")
//
//    guard let allThemes = try? crawlThemes(url: listUrl, repository: repo) else {
//        print("Error crawling themes")
//        return
//    }
//    let filterString = "?&srt=3&r=10"
//
//    let queue = OperationQueue()
//    queue.maxConcurrentOperationCount = 20
//
//    var crawllist: Deque<CrawlableObject> = Deque()
//    let obj = NSObject()
//
//    queue.addOperations((0..<allThemes.count).map { i in
//        BlockOperation(block: {
//            if synchronized(obj, do: { themesFilter(i) }),
//               let l = try? crawlBooklist(listUrl: URL(string: allThemes[i].absoluteString + filterString)!,
//                                          repository: repo, pageLimit: pageLimit) {
//                synchronized(obj) {
//                    crawllist += l as [CrawlableObject]
//                    statusCallback(allThemes.count - i, crawllist.count, 0)
//                }
//            }
//        })
//    }, waitUntilFinished: true)
//    
//    crawllist = Deque()
//    
//    print("Initializing reviews")
//    crawllist += Deque(Array(repo.allUncrawledReviewPages()) as [CrawlableObject])
//    
//    print("Initializing profiles")
//    crawllist += Deque(Array(repo.allUncrawledProfiles()) as [CrawlableObject])
//    
//    print("Initializing books")
//    crawllist += Deque(Array(repo.allUncrawledBooks()) as [CrawlableObject])
//    
//    var failedlist: [CrawlableObject] = []
//
//    var processed = 0
//
//    var continueFlag = true
//    while crawllist.count != 0 && continueFlag {
//        queue.addOperations((0..<min(100, crawllist.count)).map { i in
//            BlockOperation(block: {
//                switch synchronized(obj, do: { crawllist.popFirst()! }) {
//                case let s as Book:
//                    // Books
//                    if let result = try? crawlBook(book: s, repository: repo) {
//                        if bookFilter(s) {
//                            synchronized(obj) { crawllist += result }
//                        }
//                    } else {
//                        synchronized(obj) { failedlist.append(s) }
//                    }
//                case let s as ReviewPage:
//                    // Reviews
//                    if let result = try? crawlReviews(reviewPage: s, repository: repo) {
//                        if reviewFilter(s) {
//                            synchronized(obj) { crawllist += result }
//                        }
//                    } else {
//                        synchronized(obj) { failedlist.append(s) }
//                    }
//                case let s as Profile:
//                    // Profiles
//                    if let result = try? crawlProfile(profile: s, repository: repo) {
//                        if authorFilter(s) {
//                            synchronized(obj) { crawllist += result }
//                        }
//                    } else {
//                        synchronized(obj) { failedlist.append(s) }
//                    }
//                default:
//                    break
//                }
//                synchronized(obj) {
//                    processed += 1
//                    continueFlag = statusCallback(crawllist.count, processed, failedlist.count)
//                }
//            })
//        }, waitUntilFinished: true)
//    }
//}
