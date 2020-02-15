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
    /// 任意のEntityを新規作成する
    /// - Parameter entityName: 新規作成するEntity名
    /// - Returns: 作成したEntity
    func create<T: NSManagedObject>(entityName: String) -> Observable<T?>

    /// コンテキストを保存する
    /// - Parameter context: NSManagedObjectContext
    /// - Returns: 保存完了通知
    func save(context: NSManagedObjectContext) -> Observable<Notification>

    /// 条件に該当するオブジェクトの配列を取得する
    /// - Parameters:
    ///   - predicates: fetch条件
    ///   - sortKey: ソートキー
    ///   - ascending: 昇順 or 降順
    /// - Returns: fetchした配列
    func fetchArray<T: NSManagedObject>(predicates: [NSPredicate],
                                        sortKey: String,
                                        ascending: Bool) -> Observable<[T]>

    /// 任意のリクエスト(NSPersistentStoreRequest)を実行する
    /// - Parameter request: NSPersistentStoreRequest
    /// - Returns: 実行完了通知
    func excute<R: NSPersistentStoreRequest>(request: R) -> Observable<Notification>

    /// 任意のオブジェクトを削除する
    /// - Parameter object: 削除するオブジェクト
    /// - Returns: 削除完了通知
    func delete<T: NSManagedObject>(object: T) -> Observable<Notification>
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
                                        ascending: Bool) -> Observable<[T]> {
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

    func save(context: NSManagedObjectContext) -> Observable<Notification> {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                return Observable.error(error)
            }
        }
        return NotificationCenter.default.rx.notification(.NSManagedObjectContextDidSave)
    }

    func excute<R: NSPersistentStoreRequest>(request: R) -> Observable<Notification> {
        let context = CoreDataPropaties.shared.persistentContainer.viewContext
        do {
            try context.execute(request)
            return save(context: context)
        } catch {
            return Observable.error(error)
        }
    }

    func delete<T: NSManagedObject>(object: T) -> Observable<Notification> {
        let context = CoreDataPropaties.shared.persistentContainer.viewContext
        context.performAndWait {
            context.delete(object)
        }
        return save(context: context)
    }
}
