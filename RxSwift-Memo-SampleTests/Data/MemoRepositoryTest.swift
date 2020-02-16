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

   override func setUp() {}

    override func tearDown() {}

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

    func test_readAll_保存中のメモを全件取得できること() {
        let memoDataStore = MemoDataStoreMock()
        let memoRepository = MemoRepositoryImpl(memoDataStore: memoDataStore)
        let allMemosCount = 100

        (0..<allMemosCount).forEach {
            let memo = try! memoRepository.createMemo(text: "\($0)\n\($0)", uniqueId: "\($0)").toBlocking().first()!
            memoDataStore.dummyDataBase.append(memo)
        }

        let blocking = memoRepository.readAll().toBlocking()
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
}
