//
//  MemoRepository.swift
//  RxSwift-Memo-Sample
//
//  Created by kawaharadai on 2020/02/14.
//  Copyright © 2020 kawaharadai. All rights reserved.
//

import Foundation
import RxSwift

protocol MemoRepository {
    /// 新規メモを作成する
    /// - Parameters:
    ///   - text: メモ内容
    ///   - uniqueId: 新規メモに割り当てるユニークID（nilの場合は全件+1がID）
    func createMemo(text: String, uniqueId: String?) -> Observable<Void>

    /// 全メモを取得する
    func readAll() -> Observable<[Memo]>

    /// ID指定でメモを1件取得する
    /// - Parameter uniqueId: ユニークID
    func readMemo(uniqueId: String) -> Observable<Memo?>

    /// メモを更新する
    /// - Parameters:
    ///   - memo: 更新するメモ
    ///   - text: 更新内容
    func updateMemo(memo: Memo, text: String) -> Observable<Void>

    /// 全メモを削除する
    func deleteAll() -> Observable<Void>

    /// ID指定でメモを削除する
    /// - Parameter uniqueId: ユニークID
    func deleteMemo(uniqueId: String) -> Observable<Void>

    /// 全メモ件数を取得する
    func countAll() -> Observable<Int>
}

struct MemoRepositoryImpl: MemoRepository {

    let memoDataStore: MemoDataStore

    init(memoDataStore: MemoDataStore) {
        self.memoDataStore = memoDataStore
    }

    func createMemo(text: String, uniqueId: String?) -> Observable<Void> {

        let createMemo: Observable<Memo?> = memoDataStore.createMemo(entityName: "Memo")

        return createMemo
            .flatMap { (memo) -> Observable<Void> in
                guard let memo = memo, let managedObjectContext = memo.managedObjectContext else { return Observable.never() }
                return self.memoDataStore.countAll().map { (allMemoCount) in
                    managedObjectContext.performAndWait {
                        memo.uniqueId = uniqueId ?? "\(allMemoCount + 1)"
                        memo.title = text.firstLine
                        memo.content = text.afterSecondLine
                        memo.editDate = Date()
                        self.memoDataStore.saveContext(managedObjectContext)
                    }
                }
        }
    }

    func readAll() -> Observable<[Memo]> {
        return Observable.never()
    }

    func readMemo(uniqueId: String) -> Observable<Memo?> {
        return Observable.never()
    }

    func updateMemo(memo: Memo, text: String) -> Observable<Void> {
        return Observable.never()
    }

    func deleteAll() -> Observable<Void> {
        return Observable.never()
    }

    func deleteMemo(uniqueId: String) -> Observable<Void> {
        return Observable.never()
    }

    func countAll() -> Observable<Int> {
        return Observable.never()
    }

}
