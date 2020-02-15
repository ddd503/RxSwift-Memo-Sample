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
        let memoRepository: MemoRepository
        let tableViewEditing: Driver<Bool>
        let tappedUnderRightButton: Signal<()>
        let deleteMemoAction: Driver<String>
    }

    struct Output {
        /// メモリストが更新された
        let updateMemoList: Driver<[Memo]>
        /// メモ一覧取得（初回表示時）
        let updateMemosAtStartUp: Driver<()>
        /// メモ一覧取得（メモデータ更新後）
        let updateMemosAtCompleteSaveMemo: Driver<()>
        /// メモ一覧取得（全削除後）
        let updateMemosAtDeleteAllMemo: Driver<()>
        /// メモ一覧取得（個別削除後）
        let updateMemosAtDeleteMemo: Driver<()>
        /// 新規作成画面への遷移
        let transitionCreateMemo: Driver<()>
        /// 全削除アラートの表示
        let showAllDeleteAlert: Driver<()>
        /// リスト表示するデータソース
        let listDataSource: BehaviorRelay<[Memo]>
        /// ボタンタイトルの更新
        let updateButtonTitle: Driver<String>
    }
    
    func injection(input: Input) -> Output {
        let updateMemosAtStartUp = input.memoRepository
            .readAll()
            .flatMap { [weak self] (memos) -> Observable<()> in
                self?.memos.accept(memos)
                return Observable.just(())
        }
        .asDriver(onErrorDriveWith: Driver.never())

        let updateMemosAtCompleteSaveMemo = NotificationCenter.default.rx
            .notification(.NSManagedObjectContextDidSave)
            .flatMap { (_) -> Observable<()> in
                return input.memoRepository
                    .readAll()
                    .map { [weak self] (memos) in
                        self?.memos.accept(memos)
                }
        }
        .asDriver(onErrorDriveWith: Driver.never())

        let updateMemosAtDeleteAllMemo = input.memoRepository
            .deleteAll(entityName: "Memo")
            .flatMap({ (_) -> Observable<()> in
                return input.memoRepository
                    .readAll()
                    .map { [weak self] (memos) in
                        self?.memos.accept(memos)
                }
            })
            .asDriver(onErrorDriveWith: Driver.never())

        let updateMemosAtDeleteMemo = input.deleteMemoAction
            .flatMap { (uniqueId) -> Driver<()> in
                return input.memoRepository
                    .deleteMemo(uniqueId: uniqueId)
                    .asDriver(onErrorDriveWith: Driver.never())
        }

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

        let updateButtonTitle = input.tableViewEditing
            .flatMap { (isEditing) -> Driver<String> in
                return Driver.just(isEditing ? "全て削除" : "メモ追加")
        }
        
        return Output(updateMemoList: memos.asDriver(),
                      updateMemosAtStartUp: updateMemosAtStartUp,
                      updateMemosAtCompleteSaveMemo: updateMemosAtCompleteSaveMemo,
                      updateMemosAtDeleteAllMemo: updateMemosAtDeleteAllMemo,
                      updateMemosAtDeleteMemo: updateMemosAtDeleteMemo,
                      transitionCreateMemo: transitionCreateMemo,
                      showAllDeleteAlert: showAllDeleteAlert,
                      listDataSource: self.memos,
                      updateButtonTitle: updateButtonTitle)
    }
}
