//
//  MemoDataStoreMock.swift
//  RxSwift-Memo-SampleTests
//
//  Created by kawaharadai on 2020/02/16.
//  Copyright © 2020 kawaharadai. All rights reserved.
//

import CoreData
import RxSwift
@testable import RxSwift_Memo_Sample

class MemoDataStoreMock: MemoDataStore {

    var dummyDataBase: [Memo] = []
    func create<T: NSManagedObject>(entityName: String) -> Observable<T?> {
        let memoMock = MemoMock()
        return Observable.just(memoMock as? T)
    }

    func save(context: NSManagedObjectContext) -> Result<Void, Error> {
        return .success(())
    }

    func fetchArray<T: NSManagedObject>(predicates: [NSPredicate], sortKey: String, ascending: Bool, logicalType: NSCompoundPredicate.LogicalType) -> Observable<[T]> {
        let predicate = NSCompoundPredicate(type: logicalType, subpredicates: predicates)
        let fetchResult = (dummyDataBase as NSArray).filtered(using: predicate) as! [T]
        return Observable.just(fetchResult)
    }

    func excute<R: NSPersistentStoreRequest>(request: R) -> Observable<Void> {
        if let deleteRequest = request as? NSBatchDeleteRequest,
            let entityName = deleteRequest.fetchRequest.entityName,
            entityName == "Memo" {
            // Memo全削除時
            dummyDataBase = []
        }
        return Observable.just(())
    }

    func delete<T: NSManagedObject>(object: T) -> Observable<Void> {
        let memo = object as! Memo
        dummyDataBase = dummyDataBase.filter { $0.uniqueId != memo.uniqueId }
        return Observable.just(())
    }
}
