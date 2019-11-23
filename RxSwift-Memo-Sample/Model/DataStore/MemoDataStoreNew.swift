//
//  MemoDataStoreNew.swift
//  RxSwift-Memo-Sample
//
//  Created by kawaharadai on 2019/11/24.
//  Copyright © 2019 kawaharadai. All rights reserved.
//

import CoreData
import RxSwift
import RxCocoa

protocol MemoDataStoreNew {
    func createMemo() -> Observable<Memo>
    func readAll() -> Observable<[Memo]>
    func readMemo(uniqueId: String) -> Observable<Memo>
    func updateMemo(memo: Memo)
    func deleteAll() -> Observable<Void>
    func deleteMemo(uniqueId: String) -> Observable<Void>
    func countAll() -> Observable<Int>
}

struct MemoDataStoreNewImpl: MemoDataStoreNew {
    func createMemo() -> Observable<Memo> {
        let context = CoreDataPropaties.shared.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "Memo", in: context)
        return countAll()
            .flatMap { (memosCount) -> Observable<Memo> in
                guard let entity = entity else {
                    return Observable.error(MemoDataStoreError.isNil)
                }
                let memo = Memo(entity: entity, insertInto: context)
                memo.uniqueId = "\(memosCount + 1)"
                return Observable.of(memo)
        }
    }

    func readAll() -> Observable<[Memo]> {
        return fetchMemo(predicates: [], sortKey: "editDate")
    }

    func readMemo(uniqueId: String) -> Observable<Memo> {
        return fetchMemo(predicates: [NSPredicate(format: "uniqueId == %@", uniqueId)], sortKey: "editDate")
            .ifEmpty(switchTo: Observable.error(MemoDataStoreError.empty))
            .flatMap { (memos) -> Observable<Memo> in
                return Observable.of(memos[0])
        }
    }

    private func fetchMemo(predicates: [NSPredicate], sortKey: String, ascending: Bool = false) -> Observable<[Memo]> {
        let context = CoreDataPropaties.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Memo> = Memo.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: sortKey, ascending: ascending)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

        let resultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                           managedObjectContext: context,
                                                           sectionNameKeyPath: nil,
                                                           cacheName: nil)

        return Observable.just(resultsController)
            .flatMap { (fetchResultController) -> Observable<[Memo]> in
                try fetchResultController.performFetch()
                if let memos = fetchResultController.fetchedObjects {
                    return Observable.of(memos)
                } else {
                    return Observable.error(MemoDataStoreError.isNil)
                }
        }
        .asObservable()
    }

    func updateMemo(memo: Memo) {
        guard let context = memo.managedObjectContext else { return }
        saveContext(context)
    }

    func deleteAll() -> Observable<Void> {
        let context = CoreDataPropaties.shared.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Memo")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        return Observable.just(deleteRequest)
            .flatMap { (request) -> Observable<Void> in
                let result = try context.execute(request)
                print("削除結果：\(result)")
                return Observable.of(())
        }
    }

    func deleteMemo(uniqueId: String) -> Observable<Void> {
        let context = CoreDataPropaties.shared.persistentContainer.viewContext
        return Observable.just(uniqueId)
            .flatMap { (id) -> Observable<Memo> in
                return self.readMemo(uniqueId: id)
        }
        .map { (memo) in
            context.delete(memo)
            return self.saveContext(context)
        }
        .asObservable()
    }

    func countAll() -> Observable<Int> {
        return fetchMemo(predicates: [], sortKey: "editDate").flatMap { (memos) -> Observable<Int> in
            return Observable.of(memos.count)
        }
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

