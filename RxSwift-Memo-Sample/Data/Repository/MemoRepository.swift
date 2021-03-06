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
    func createMemo(text: String, uniqueId: String?) -> Observable<Memo>

    /// 全メモを取得する
    func readAllMemos() -> Observable<[Memo]>

    /// ID指定でメモを1件取得する
    /// - Parameter uniqueId: ユニークID
    func readMemo(uniqueId: String) -> Observable<Memo?>

    /// メモを更新する
    /// - Parameters:
    ///   - uniqueId: 更新するメモのuniqueId
    ///   - text: 更新内容
    func updateMemo(uniqueId: String, text: String) -> Observable<()>

    /// 全メモを削除する
    func deleteAll(entityName: String) -> Observable<()>

    /// ID指定でメモを削除する
    /// - Parameter uniqueId: ユニークID
    func deleteMemo(uniqueId: String) -> Observable<()>

    /// 全メモ件数を取得する
    func countAll() -> Observable<Int>
}

struct MemoRepositoryImpl: MemoRepository {

    let memoDataStore: MemoDataStore

    init(memoDataStore: MemoDataStore) {
        self.memoDataStore = memoDataStore
    }

    func createMemo(text: String, uniqueId: String?) -> Observable<Memo> {
        let createMemo: Observable<Memo?> = memoDataStore.create(entityName: "Memo")
        return createMemo
            .flatMap { (memo) -> Observable<Memo> in
                guard let memo = memo,
                    let managedObjectContext = memo.managedObjectContext else {
                        return Observable.error(CoreDataError.notFoundContext)
                }
                return self.countAll()
                    .map { (allMemoCount) in
                        managedObjectContext.performAndWait {
                            memo.uniqueId = uniqueId ?? "\(allMemoCount + 1)"
                            memo.title = text.firstLine
                            memo.content = text.afterSecondLine
                            memo.editDate = Date()
                            self.memoDataStore.save(context: managedObjectContext)
                        }
                        return memo
                }
        }
    }

    func readAllMemos() -> Observable<[Memo]> {
        let allMemos: Observable<[Memo]> = memoDataStore.fetchArray(predicates: [],
                                                                    sortKey: "editDate",
                                                                    ascending: false,
                                                                    logicalType: .and)
        return allMemos
    }

    func readMemo(uniqueId: String) -> Observable<Memo?> {
        let fetchResult: Observable<[Memo]> =
            memoDataStore.fetchArray(predicates: [NSPredicate(format: "uniqueId == %@", uniqueId)],
                                     sortKey: "editDate",
                                     ascending: false,
                                     logicalType: .and)
        return fetchResult.map { $0.first }
    }

    func updateMemo(uniqueId: String, text: String) -> Observable<()> {
        return readMemo(uniqueId: uniqueId).flatMap { (memo) -> Observable<()> in
            guard let memo = memo,
                let context = memo.managedObjectContext else {
                    return Observable.error(CoreDataError.notFoundContext)
            }
            context.performAndWait {
                memo.title = text.firstLine
                memo.content = text.afterSecondLine
                memo.editDate = Date()
            }
            return self.memoDataStore.save(context: context)
        }
    }

    func deleteAll(entityName: String) -> Observable<()> {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        return memoDataStore.execute(request: deleteRequest)
    }

    func deleteMemo(uniqueId: String) -> Observable<()> {
        return readMemo(uniqueId: uniqueId)
            .flatMap { (memo) -> Observable<()> in
                guard let memo = memo else { return Observable.error(CoreDataError.failedFetchMemoById) }
                return self.memoDataStore.delete(object: memo)
        }
    }

    func countAll() -> Observable<Int> {
        return readAllMemos().map { $0.count }
    }
}
