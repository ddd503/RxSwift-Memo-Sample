//
//  CoreDataPropaties.swift
//  RxSwift-Memo-Sample
//
//  Created by kawaharadai on 2019/10/19.
//  Copyright © 2019 kawaharadai. All rights reserved.
//

import CoreData

final class CoreDataPropaties {

    private init() {}

    static let shared = CoreDataPropaties()

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "RxSwift_Memo_Sample")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
}
