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

    func test_createMemo_新規メモが作成できること() {
        let memoDataStore = MemoDataStoreImpl()
        let dummyUniqueId1 = "1000"
        // 1件のメモを新規作成してからidでfetchする
        let blocking = memoDataStore.createMemo(text: "タイトル1\nコンテンツ1\nコンテンツ2", uniqueId: dummyUniqueId1)
            .flatMap { (_) -> Observable<Memo> in
                return memoDataStore.readMemo(uniqueId: dummyUniqueId1)
        }
        .toBlocking()

        guard let newMemo = try? blocking.first() else {
            XCTFail("Memoの生成に失敗")
            return
        }

        XCTAssertNotNil(newMemo.uniqueId)
        // 1行目がtitle、2行目以降がcontentであることも確認
        XCTAssertEqual(newMemo.title, "タイトル1")
        XCTAssertEqual(newMemo.content, "コンテンツ1\nコンテンツ2")
    }

    func test_createMemo_uniqueIdがユニークになっていること() {
        let memoDataStore = MemoDataStoreImpl()
        let createMemoCount = 100
        var createMemos = [Memo]()
        (0..<createMemoCount).forEach { i in
            let newMemo = try! memoDataStore.createMemo(text: "\(i)", uniqueId: "\(i)")
                .flatMap { (_) -> Observable<Memo> in
                    return memoDataStore.readMemo(uniqueId: "\(i)")
            }
            .toBlocking()
            .first()!

            // 1件ごとのSaveはCreateがやってくれている
            XCTAssertFalse(createMemos
                .compactMap { $0.uniqueId }
                .contains(newMemo.uniqueId!),
                           "同じIDのメモが配列内にないこと")
            createMemos.append(newMemo)
        }
    }

    func test_readAll_保存されているMemoが全て取得できること() {
        let memoDataStore = MemoDataStoreImpl()
        let createMemoCount = 200
        (0..<createMemoCount).forEach { i in
            try! memoDataStore.createMemo(text: "\(i)", uniqueId: "\(i)")
                .toBlocking()
                .first()!
        }
        let blocking = memoDataStore.readAll().toBlocking()
        guard let allMemo = try? blocking.first() else {
            XCTFail("Memo配列の取得に失敗")
            return
        }
        XCTAssertEqual(allMemo.count, createMemoCount)
    }

    func test_readMemo_uniqueId指定でMemoが取得できること() {
        let memoDataStore = MemoDataStoreImpl()
        let dummyUniqueId1 = "1000"
        let dummyUniqueId2 = "2000"
        let dummyUniqueId3 = "3000"
        try! memoDataStore.createMemo(text: "メモ1", uniqueId: dummyUniqueId1).toBlocking().first()!
        try! memoDataStore.createMemo(text: "メモ2", uniqueId: dummyUniqueId2).toBlocking().first()!
        try! memoDataStore.createMemo(text: "メモ3", uniqueId: dummyUniqueId3).toBlocking().first()!

        let blocking = memoDataStore.readMemo(uniqueId: dummyUniqueId2).toBlocking()
        guard let memo = try? blocking.first() else {
            XCTFail("ID指定でのメモ取得に失敗")
            return
        }
        XCTAssertEqual(memo.uniqueId, dummyUniqueId2)
        XCTAssertEqual(memo.title, "メモ2")
    }

    func test_updateMemo_作成済みのメモの内容を更新できること() {
        let memoDataStore = MemoDataStoreImpl()
        let dummyUniqueId = "100"
        try! memoDataStore.createMemo(text: "タイトル1\nコンテンツ1\nコンテンツ2",
                                      uniqueId: dummyUniqueId)
            .toBlocking()
            .first()!

        // 新規作成したメモを取得（更新作業を行う）
        let readMemo = try! memoDataStore.readMemo(uniqueId: dummyUniqueId).toBlocking().first()!
        XCTAssertEqual(readMemo.title, "タイトル1")
        XCTAssertEqual(readMemo.content, "コンテンツ1\nコンテンツ2")

        // メモを更新した上でreadして更新後の値を確認
        let updateMemo = try! memoDataStore.updateMemo(memo: readMemo, text: "タイトル3\nコンテンツ3")
            .flatMap { (_) -> Observable<Memo> in
                return memoDataStore.readMemo(uniqueId: dummyUniqueId)
        }
        .toBlocking()
        .first()!

        XCTAssertEqual(updateMemo.title, "タイトル3")
        XCTAssertEqual(updateMemo.content, "コンテンツ3")
    }

    func test_deleteAll_保存されているメモを全て削除できること() {
        let memoDataStore = MemoDataStoreImpl()
        let dummyUniqueId1 = "1000"
        let dummyUniqueId2 = "2000"
        let dummyUniqueId3 = "3000"
        try! memoDataStore.createMemo(text: "メモ1", uniqueId: dummyUniqueId1).toBlocking().first()!
        try! memoDataStore.createMemo(text: "メモ2", uniqueId: dummyUniqueId2).toBlocking().first()!
        try! memoDataStore.createMemo(text: "メモ3", uniqueId: dummyUniqueId3).toBlocking().first()!

        // 全件取得
        let allMemoBeforeDeleteAll = try! memoDataStore.readAll().toBlocking().first()!

        XCTAssertEqual(allMemoBeforeDeleteAll.count, 3)

        // 全て削除
        try! memoDataStore.deleteAll().toBlocking().first()!

        // 全件取得
        let allMemoAfterDeleteAll = try! memoDataStore.readAll().toBlocking().first()!

        XCTAssertTrue(allMemoAfterDeleteAll.isEmpty)
    }

    func test_deleteMemo_uniqueId指定でMemoが削除できること() {
        let memoDataStore = MemoDataStoreImpl()
        let dummyUniqueId1 = "1000"
        let dummyUniqueId2 = "2000"
        let dummyUniqueId3 = "3000"
        try! memoDataStore.createMemo(text: "メモ1", uniqueId: dummyUniqueId1).toBlocking().first()!
        try! memoDataStore.createMemo(text: "メモ2", uniqueId: dummyUniqueId2).toBlocking().first()!
        try! memoDataStore.createMemo(text: "メモ3", uniqueId: dummyUniqueId3).toBlocking().first()!

        // 全件取得
        let allMemoBeforeDelete = try! memoDataStore.readAll().toBlocking().first()!

        XCTAssertEqual(allMemoBeforeDelete.count, 3)

        // メモ2を削除
        try! memoDataStore.deleteMemo(uniqueId: dummyUniqueId2).toBlocking().first()!

        // 全件取得
        let allMemoAfterDelete = try! memoDataStore.readAll().toBlocking().first()!

        XCTAssertEqual(allMemoAfterDelete.count, 2)
        XCTAssertFalse(allMemoAfterDelete.contains(where: { $0.uniqueId == dummyUniqueId2 }),
                       "削除後の全件メモの中にメモ2のuniqueIDが含まれていないこと")
    }

    func test_countAll_メモ全件の総数を取得できること() {
        let memoDataStore = MemoDataStoreImpl()
        let memosCount = 200
        (0..<memosCount).forEach {
            try! memoDataStore.createMemo(text: "\($0)", uniqueId: "\($0)").toBlocking().first()!
        }

        let blocking1 = memoDataStore.countAll().toBlocking()
        guard let allMemoCountFirst = try? blocking1.first() else {
            XCTFail("メモ総数の取得に失敗")
            return
        }

        XCTAssertEqual(allMemoCountFirst, memosCount)

        let dummyUniqueId1 = "1000"
        let dummyUniqueId2 = "2000"
        try! memoDataStore.createMemo(text: "メモ1", uniqueId: dummyUniqueId1).toBlocking().first()!
        try! memoDataStore.createMemo(text: "メモ2", uniqueId: dummyUniqueId2).toBlocking().first()!

        let blocking2 = memoDataStore.countAll().toBlocking()
        guard let allMemoCountSecond = try? blocking2.first() else {
            XCTFail("メモ総数の取得に失敗")
            return
        }

        XCTAssertEqual(allMemoCountSecond, memosCount + 2)
    }

    private func deleteAllMemo() {
        let context = CoreDataPropaties.shared.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Memo")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        try! context.execute(deleteRequest)
    }
}
