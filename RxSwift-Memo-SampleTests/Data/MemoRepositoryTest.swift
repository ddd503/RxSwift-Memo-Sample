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
}
