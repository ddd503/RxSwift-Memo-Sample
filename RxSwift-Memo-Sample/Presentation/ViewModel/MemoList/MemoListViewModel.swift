//
//  MemoListViewModel.swift
//  RxSwift-Memo-Sample
//
//  Created by kawaharadai on 2019/10/17.
//  Copyright © 2019 kawaharadai. All rights reserved.
//

import RxCocoa
import RxSwift

final class MemoListViewModel: ViewModelType {

    private var memos = BehaviorRelay<[Memo]>(value: [])

    struct Input {
        let memoDataStore: MemoDataStore
        let tableViewEditing: Driver<Bool>
        let tappedUnderRightButton: Signal<()>
    }

    struct Output {
        /// リスト更新（初回表示時）
        let updateMemosAtStartUp: Driver<()>
        /// リスト更新（メモ更新時）
        let updateMemosAtCompleteSaveMemo: Driver<()>
        /// リスト更新（全削除時）
        let updateMemosAtDeleteAllMemo: Driver<()>
        /// 新規作成画面への遷移
        let transitionCreateMemo: Driver<()>
        /// 全削除アラートの表示
        let showAllDeleteAlert: Driver<()>
        /// リスト表示するデータソース
        let listDataSource: BehaviorRelay<[Memo]>
        /// メモ数表示の更新
        let updateMemoCount: Driver<Int>
        /// ボタンタイトルの更新
        let updateButtonTitle: Driver<String>
    }
    
    func injection(input: Input) -> Output {
        let updateMemosAtStartUp = input.memoDataStore
            .readAll()
            .flatMap { [weak self] (memos) -> Observable<()> in
                self?.memos.accept(memos)
                return Observable.just(())
        }
        .asDriver(onErrorDriveWith: Driver.never())

        let updateMemosAtCompleteSaveMemo = NotificationCenter.default.rx
            .notification(.NSManagedObjectContextDidSave)
            .flatMap { (_) -> Observable<()> in
                return input.memoDataStore
                    .readAll()
                    .map { [weak self] (memos) in
                        self?.memos.accept(memos)
                }
        }
        .asDriver(onErrorDriveWith: Driver.never())

        let updateMemosAtDeleteAllMemo = input.memoDataStore
            .deleteAll().flatMap({ (_) -> Observable<()> in
                return input.memoDataStore
                    .readAll()
                    .map { [weak self] (memos) in
                        self?.memos.accept(memos)
                }
            })
            .asDriver(onErrorDriveWith: Driver.never())

        let transitionCreateMemo = input.tappedUnderRightButton
            .withLatestFrom(input.tableViewEditing)
            .flatMap { (isEditing) -> Driver<()> in
                return isEditing ? Driver.never() : Driver.just(())
        }

        let showAllDeleteAlert = input.tappedUnderRightButton
            .withLatestFrom(input.tableViewEditing)
            .flatMap { (isEditing) -> Driver<()> in
                return isEditing ? Driver.just(()) : Driver.never()
        }

        let updateMemoCount = memos
            .flatMap { (memos) -> Observable<Int> in
                return Observable.just(memos.count)
        }
        .asDriver(onErrorDriveWith: Driver.just(0))

        let updateButtonTitle = input.tableViewEditing
            .flatMap { (isEditing) -> Driver<String> in
                return Driver.just(isEditing ? "全て削除" : "メモ追加")
        }
        
        return Output(updateMemosAtStartUp: updateMemosAtStartUp,
                      updateMemosAtCompleteSaveMemo: updateMemosAtCompleteSaveMemo,
                      updateMemosAtDeleteAllMemo: updateMemosAtDeleteAllMemo,
                      transitionCreateMemo: transitionCreateMemo,
                      showAllDeleteAlert: showAllDeleteAlert,
                      listDataSource: self.memos,
                      updateMemoCount: updateMemoCount,
                      updateButtonTitle: updateButtonTitle)
    }
}
