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
    @objc dynamic var discoveredCount: Int = 100
    @objc dynamic var crawledCount: Int = 20
    @objc dynamic var crawledActiveCount: Int {
        return crawledCount + currentSessionCrawled
    }
    @objc dynamic var currentSessionCrawled: Int = 0
    @objc dynamic var filteredCount: Int = 20
    @objc dynamic var remainingCount: Int = 0
    @objc dynamic var name: String?
    @objc dynamic var maxCrawlingCount: Int = 100
    @objc dynamic var maxConcurrent: Int = 20
    @objc dynamic var updateFrequency: TimeInterval = 2.0
    @objc dynamic var running: Bool = false {
        didSet {
            if running && running != oldValue {
                startCrawling()
            }
        }
    }
    @objc dynamic var runningCrawlersCount: Int = 0
    @objc dynamic var log: [String] = []
    @objc dynamic var unfinished: Bool {
        return runningCrawlersCount != 0 || updateStatusRunning
    }
    @objc dynamic var updateStatusRunning: Bool = false

    @objc static func keyPathsForValuesAffectingCrawledActiveCount() -> Set<String> {
        return Set(["\(#keyPath(Crawler.currentSessionCrawled))", "\(#keyPath(Crawler.crawledCount))"])
    }

    @objc static func keyPathsForValuesAffectingUnfinished() -> Set<String> {
        return Set(["\(#keyPath(Crawler.runningCrawlersCount))", "\(#keyPath(Crawler.updateStatusRunning))"])
    }

    private var crawllist: SynchronizedBox<Deque<CrawlableObject>> = SynchronizedBox(Deque())
    private var crawllistNeedsUpdating: SynchronizedBox<Bool> = SynchronizedBox(true)

    override required init() {
        super.init()
        // Required to initialize statistics
        self.updateCrawllist()
    }

    func resolvePlugin(for object: CrawlableObject) -> TarantulaCrawlingPlugin {
        let appController = NSApplication.shared.controller
        let result = appController.pluginLoader.crawlers.filter { plugin in plugin.crawlableObjectTypes.contains { o in o == type(of: object as Any) } } .first
        assert(result != nil, "Object not present in plugins")
        return result!
    }

    func crawlerSingleTask() throws {
        guard let crawlingObject = (crawllist.modify { c in c.popFirst() }) else {
            return
        }

        let plugin = resolvePlugin(for: crawlingObject)

        // After we have plugin, we need to crawl the object. The filtering is responsibility
        // of the plugin: if it deems object is not to be crawled (after it, obviously, crawled it),
        // it needs to set object as being filtered and mark all created related objects
        // as filtered as well.
        //
        // It is also a responsibility of the crawler to remove `filtered` flag, if it encounters
        // a filtered object while crawling one that is not filtered, iff object hasn't been crawled yet.
        //
        // Essentially, the plugin may perform filtering at any time — and simply mark all filtered
        // crawled objects as such, and previously-filtered-now-unfiltered objects as unfiltered together
        // with all their direct yet uncrawled relashionships; but leaving uncrawled filtered objects
        // that it didn't encounter while checking for filtered objects untouched.
        //
        // Thus, we have 4 states:
        // - uncrawled, unfiltered — Objects that need crawling
        // - uncrawled, filtered — Objects, preserved, but that don't need to be crawled (yet)
        // - crawled, filtered — Objects that were discovered to be in contradiction with filter
        // - crawled, unfiltered — Complete objects
        //
        // So when we call plugin's `crawlObject`, plugin needs to do the following:
        // 1. Determine object type
        // 2. Crawl the object with all relationships
        // 3. Collect all new objects
        // 4. Run filter
        // 5. Set filter result on the object and all new objects
        // 6. Perform AND on each non-new related object for `filtered`
        //

        try plugin.crawlObject(object: crawlingObject)

        // Queue crawllist update
        crawllistNeedsUpdating.modify { x in x = true }
        NSApplication.shared.controller.mainQueue.addOperation {
            self.currentSessionCrawled += 1
        }
    }

    func updateCrawllist() {
        logDebug("attempting update lock")

        zipModify(&crawllist, &crawllistNeedsUpdating) { c, u in
            logDebug("update lock acquired")

            defer {
                u = false
            }

            let addCount = self.maxCrawlingCount - c.count
            guard addCount != 0 else {
                return
            }

            var collectedObjects: [CrawlableObject] = []

            let appController = NSApplication.shared.controller
            var crawledCount = 0
            var discoveredCount = 0
            var filteredCount = 0

            for plugin in appController.pluginLoader.crawlers {
                plugin.repository?.performAndWait {
                    for type in plugin.crawlableObjectTypes {
                        if let objectsTmp = plugin.repository?.readAllObjects(type, withSelection: .objectsToCrawl, max: addCount),
                        let objects = objectsTmp as? [CrawlableObject] {
                            collectedObjects.append(contentsOf: objects)
                        }
                        crawledCount += plugin.repository?.countAllObjects(type, withSelection: .crawledObjects) ?? 0
                        discoveredCount += plugin.repository?.countAllObjects(type, withSelection: .all) ?? 0
                        filteredCount += plugin.repository?.countAllObjects(type, withSelection: .filteredObjects) ?? 0
                    }
                }
            }

            c.append(contentsOf: collectedObjects)

            let requiresStop = (c.count == 0)

            logDebug("queued info update")

            NSApplication.shared.controller.mainQueue.addOperation {
                self.currentSessionCrawled = 0
                self.crawledCount = crawledCount
                self.discoveredCount = discoveredCount
                self.filteredCount = filteredCount
                if requiresStop {
                    self.running = false
                }
                logDebug("info updated")
            }
        }
    }

    func pushToLogAsync(_ text: String) {
        NSApplication.shared.controller.mainQueue.addOperation {
            self.log.append(text)
        }
    }

    func startCrawling() {
        guard running else {
            logDebug("Start requested, when running == false")
            return
        }
        let appController = NSApplication.shared.controller

        crawllistNeedsUpdating.modify { u in u = true }

        let crawlingQueue = OperationQueue()
        crawlingQueue.qualityOfService = .background
        crawlingQueue.maxConcurrentOperationCount = maxConcurrent

        var crawlingOperation: (() -> ())! = nil
        crawlingOperation = {
            appController.mainQueue.addOperation {
                self.runningCrawlersCount += 1
            }
            do {
                try self.crawlerSingleTask()
            }
            catch let error {
                self.pushToLogAsync("Error while crawling: \(error)")
            }

            appController.mainQueue.addOperation {
                self.runningCrawlersCount -= 1
                if self.running {
                    crawlingQueue.addOperation(crawlingOperation)
                }
            }
        }

        let updateQueue = appController.backgroundQueue()

        var updateOperation: (() -> ())! = nil
        updateOperation = {
            appController.mainQueue.addOperation {
                self.updateStatusRunning = true
            }
            if (self.crawllistNeedsUpdating.read { c in c }) {
                self.updateCrawllist()
            }
            appController.delay(self.updateFrequency) {
                appController.mainQueue.addOperation {
                    if self.running {
                        updateQueue.addOperation(updateOperation)
                    } else {
                        self.updateStatusRunning = false
                        logDebug("finished update queue")
                    }
                }
            }
        }

        // Populate queues
        for _ in 0..<maxConcurrent {
            crawlingQueue.addOperation(crawlingOperation)
        }
        updateQueue.addOperation(updateOperation)
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
