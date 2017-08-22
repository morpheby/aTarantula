//
//  ViewController.swift
//  aTarantula
//
//  Created by Ilya Mikhaltsou on 8/18/17.
//  Copyright © 2017 morpheby. All rights reserved.
//

import Cocoa
import TarantulaPluginCore

class ViewController: NSViewController {

    dynamic var crawler: Crawler?
    @IBOutlet var objectController: NSObjectController!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func loadPlugin(_ sender: Any?) {
        self.crawler = Crawler()
        let pluginsPath = Bundle.main.builtInPlugInsPath!
//        let pluginsUrl = URL(string: pluginsPath)!
        let plugins = try? FileManager.default.contentsOfDirectory(atPath: pluginsPath)
        // XXX search other paths
        let bundle = Bundle(path: pluginsPath + "/" + plugins!.first!)
        guard let principal = bundle?.principalClass else {
            debugPrint("Unable to load \(plugins!)")
            abort()
        }
        guard let pobjclass = principal as? NSObject.Type else {
            debugPrint("Unable to load \(principal)")
            abort()
        }
        let object = pobjclass.init()
        guard let tarantulaPlugin = object as? TarantulaCrawlingPlugin else {
            debugPrint("Unable to load \(object) as CrawlingPluginProtocol")
            abort()
        }


        let persistentContainer = NSPersistentContainer(name: "Model", managedObjectModel: tarantulaPlugin.managedObjectModel)
        persistentContainer.persistentStoreDescriptions[0].shouldMigrateStoreAutomatically = true
        persistentContainer.loadPersistentStores() { (description, error) in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
            if let s = description.url?.absoluteString {
                print(s)
            }
            let context = persistentContainer.newBackgroundContext()
            let repository = CoredataRepository(context: context)
            repository.performAndWait {
//                let obj = repository.newObject(forUrl: URL(string: "http://test.com")!, type: tarantulaPlugin.crawlableObjectTypes[0] as! NSManagedObject.Type)
                let obj = repository.readAllObjects(tarantulaPlugin.crawlableObjectTypes[0] as! NSManagedObject.Type, withPredicate: .All)
                debugPrint(obj)
            }
        }
//        tarantulaPlugin.crawlableTypes
//        self.crawler?.name = tarantulaPlugin.testMe()
    }

    @IBAction func start(_ sender: Any?) {
        self.crawler?.name = "Other"
    }

}

