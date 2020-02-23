//
//  MemoRepositoryTest.swift
//  RxSwift-Memo-SampleTests
//
//  Created by kawaharadai on 2020/02/15.
//  Copyright © 2020 kawaharadai. All rights reserved.
//

import XCTest
@testable import RxSwift_Memo_Sample

class MemoRepositoryTest: XCTestCase {

    func test_createMemo_1件のメモを新規作成できること() {
        let memoRepository = MemoRepositoryImpl(memoDataStore: MemoDataStoreMock())
        let blocking = memoRepository.createMemo(text: "テストタイトル\nテストコンテンツ1\nテストコンテンツ2", uniqueId: nil).toBlocking()
        guard let memo = try? blocking.first() else {
            XCTFail("Memoの新規作成に失敗")
            return
        }
        XCTAssertEqual(memo.uniqueId, "1")
        XCTAssertEqual(memo.title, "テストタイトル")
        XCTAssertEqual(memo.content, "テストコンテンツ1\nテストコンテンツ2")
    }

    func test_readAllMemos_保存中のメモを全件取得できること() {
        let memoDataStore = MemoDataStoreMock()
        let memoRepository = MemoRepositoryImpl(memoDataStore: memoDataStore)
        let allMemosCount = 100

        (0..<allMemosCount).forEach {
            let memo = try! memoRepository.createMemo(text: "\($0)\n\($0)", uniqueId: "\($0)").toBlocking().first()!
            memoDataStore.dummyDataBase.append(memo)
        }

        let blocking = memoRepository.readAllMemos().toBlocking()
        guard let allMemos = try? blocking.first() else {
            XCTFail("全件取得に失敗")
            return
        }

        XCTAssertEqual(allMemos.count, allMemosCount)

        // 重複削除
        let allMemosNotDeplication =
            allMemos.reduce([Memo]()) { (memos, memo) -> [Memo] in
                var mutableMemos = memos
                guard let uniqueId = memo.uniqueId else { return memos }
                let isNotContains = !memos.compactMap { $0.uniqueId }.contains(uniqueId)
                guard isNotContains else { return memos }
                mutableMemos.append(memo)
                return mutableMemos
        }
        XCTAssertEqual(allMemosNotDeplication.count, allMemosCount)
    }

    func test_readMemo_ID指定で特定のメモを1件取得できること() {
        let memoDataStore = MemoDataStoreMock()
        let memoRepository = MemoRepositoryImpl(memoDataStore: memoDataStore)
        let dummyUniqueId1 = "1"
        let dummyUniqueId2 = "2"
        let dummyTitle1 = "title1"
        let dummyTitle2 = "title2"
        let dummyContent1 = "content1"
        let dummyContent2 = "content2"
        
        let memo1 = try! memoRepository.createMemo(text: "\(dummyTitle1)\n\(dummyContent1)", uniqueId: dummyUniqueId1).toBlocking().first()!
        let memo2 = try! memoRepository.createMemo(text: "\(dummyTitle2)\n\(dummyContent2)", uniqueId: dummyUniqueId2).toBlocking().first()!
        memoDataStore.dummyDataBase.append(contentsOf: [memo1, memo2])

        let blocking = memoRepository.readMemo(uniqueId: dummyUniqueId1).toBlocking()
        guard let result = try? blocking.first(), let readMemo = result else {
            XCTFail("ID指定でのメモ取得に失敗")
            return
        }
        XCTAssertEqual(readMemo.uniqueId, dummyUniqueId1)
        XCTAssertEqual(readMemo.title, dummyTitle1)
        XCTAssertEqual(readMemo.content, dummyContent1)
    }

    func test_updateMemo_メモ内容を更新できること() {
        let memoDataStore = MemoDataStoreMock()
        let memoRepository = MemoRepositoryImpl(memoDataStore: memoDataStore)
        let dummyUniqueId = "1"
        let dummyTitle = "title"
        let dummyContent = ""
        let dummyTextAfterChange = "new title\nnew content"

        let memo = try! memoRepository
            .createMemo(text: "\(dummyTitle)\n\(dummyContent)", uniqueId: dummyUniqueId)
            .toBlocking()
            .first()!
        // 保存
        memoDataStore.dummyDataBase.append(memo)

        let blocking = memoRepository.updateMemo(memo: memo, text: dummyTextAfterChange).toBlocking()

        XCTAssertNoThrow(try blocking.first())

        let didUpdateMemo = try! memoRepository.readMemo(uniqueId: dummyUniqueId).toBlocking().first()!!
        XCTAssertEqual(didUpdateMemo.uniqueId, dummyUniqueId)
        XCTAssertEqual(didUpdateMemo.title, "new title")
        XCTAssertEqual(didUpdateMemo.content, "new content")
    }

    func test_deleteAll_保存されているメモを全て削除できること() {
        let memoDataStore = MemoDataStoreMock()
        let memoRepository = MemoRepositoryImpl(memoDataStore: memoDataStore)
        let allMemosCount = 10

        (0..<allMemosCount).forEach {
            let memo = try! memoRepository.createMemo(text: "\($0)\n\($0)", uniqueId: "\($0)").toBlocking().first()!
            memoDataStore.dummyDataBase.append(memo)
        }

        let allMemosBeforeDeleteAll = try! memoRepository.readAllMemos().toBlocking().first()!
        XCTAssertEqual(allMemosBeforeDeleteAll.count, allMemosCount)

        let blocking = memoRepository.deleteAll(entityName: "Memo").toBlocking()
        XCTAssertNoThrow(try blocking.first())

        let allMemosAfterDeleteAll = try! memoRepository.readAllMemos().toBlocking().first()!
        XCTAssertEqual(allMemosAfterDeleteAll.count, 0)
    }

    func test_deleteMemo_ID指定で1件のメモを削除できること() {
        let memoDataStore = MemoDataStoreMock()
        let memoRepository = MemoRepositoryImpl(memoDataStore: memoDataStore)
        let dummyUniqueId1 = "1"
        let dummyUniqueId2 = "2"
        let dummyUniqueId3 = "3"
        let dummyTitle1 = "title1"
        let dummyTitle2 = "title2"
        let dummyTitle3 = "title3"
        let dummyContent1 = "content1"
        let dummyContent2 = "content2"
        let dummyContent3 = "content3"

        let memo1 = try! memoRepository.createMemo(text: "\(dummyTitle1)\n\(dummyContent1)", uniqueId: dummyUniqueId1).toBlocking().first()!
        let memo2 = try! memoRepository.createMemo(text: "\(dummyTitle2)\n\(dummyContent2)", uniqueId: dummyUniqueId2).toBlocking().first()!
         let memo3 = try! memoRepository.createMemo(text: "\(dummyTitle3)\n\(dummyContent3)", uniqueId: dummyUniqueId3).toBlocking().first()!
        memoDataStore.dummyDataBase.append(contentsOf: [memo1, memo2, memo3])

        let allMemosBeforeDelete = try! memoRepository.readAllMemos().toBlocking().first()!
        XCTAssertEqual(allMemosBeforeDelete.count, 3)

        let blocking = memoRepository.deleteMemo(uniqueId: dummyUniqueId1).toBlocking()
        XCTAssertNoThrow(try blocking.first())

        let allMemosAfterDelete = try! memoRepository.readAllMemos().toBlocking().first()!
        XCTAssertEqual(allMemosAfterDelete.count, 2)
        XCTAssertTrue(allMemosAfterDelete.compactMap { $0.uniqueId }.contains(dummyUniqueId2))
        XCTAssertTrue(allMemosAfterDelete.compactMap { $0.uniqueId }.contains(dummyUniqueId3))
    }

    func test_countAll_保存されているメモの総数を取得できること() {
        let memoDataStore = MemoDataStoreMock()
        let memoRepository = MemoRepositoryImpl(memoDataStore: memoDataStore)
        let allMemosCount = 200

        (0..<allMemosCount).forEach {
            let memo = try! memoRepository.createMemo(text: "\($0)\n\($0)", uniqueId: "\($0)").toBlocking().first()!
            memoDataStore.dummyDataBase.append(memo)
        }

        let blocking = memoRepository.countAll().toBlocking()
        guard let memosCount = try? blocking.first() else {
            XCTFail("全件総数の取得に失敗")
            return
        }
        XCTAssertEqual(memosCount, allMemosCount)
    }
}
