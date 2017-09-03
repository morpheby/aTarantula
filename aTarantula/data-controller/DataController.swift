//
//  DataController.swift
//  aTarantula
//
//  Created by Ilya Mikhaltsou on 9/2/17.
//  Copyright © 2017 morpheby. All rights reserved.
//

import Foundation
import TarantulaPluginCore

class DataController {
    lazy var managedObjectModel: NSManagedObjectModel = {
        assert(finishedInitialization, "Invalid access. Please, set up initialization threads accordingly")
        return self._managedObjectModel
    }()
    lazy var persistentContainer: NSPersistentContainer = {
        assert(finishedInitialization, "Invalid access. Please, set up initialization threads accordingly")
        return self._persistentContainer
    }()
    var finishedInitialization: Bool = false

    private let _managedObjectModel: NSManagedObjectModel
    private let _persistentContainer: NSPersistentContainer

    init(modelName: String, managedObjectModel: NSManagedObjectModel) throws {
        self._managedObjectModel = managedObjectModel

        let persistentContainer = NSPersistentContainer(name: modelName, managedObjectModel: managedObjectModel)

        self._persistentContainer = persistentContainer
        
        persistentContainer.persistentStoreDescriptions[0].shouldMigrateStoreAutomatically = true
        persistentContainer.loadPersistentStores() { (description, error) in
            if let error = error {
                NSApplication.shared.presentError(error)
                fatalError("Failed to load Core Data stack: \(error)")
            } else {
                self.finishedInitialization = true
            }
        }
    }
}
