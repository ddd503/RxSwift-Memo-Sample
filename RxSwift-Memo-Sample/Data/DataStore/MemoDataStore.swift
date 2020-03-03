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
    @discardableResult
    func save(context: NSManagedObjectContext) -> Observable<Void>

    /// 条件に該当するオブジェクトの配列を取得する
    /// - Parameters:
    ///   - predicates: fetch条件
    ///   - sortKey: ソートキー
    ///   - ascending: 昇順 or 降順
    ///   - logicalType: 複数条件指定時のフィルター方法
    /// - Returns: fetchした配列
    func fetchArray<T: NSManagedObject>(predicates: [NSPredicate],
                                        sortKey: String,
                                        ascending: Bool,
                                        logicalType: NSCompoundPredicate.LogicalType) -> Observable<[T]>

    /// 任意のリクエスト(NSPersistentStoreRequest)を実行する
    /// - Parameter request: NSPersistentStoreRequest
    func execute<R: NSPersistentStoreRequest>(request: R) -> Observable<Void>

    /// 任意のオブジェクトを削除する
    /// - Parameter object: 削除するオブジェクト
    func delete<T: NSManagedObject>(object: T) -> Observable<Void>
}

struct MemoDataStoreImpl: MemoDataStore {

    func create<T: NSManagedObject>(entityName: String) -> Observable<T?> {
        let context = CoreDataPropaties.shared.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: entityName, in: context)
        guard let memoEntity = entity else { return Observable.error(CoreDataError.failedCreateEntity) }
        let object = NSManagedObject(entity: memoEntity, insertInto: context) as? T
        return Observable.just(object)
    }

    @discardableResult
    func save(context: NSManagedObjectContext) -> Observable<Void> {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                return Observable.error(error)
            }
        }
        return Observable.just(())
    }

    func fetchArray<T: NSManagedObject>(predicates: [NSPredicate],
                                        sortKey: String,
                                        ascending: Bool,
                                        logicalType: NSCompoundPredicate.LogicalType) -> Observable<[T]> {
        let context = CoreDataPropaties.shared.persistentContainer.viewContext
        guard let fetchRequest: NSFetchRequest<T> = T.fetchRequest() as? NSFetchRequest<T> else {
            return Observable.error(CoreDataError.failedPrepareRequest)
        }
        let sortDescriptor = NSSortDescriptor(key: sortKey, ascending: ascending)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.predicate = NSCompoundPredicate(type: logicalType, subpredicates: predicates)

        let resultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                           managedObjectContext: context,
                                                           sectionNameKeyPath: nil,
                                                           cacheName: nil)

        return Observable.just(resultsController)
            .flatMap { (fetchResultController) -> Observable<[T]> in
                do {
                    try fetchResultController.performFetch()
                    let objects = fetchResultController.fetchedObjects ?? []
                    return Observable.just(objects)
                } catch {
                    return Observable.error(CoreDataError.failedFetchRequest)
                }
        }
    }

    func execute<R: NSPersistentStoreRequest>(request: R) -> Observable<Void> {
        let context = CoreDataPropaties.shared.persistentContainer.viewContext
        do {
            try context.execute(request)
            return Observable.just(())
        } catch {
            return Observable.error(error)
        }
    }

    func delete<T: NSManagedObject>(object: T) -> Observable<Void> {
        let context = CoreDataPropaties.shared.persistentContainer.viewContext
        context.performAndWait {
            context.delete(object)
        }
        return Observable.just(())
    }
}
