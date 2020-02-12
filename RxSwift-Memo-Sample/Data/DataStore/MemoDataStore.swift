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
    /// - Parameter text: メモ内容
    func createMemo(text: String) -> Observable<Memo>
    /// 全メモを取得する
    func readAll() -> Observable<[Memo]>
    /// ID指定でメモを1件取得する
    /// - Parameter uniqueId: ユニークID
    func readMemo(uniqueId: String) -> Observable<Memo>
    /// メモを更新する
    /// - Parameters:
    ///   - memo: 更新するメモ
    ///   - text: 更新内容
    func updateMemo(memo: Memo, text: String) -> Observable<Memo>
    /// 全メモを削除する
    func deleteAll() -> Observable<Void>
    /// ID指定でメモを削除する
    /// - Parameter uniqueId: ユニークID
    func deleteMemo(uniqueId: String) -> Observable<Void>
    /// 全メモ件数を取得する
    func countAll() -> Observable<Int>
}

enum MemoDataStoreError: Error {
    case notFoundFetchedMemos
    case notFoundEntity
    case empty
}

struct MemoDataStoreImpl: MemoDataStore {
    func createMemo(text: String) -> Observable<Memo> {
        let context = CoreDataPropaties.shared.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "Memo", in: context)
        return countAll()
            .flatMap { (memosCount) -> Observable<Memo> in
                guard let entity = entity else {
                    return Observable.error(MemoDataStoreError.notFoundEntity)
                }
                let memo = Memo(entity: entity, insertInto: context)
                context.performAndWait {
                    memo.uniqueId = "\(memosCount + 1)"
                    memo.title = text.firstLine
                    memo.content = text.afterSecondLine
                    memo.editDate = Date()
                    self.saveContext(context)
                }
                return Observable.just(memo)
        }
    }

    func readAll() -> Observable<[Memo]> {
        return fetchMemo(predicates: [], sortKey: "editDate")
    }

    func readMemo(uniqueId: String) -> Observable<Memo> {
        return fetchMemo(predicates: [NSPredicate(format: "uniqueId == %@", uniqueId)], sortKey: "editDate")
            .ifEmpty(switchTo: Observable.error(MemoDataStoreError.empty))
            .flatMap { (memos) -> Observable<Memo> in
                return Observable.just(memos[0])
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
                    return Observable.error(MemoDataStoreError.notFoundFetchedMemos)
                }
        }
        .asObservable()
    }

    func updateMemo(memo: Memo, text: String) -> Observable<Memo> {
        guard let context = memo.managedObjectContext else { return Observable.never() }
        context.performAndWait {
            memo.title = text.firstLine
            memo.content = text.afterSecondLine
            memo.editDate = Date()
            self.saveContext(context)
        }
        return Observable.just(memo)
    }

    func deleteAll() -> Observable<Void> {
        let context = CoreDataPropaties.shared.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Memo")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        return Observable.just(deleteRequest)
            .flatMap { (request) -> Observable<Void> in
                let result = try context.execute(request)
                print("削除結果：\(result)")
                return Observable.just(())
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
            return Observable.just(memos.count)
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
