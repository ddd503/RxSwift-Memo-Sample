//
//  MemoDataStore.swift
//  RxSwift-Memo-Sample
//
//  Created by kawaharadai on 2019/10/18.
//  Copyright © 2019 kawaharadai. All rights reserved.
//

import CoreData

protocol MemoDataStore {
    func createMemo(title: String?, content: String?)
    func readAll(_ completion: (Result<[Memo], Error>) -> ())
    func readMemo(uniqueId: String, _ completion: (Result<Memo, Error>) -> ())
    func updateMemo(memo: Memo)
    func deleteAll()
    func deleteMemo(uniqueId: String)
    func countAll(_ completion: (Result<Int, Error>) -> ())
    func viewContext() -> NSManagedObjectContext
}

struct MemoDataStoreImpl: MemoDataStore {
    func createMemo(title: String?, content: String?) {

    }

    func readAll(_ completion: (Result<[Memo], Error>) -> ()) {

    }

    func readMemo(uniqueId: String, _ completion: (Result<Memo, Error>) -> ()) {

    }

    func updateMemo(memo: Memo) {}

    func deleteAll() {}

    func deleteMemo(uniqueId: String) {}

    func countAll(_ completion: (Result<Int, Error>) -> ()) {}

    func viewContext() -> NSManagedObjectContext {
        let container = NSPersistentContainer(name: "RxSwift_Memo_Sample")
               container.loadPersistentStores(completionHandler: { (storeDescription, error) in
                   if let error = error as NSError? {
                       fatalError("Unresolved error \(error), \(error.userInfo)")
                   }
               })
        return container.viewContext
    }

    private func saveContext (_ context: NSManagedObjectContext) {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
