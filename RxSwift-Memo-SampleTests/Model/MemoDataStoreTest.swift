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

    override func setUp() {

    }

    override func tearDown() {

    }

    func test_createMemo_新規メモが作成できること() {
        let newMemo = memoDataStore.createMemo()
        XCTAssertNotNil(newMemo)
        XCTAssertNotNil(newMemo?.uniqueId)
    }
}
