//
//  DataLoader.swift
//  aTarantula
//
//  Created by Ilya Mikhaltsou on 9/9/17.
//  Copyright © 2017 morpheby. All rights reserved.
//

import Foundation

class DataLoader {

    init() {
        loadingState = .na
        migrationState = .na
    }

    lazy var dataLoadingObservable = Observable(self)
    var loadingState: LoadingState {
        didSet {
            dataLoadingObservable.fire()
        }
    }

    lazy var dataMigrationObservable = Observable(self)
    var migrationState: MigrationState {
        didSet {
            dataMigrationObservable.fire()
        }
    }

    var stores: [String: DataController] = [:]

    func loadStore(named name: String, managedObjectModel: NSManagedObjectModel,
                   success: ((_ dataController: DataController) -> ())? = nil) throws {
        try loadStore(named: name,
                             at: NSPersistentContainer.defaultDirectoryURL().appendingPathComponent(name).appendingPathExtension("sqlite"),
                             managedObjectModel: managedObjectModel, success: success)
    }

    func loadStore(named name: String, at storeURL: URL, managedObjectModel: NSManagedObjectModel,
                   success: ((_ dataController: DataController) -> ())? = nil) throws {
        defer {
            loadingState = .na
        }

        loadingState = .loadingStore(named: name)

        let persistentContainer = NSPersistentContainer(name: name, managedObjectModel: managedObjectModel)
        let description = persistentContainer.persistentStoreDescriptions[0]
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        description.setValue("NORMAL" as NSString, forPragmaNamed: "synchronous")

        persistentContainer.loadPersistentStores() { (description, error) in
            if let error = error {
                self.loadingState = .asyncError(error)
            } else {
                persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
                let controller = DataController(persistentContainer: persistentContainer)
                self.stores[name] = controller
                self.loadingState = .loadedStore(named: name)
                if let s = success {
                    s(controller)
                }
            }
            self.loadingState = .na
        }
    }

    let foreignOptions: [AnyHashable: Any] = [
        NSSQLitePragmasOption: [
            "journal_mode": "OFF",
            "synchronous": "NORMAL",
        ],
        NSSQLiteAnalyzeOption: true
    ]

    let nativeOptions: [AnyHashable: Any] = [
        NSSQLitePragmasOption: [
            "synchronous": "NORMAL",
        ],
    ]

    func migrateStore(_ persistentStore: NSPersistentStore, named name: String, to targetURL: URL,
                      targetOptions: [AnyHashable: Any], destroy: Bool) throws {
        defer {
            migrationState = .na
        }

        migrationState = .migratingStore(named: name, to: targetURL)

        guard let store = stores[name] else {
            throw ExportingError.noSuchStore
        }
        let coordinator = store.persistentContainer.persistentStoreCoordinator

        // Remove old store
        if destroy {
            try coordinator.destroyPersistentStore(at: targetURL, ofType: NSSQLiteStoreType, options: targetOptions)
        }

        let newStore = try coordinator.migratePersistentStore(persistentStore,
                                                              to: targetURL,
                                                              options: targetOptions,
                                                              withType: NSSQLiteStoreType)

        // Disconnect migrated persistent store
        migrationState = .disconnectingStore(named: name)
        try coordinator.remove(newStore)
    }

    func exportStore(named name: String, to targetURL: URL, success: (() -> ())? = nil) throws {
        defer {
            migrationState = .na
        }

        guard let store = stores[name] else {
            throw ExportingError.noSuchStore
        }

        let coordinator = store.persistentContainer.persistentStoreCoordinator

        guard let persistentStore = coordinator.persistentStores.first else {
            throw ExportingError.coordinatorNotInitialized
        }

        try migrateStore(persistentStore, named: name, to: targetURL, targetOptions: foreignOptions, destroy: true)

        migrationState = .reconnectingStore(named: name)
        coordinator.addPersistentStore(with: store.persistentContainer.persistentStoreDescriptions[0],
                                           completionHandler: { (description, error) in
            if let error = error {
                self.migrationState = .asyncError(error)
            } else {
                self.migrationState = .migratedStore(named: name)
                if let s = success {
                    s()
                }
            }
            self.migrationState = .na
        })
    }

    func importStore(named name: String, from targetURL: URL, destroy: Bool = false, success: (() -> ())? = nil) throws {
        defer {
            migrationState = .na
        }

        guard let store = stores[name] else {
            throw ExportingError.noSuchStore
        }

        let coordinator = store.persistentContainer.persistentStoreCoordinator

        guard let originalStore = coordinator.persistentStores.first else {
            throw ExportingError.coordinatorNotInitialized
        }

        // Disconnect original persistent store
        migrationState = .disconnectingStore(named: name)
        try coordinator.remove(originalStore)

        migrationState = .openingStore(named: name, url: targetURL)

        let importingStore = try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: targetURL, options: foreignOptions)

        try migrateStore(importingStore, named: name, to: store.persistentContainer.persistentStoreDescriptions[0].url!,
                         targetOptions: nativeOptions, destroy: destroy)

        migrationState = .reconnectingStore(named: name)
        coordinator.addPersistentStore(with: store.persistentContainer.persistentStoreDescriptions[0],
                                       completionHandler: { (description, error) in
                                        if let error = error {
                                            self.migrationState = .asyncError(error)
                                        } else {
                                            self.migrationState = .migratedStore(named: name)
                                            if let s = success {
                                                s()
                                            }
                                        }
                                        self.migrationState = .na
        })
    }

    enum LoadingState {
        case na
        case loadingStore(named: String)
        case loadedStore(named: String)
        case asyncError(Error)
    }

    enum MigrationState {
        case na
        case migratingStore(named: String, to: URL)
        case disconnectingStore(named: String)
        case reconnectingStore(named: String)
        case openingStore(named: String, url: URL)
        case migratedStore(named: String)
        case asyncError(Error)
    }

    enum ExportingError: Error {
        case noSuchStore
        case coordinatorNotInitialized
    }

}
