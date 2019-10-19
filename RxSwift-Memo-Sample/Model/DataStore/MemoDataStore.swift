//
//  MemoDataStore.swift
//  RxSwift-Memo-Sample
//
//  Created by kawaharadai on 2019/10/18.
//  Copyright © 2019 kawaharadai. All rights reserved.
//

import CoreData

protocol MemoDataStore {
    func createMemo() -> Memo?
    func readAll(_ completion: (Result<[Memo], Error>) -> ())
     func readMemo(uniqueId: String) throws -> Memo
    func updateMemo(memo: Memo)
    func deleteAll()
    func deleteMemo(uniqueId: String)
    func countAll() -> Int?
}

enum MemoDataStoreError: Error {
    case isNil
    case empty
}

struct MemoDataStoreImpl: MemoDataStore {
    func createMemo() -> Memo? {
        let context = CoreDataPropaties.shared.persistentContainer.viewContext
        guard let entity = NSEntityDescription.entity(forEntityName: "Memo", in: context), let allMemoCount = countAll() else { return nil }
        let memo = Memo(entity: entity, insertInto: context)
        memo.uniqueId = "\(allMemoCount + 1)"
        return memo
    }

    func readAll(_ completion: (Result<[Memo], Error>) -> ()) {
        fetchMemo(predicates: [], sortKey: "editDate", completion: completion)
    }

    func readMemo(uniqueId: String) throws -> Memo {
        let memos = try fetchMemo(predicates: [NSPredicate(format: "uniqueId == %@", uniqueId)], sortKey: "editDate")
        return memos[0]
    }

    /// クロージャで返す版
    private func fetchMemo(predicates: [NSPredicate], sortKey: String, ascending: Bool = false, completion: (Result<[Memo], Error>) -> ()) {
        let context = CoreDataPropaties.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Memo> = Memo.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: sortKey, ascending: ascending)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

        let resultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                           managedObjectContext: context,
                                                           sectionNameKeyPath: nil,
                                                           cacheName: nil)
        do {
            try resultsController.performFetch()
            guard let objects = resultsController.fetchedObjects, !objects.isEmpty else {
                completion(.failure(MemoDataStoreError.empty))
                return
            }
            completion(.success(objects))
        } catch let error as NSError {
            completion(.failure(error))
        }
    }

    /// エラーをthrowする版
    private func fetchMemo(predicates: [NSPredicate], sortKey: String, ascending: Bool = false, shouldErrorEmpty: Bool = true) throws -> [Memo] {
        let context = CoreDataPropaties.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Memo> = Memo.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: sortKey, ascending: ascending)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

        let resultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                           managedObjectContext: context,
                                                           sectionNameKeyPath: nil,
                                                           cacheName: nil)
        do {
            try resultsController.performFetch()
            if let objects = resultsController.fetchedObjects {
                // 0件をエラーとするかどうか
                if shouldErrorEmpty {
                    guard !objects.isEmpty else {
                        throw MemoDataStoreError.empty
                    }
                    return objects
                } else {
                    return objects
                }
            } else {
                throw MemoDataStoreError.isNil
            }
        } catch let error as NSError {
            throw error
        }
    }

    func updateMemo(memo: Memo) {
        guard let context = memo.managedObjectContext else { return }
        saveContext(context)
    }

    func deleteAll() {
        let context = CoreDataPropaties.shared.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Memo")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try context.execute(deleteRequest)
        } catch let error as NSError {
            print("error: \(error.localizedDescription)")
        }
    }

    func deleteMemo(uniqueId: String) {
        let context = CoreDataPropaties.shared.persistentContainer.viewContext
        guard let targetMemo = try? readMemo(uniqueId: uniqueId) else { return }
        context.delete(targetMemo)
        saveContext(context)
    }

    func countAll() -> Int? {
        guard let memos = try? fetchMemo(predicates: [], sortKey: "editDate", shouldErrorEmpty: false) else { return nil }
        return memos.count
    }

    func saveContext (_ context: NSManagedObjectContext) {
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
