//
//  MemoDataStore.swift
//  RxSwift-Memo-Sample
//
//  Created by kawaharadai on 2019/10/18.
//  Copyright © 2019 kawaharadai. All rights reserved.
//

import CoreData
import RxSwift
import RxCocoa

protocol MemoDataStore {
    /// 新規メモを作成する
    /// - Parameters:
    ///   - text: メモ内容
    ///   - uniqueId: 新規メモに割り当てるユニークID（nilの場合は全件+1がID）
    func createMemo(text: String, uniqueId: String?) -> Observable<Void>

    /// 全メモを取得する
    func readAll() -> Observable<[Memo]>

    /// ID指定でメモを1件取得する
    /// - Parameter uniqueId: ユニークID
    func readMemo(uniqueId: String) -> Observable<Memo?>

    /// メモを更新する
    /// - Parameters:
    ///   - memo: 更新するメモ
    ///   - text: 更新内容
    func updateMemo(memo: Memo, text: String) -> Observable<Void>

    /// 全メモを削除する
    func deleteAll() -> Observable<Void>

    /// ID指定でメモを削除する
    /// - Parameter uniqueId: ユニークID
    func deleteMemo(uniqueId: String) -> Observable<Void>
    
    /// 全メモ件数を取得する
    func countAll() -> Observable<Int>


    func create<T: NSManagedObject>(entityName: String) -> Observable<T?>
    func saveContext (_ context: NSManagedObjectContext)
    func fetchArray<T: NSManagedObject>(predicates: [NSPredicate],
                                        sortKey: String,
                                        ascending: Bool) -> Observable<[T]>
}

enum MemoDataStoreError: Error {
    case notFoundFetchedMemos
    case empty
}

struct MemoDataStoreImpl: MemoDataStore {
    func create<T: NSManagedObject>(entityName: String) -> Observable<T?> {
        let context = CoreDataPropaties.shared.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: entityName, in: context)
        guard let memoEntity = entity else { return Observable.just(nil) }
        let object = NSManagedObject(entity: memoEntity, insertInto: context) as? T
        return Observable.just(object)
    }

    func fetchArray<T: NSManagedObject>(predicates: [NSPredicate],
                                        sortKey: String,
                                        ascending: Bool = false) -> Observable<[T]> {
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
            .flatMap { (fetchResultController) -> Observable<[T]> in
                try fetchResultController.performFetch()
                let objects = (fetchResultController.fetchedObjects as? [T]) ?? []
                return Observable.just(objects)
        }
    }





    func createMemo(text: String, uniqueId: String?) -> Observable<Void> {
        let context = CoreDataPropaties.shared.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "Memo", in: context)
        return countAll()
            .map { (memosCount) in
                guard let entity = entity else { return }
                let memo = Memo(entity: entity, insertInto: context)
                context.performAndWait {
                    memo.uniqueId = uniqueId ?? "\(memosCount + 1)"
                    memo.title = text.firstLine
                    memo.content = text.afterSecondLine
                    memo.editDate = Date()
                    self.saveContext(context)
                }
        }
    }

    func readAll() -> Observable<[Memo]> {
        let allMemos: Observable<[Memo]> = fetchArray(predicates: [], sortKey: "editDate")
        return allMemos
    }

    func readMemo(uniqueId: String) -> Observable<Memo?> {
        let fetchMemos: Observable<[Memo]> = fetchArray(predicates: [NSPredicate(format: "uniqueId == %@", uniqueId)], sortKey: "editDate")
        return fetchMemos.map { $0.first }
    }

    func updateMemo(memo: Memo, text: String) -> Observable<Void> {
        guard let context = memo.managedObjectContext else { return Observable.never() }
        return Observable.just(memo)
            .map { (memo) in
                context.performAndWait {
                    memo.title = text.firstLine
                    memo.content = text.afterSecondLine
                    memo.editDate = Date()
                    self.saveContext(context)
                }
        }
    }

    func deleteAll() -> Observable<Void> {
        let context = CoreDataPropaties.shared.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Memo")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        return Observable.just(deleteRequest)
            .flatMap { (request) -> Observable<()> in
                try context.execute(request)
                return Observable.just(())
        }
    }

    func deleteMemo(uniqueId: String) -> Observable<Void> {
        let context = CoreDataPropaties.shared.persistentContainer.viewContext
        return readMemo(uniqueId: uniqueId)
            .map { (memo) in
                context.performAndWait {
                    context.delete(memo)
                    self.saveContext(context)
                }
        }
    }

    func countAll() -> Observable<Int> {
        return fetchMemo(predicates: [], sortKey: "editDate").map { $0.count }
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
