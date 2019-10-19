//
//  MemoDataStoreTest.swift
//  RxSwift-Memo-SampleTests
//
//  Created by kawaharadai on 2019/10/19.
//  Copyright © 2019 kawaharadai. All rights reserved.
//

import XCTest
import CoreData
@testable import RxSwift_Memo_Sample

class MemoDataStoreTest: XCTestCase {

    let memoDataStore = MemoDataStoreImpl()
    var expectation = XCTestExpectation()

    override func setUp() {
        memoDataStore.deleteAll()
    }

    override func tearDown() {
        memoDataStore.deleteAll()
    }

    func test_createMemo_新規メモが作成できること() {
        let newMemo = memoDataStore.createMemo()
        XCTAssertNotNil(newMemo)
        XCTAssertNotNil(newMemo?.uniqueId)
    }

    func test_createMemo_uniqueIdがユニークになっていること() {
        var createMemos = [Memo]()
        (0..<100).forEach {_ in
            let newMemo = memoDataStore.createMemo()!
            memoDataStore.saveContext(newMemo.managedObjectContext!)
            XCTAssertFalse(createMemos.compactMap { $0.uniqueId }.contains(newMemo.uniqueId!), "同じIDのメモが配列内にないこと")
            createMemos.append(newMemo)
        }
    }

    func test_readAll_保存されているMemoが全て取得できること() {
        let memoCount = 200
        (0..<memoCount).forEach {_ in
            let newMemo = memoDataStore.createMemo()!
            memoDataStore.saveContext(newMemo.managedObjectContext!)
        }

        expectation = self.expectation(description: "作ったメモと取得したメモの数が同じこと")
        memoDataStore.readAll { (result) in
            switch result {
            case .success(let memos):
                XCTAssertEqual(memos.count, memoCount)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)
    }

    func test_readMemo_uniqueId指定でMemoが取得できること() {
        let dummyUniqueId = "2000"
        let newMemo = memoDataStore.createMemo()!
        newMemo.uniqueId = dummyUniqueId
        memoDataStore.saveContext(newMemo.managedObjectContext!)
        do {
            let readMemo = try memoDataStore.readMemo(uniqueId: dummyUniqueId)
            XCTAssertEqual(readMemo.uniqueId, dummyUniqueId)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_updateMemo_作成済みのメモの内容を更新できること() {
        let dummyUniqueId = "2000"
        let title1 = "タイトル1"
        let title2 = "タイトル2"
        let newMemo = memoDataStore.createMemo()!
        newMemo.uniqueId = dummyUniqueId
        newMemo.title = title1
        memoDataStore.saveContext(newMemo.managedObjectContext!)
        let readMemo = try! memoDataStore.readMemo(uniqueId: dummyUniqueId)
        readMemo.title = title2
        memoDataStore.updateMemo(memo: readMemo)
        let readMemoSecond = try! memoDataStore.readMemo(uniqueId: dummyUniqueId)
        XCTAssertEqual(readMemoSecond.title, title2)
    }

    func test_deleteMemo_uniqueId指定でMemoが削除できること() {
        let dummyUniqueId = "2000"
        let newMemo = memoDataStore.createMemo()!
        newMemo.uniqueId = dummyUniqueId
        memoDataStore.saveContext(newMemo.managedObjectContext!)
        memoDataStore.deleteMemo(uniqueId: dummyUniqueId)
        // 検索結果が0件の時はerrorを返すようになっている
        do {
            let _ = try memoDataStore.readMemo(uniqueId: dummyUniqueId)
            XCTFail("メモは削除されているので取得できないこと")
        } catch {
            guard let memoDataStoreError = error as? MemoDataStoreError else {
                XCTFail()
                return
            }
            XCTAssertTrue(memoDataStoreError == .empty, "0件エラーが返ること")
        }
    }
}
