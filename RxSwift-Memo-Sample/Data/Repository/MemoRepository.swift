//
//  MemoRepository.swift
//  RxSwift-Memo-Sample
//
//  Created by kawaharadai on 2020/02/14.
//  Copyright © 2020 kawaharadai. All rights reserved.
//

import Foundation
import CoreData
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
    func deleteAll(entityName: String) -> Observable<Void>

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

        let createMemo: Observable<Memo?> = memoDataStore.create(entityName: "Memo")

        return createMemo
            .flatMap { (memo) -> Observable<Void> in
                guard let memo = memo,
                    let managedObjectContext = memo.managedObjectContext else { return Observable.empty() }

                return self.countAll()
                    .flatMap { (allMemoCount) -> Observable<Void> in
                        managedObjectContext.performAndWait {
                            memo.uniqueId = uniqueId ?? "\(allMemoCount + 1)"
                            memo.title = text.firstLine
                            memo.content = text.afterSecondLine
                            memo.editDate = Date()
                        }
                        return self.memoDataStore.save(context: managedObjectContext).map { _ in }
                }
        }
    }

    func readAll() -> Observable<[Memo]> {
        let allMemos: Observable<[Memo]> = memoDataStore.fetchArray(predicates: [],
                                                                    sortKey: "editDate",
                                                                    ascending: false)
        return allMemos
    }

    func readMemo(uniqueId: String) -> Observable<Memo?> {
        let fetchResult: Observable<[Memo]> =
            memoDataStore.fetchArray(predicates: [NSPredicate(format: "uniqueId == %@", uniqueId)],
                                     sortKey: "editDate",
                                     ascending: false)
        return fetchResult.map { $0.first }
    }

    func updateMemo(memo: Memo, text: String) -> Observable<Void> {
        return Observable.just(memo.managedObjectContext)
            .flatMap { (context) -> Observable<Void> in
                guard let context = context else { return Observable.empty() }
                context.performAndWait {
                    memo.title = text.firstLine
                    memo.content = text.afterSecondLine
                    memo.editDate = Date()
                }
                return self.memoDataStore.save(context: context).map { _ in }
        }
    }

    func deleteAll(entityName: String) -> Observable<Void> {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        let result = memoDataStore.excute(request: deleteRequest)
        return result.map { _ in }
    }

    func deleteMemo(uniqueId: String) -> Observable<Void> {
        return readMemo(uniqueId: uniqueId)
            .flatMap { (memo) -> Observable<Void> in
                guard let memo = memo else { return Observable.empty() }
                let deleteOperation: Observable<Notification> = self.memoDataStore.delete(object: memo)
                return deleteOperation.map { _ in }
        }
    }

    func countAll() -> Observable<Int> {
        return readAll().map { $0.count }
    }
}
