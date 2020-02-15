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

    var fetchResultArray: [Memo] = []

    func create<T: NSManagedObject>(entityName: String) -> Observable<T?> {
        let memoMock = MemoMock() as? T
        return Observable.just(memoMock)
    }

    func save(context: NSManagedObjectContext) -> Observable<Void> {
        return Observable.just(())
    }

    func fetchArray<T: NSManagedObject>(predicates: [NSPredicate], sortKey: String, ascending: Bool, logicalType: NSCompoundPredicate.LogicalType) -> Observable<[T]> {
        return Observable.just(fetchResultArray as! [T])
    }

    func excute<R: NSPersistentStoreRequest>(request: R) -> Observable<Void> {
        return Observable.just(())
    }

    func delete<T: NSManagedObject>(object: T) -> Observable<Void> {
        let memo = object as! Memo
        fetchResultArray = fetchResultArray.filter { $0.uniqueId != memo.uniqueId }
        return Observable.just(())
    }
}
