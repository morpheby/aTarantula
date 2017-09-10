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
    let persistentContainer: NSPersistentContainer
    let repository: Repository

    init(persistentContainer: NSPersistentContainer) {
        self.persistentContainer = persistentContainer
        self.repository = CoredataRepository(context: persistentContainer.newBackgroundContext())
    }
}
