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

    var isSuccessFunc = true
    var dummyMemos = [Memo]()
    let testError = NSError(domain: "TestErrorDomain", code: 999, userInfo: nil)

    func createMemo(text: String, uniqueId: String?) -> Observable<Memo> {
        guard isSuccessFunc else { return Observable.error(testError) }

        let newMemo = MemoMock(uniqueId: uniqueId ?? "\(dummyMemos.count + 1)",
                               title: text.firstLine,
                               content: text.afterSecondLine,
                               editDate: Date())
        dummyMemos.append(newMemo)
        return Observable.just(newMemo)
    }

    func readAllMemos() -> Observable<[Memo]> {
        return isSuccessFunc ? Observable.just(dummyMemos) : Observable.error(testError)
    }

    func readMemo(uniqueId: String) -> Observable<Memo?> {
        return isSuccessFunc ? Observable.just(MemoMock()) : Observable.error(testError)
    }

    func updateMemo(uniqueId: String, text: String) -> Observable<()> {
        guard isSuccessFunc else { return Observable.error(testError) }

        let updateMemo = dummyMemos.filter { uniqueId == $0.uniqueId }.first!
        updateMemo.title = text.firstLine
        updateMemo.content = text.afterSecondLine
        updateMemo.editDate = Date()
        return Observable.just(())
    }

    func deleteAll(entityName: String) -> Observable<()> {
        guard isSuccessFunc else { return Observable.error(testError) }

        dummyMemos = []
        return Observable.just(())
    }

    func deleteMemo(uniqueId: String) -> Observable<()> {
        guard isSuccessFunc else { return Observable.error(testError) }

        dummyMemos = dummyMemos.filter { uniqueId != $0.uniqueId }
        return Observable.just(())
    }

    func countAll() -> Observable<Int> {
        return Observable.just(dummyMemos.count)
    }
}
