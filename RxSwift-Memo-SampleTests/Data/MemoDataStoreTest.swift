//
//  MemoDataStoreTest.swift
//  RxSwift-Memo-SampleTests
//
//  Created by kawaharadai on 2019/10/19.
//  Copyright © 2019 kawaharadai. All rights reserved.
//

import XCTest
import CoreData
import RxSwift
import RxBlocking
@testable import RxSwift_Memo_Sample

class MemoDataStoreTest: XCTestCase {

    override func setUp() {
        deleteAllMemo()
    }

    override func tearDown() {
        deleteAllMemo()
    }

    func test_create_任意のEntityを新規作成できること() {
        let memoDataStore = MemoDataStoreImpl()
        let blocking = memoDataStore.create(entityName: "Memo").toBlocking()

        XCTAssertNoThrow(try blocking.first())

        guard let object = try? blocking.first(), let memo = object as? Memo else {
            XCTFail("作成したメモの取得に失敗")
            return
        }
        // 保存せずに消しておく
        memo.managedObjectContext?.delete(memo)
    }

    func test_fetchArray_条件を指定してEntityの配列を取得できること() {
        let memoDataStore = MemoDataStoreImpl()
        let entityName = "Memo"
        let memo1 = try! memoDataStore.create(entityName: entityName).toBlocking().first()! as! Memo
        memo1.title = "テスト1"
        memoDataStore.save(context: memo1.managedObjectContext!)
        let memo2 = try! memoDataStore.create(entityName: entityName).toBlocking().first()! as! Memo
        memo2.title = "テスト2"
        memoDataStore.save(context: memo2.managedObjectContext!)
        let memo3 = try! memoDataStore.create(entityName: entityName).toBlocking().first()! as! Memo
        memo3.title = "テスト3"
        memoDataStore.save(context: memo3.managedObjectContext!)

        let predicate1 = NSPredicate(format: "title == %@", "テスト2")
        let predicate2 = NSPredicate(format: "title == %@", "テスト3")

        let blocking: BlockingObservable<[Memo]> = memoDataStore.fetchArray(predicates: [predicate1, predicate2],
                                                                            sortKey: "editDate",
                                                                            ascending: false,
                                                                            logicalType: .or).toBlocking()
        guard let fetchMemos = try? blocking.first() else {
            XCTFail("Memo配列の取得に失敗")
            return
        }
        XCTAssertEqual(fetchMemos.count, 2)
    }

    func test_excute_リクエストが実行されていること() {
        let memoDataStore = MemoDataStoreImpl()
        let entityName = "Memo"
        let allMemosCount = 100

        (0..<allMemosCount).forEach {
            let memo = try! memoDataStore.create(entityName: entityName).toBlocking().first()! as! Memo
            memo.uniqueId = "\($0)"
            memoDataStore.save(context: memo.managedObjectContext!)
        }

        let allMemosBeforeRequest: [Memo] = try! memoDataStore.fetchArray(predicates: [],
                                                                          sortKey: "editDate",
                                                                          ascending: false,
                                                                          logicalType: .and) // predicateがない場合はandにしないと全件取れない
            .toBlocking()
            .first()!
        XCTAssertEqual(allMemosBeforeRequest.count, allMemosCount, "削除実行前はallMemosCount分の要素があるはず")

        // 削除リクエストの実行
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        try! memoDataStore.excute(request: deleteRequest).toBlocking().first()!

        // 削除後に再びfetchして全て消えているかを確認
        let allMemosAfterRequest: [Memo] = try! memoDataStore.fetchArray(predicates: [],
                                                                         sortKey: "editDate",
                                                                         ascending: false,
                                                                         logicalType: .and)
            .toBlocking()
            .first()!
        XCTAssertEqual(allMemosAfterRequest.count, 0)
    }

    func test_delete_指定した1件のEntityを削除できること() {
        let memoDataStore = MemoDataStoreImpl()
        let entityName = "Memo"
        let memo1 = try! memoDataStore.create(entityName: entityName).toBlocking().first()! as! Memo
        memo1.uniqueId = "1"
        memoDataStore.save(context: memo1.managedObjectContext!)
        let memo2 = try! memoDataStore.create(entityName: entityName).toBlocking().first()! as! Memo
        memo2.uniqueId = "2"
        memoDataStore.save(context: memo2.managedObjectContext!)
        let memo3 = try! memoDataStore.create(entityName: entityName).toBlocking().first()! as! Memo
        memo3.uniqueId = "3"
        memoDataStore.save(context: memo3.managedObjectContext!)

        let allMemosBeforeDelete: [Memo] = try! memoDataStore.fetchArray(predicates: [],
                                                                         sortKey: "editDate",
                                                                         ascending: false,
                                                                         logicalType: .and) // predicateがない場合はandにしないと全件取れない
            .toBlocking()
            .first()!
        XCTAssertEqual(allMemosBeforeDelete.count, 3, "削除実行前は3つの要素があるはず")

        // memo2を削除
        try! memoDataStore.delete(object: memo2).toBlocking().first()!

        let allMemosAfterDelete: [Memo] = try! memoDataStore.fetchArray(predicates: [],
                                                                         sortKey: "editDate",
                                                                         ascending: false,
                                                                         logicalType: .and) // predicateがない場合はandにしないと全件取れない
            .toBlocking()
            .first()!
        XCTAssertEqual(allMemosAfterDelete.count, 2, "削除実行後は要素数は2つのはず")
        XCTAssertFalse(allMemosAfterDelete.contains(where: { $0.uniqueId == "2" }), "idが2のメモが含まれていないこと")
    }

    private func deleteAllMemo() {
        let context = CoreDataPropaties.shared.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Memo")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        try! context.execute(deleteRequest)
    }
}
