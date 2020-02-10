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
        let updateMemosAtStartUp: Driver<()>
        let transitionCreateMemo: Driver<()>
        let showAllDeleteAlert: Driver<()>
        let listDataSource: BehaviorRelay<[Memo]>
        let updateMemoCount: Driver<Int>
        let updateButtonTitle: Driver<String>
        let deleteAllMemo: Driver<()>
    }
    
    func injection(input: Input) -> Output {
        let updateMemosAtStartUp = input.memoDataStore
            .readAll()
            .flatMap { [weak self] (memos) -> Observable<()> in
                self?.memos.accept(memos)
                return Observable.just(())
        }
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

        let deleteAllMemo = input.memoDataStore
            .deleteAll()
            .asDriver(onErrorDriveWith: Driver.never())

        return Output(updateMemosAtStartUp: updateMemosAtStartUp,
                      transitionCreateMemo: transitionCreateMemo,
                      showAllDeleteAlert: showAllDeleteAlert,
                      listDataSource: self.memos,
                      updateMemoCount: updateMemoCount,
                      updateButtonTitle: updateButtonTitle,
                      deleteAllMemo: deleteAllMemo)
    }
}
