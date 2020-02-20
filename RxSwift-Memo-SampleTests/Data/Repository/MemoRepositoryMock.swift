//
//  MemoRepositoryMock.swift
//  RxSwift-Memo-SampleTests
//
//  Created by kawaharadai on 2020/02/17.
//  Copyright © 2020 kawaharadai. All rights reserved.
//

import RxSwift
import Foundation
@testable import RxSwift_Memo_Sample

class MemoRepositoryMock: MemoRepository {

    var isReadMemoSuccess = true
    var dummyMemos = [Memo]()

    func createMemo(text: String, uniqueId: String?) -> Observable<Memo> {
        return Observable.of(MemoMock(),MemoMock())
    }

    func readAll() -> Observable<[Memo]> {
        return Observable.just(dummyMemos)
    }

    func readMemo(uniqueId: String) -> Observable<Memo?> {
        return isReadMemoSuccess ? Observable.just(MemoMock()) : Observable.just(nil)
    }

    func updateMemo(memo: Memo, text: String) -> Observable<Void> {
        let updateMemo = dummyMemos.filter { memo.uniqueId == $0.uniqueId }.first!
        updateMemo.title = memo.title
        updateMemo.content = memo.content
        updateMemo.editDate = Date()
        return Observable.just(())
    }

    func deleteAll(entityName: String) -> Observable<Void> {
        dummyMemos = []
        return Observable.just(())
    }

    func deleteMemo(uniqueId: String) -> Observable<Void> {
        dummyMemos = dummyMemos.filter { uniqueId != $0.uniqueId }
        return Observable.just(())
    }

    func countAll() -> Observable<Int> {
        return Observable.just(dummyMemos.count)
    }
}
