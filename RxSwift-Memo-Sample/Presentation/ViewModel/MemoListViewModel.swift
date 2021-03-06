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
        let viewWillAppear: Observable<[Any]>
        let tableViewEditing: Driver<Bool>
        let tappedUnderRightButton: Signal<()>
        let deleteMemoAction: Driver<String>
        let showActionSheet: Driver<AlertEvent>
        let didSaveMemo: Observable<Notification>
    }

    struct Output {
        /// メモリストが更新された
        let updateMemoList: Driver<[Memo]>
        /// メモ一覧取得（viewWillAppear時）
        let updateMemosAtWillAppear: Driver<()>
        /// メモ一覧取得（メモデータ更新後）
        let updateMemosAtCompleteSaveMemo: Driver<()>
        /// メモ一覧取得（全削除後）
        let updateMemosAtDeleteAllMemo: Driver<()>
        /// メモ一覧取得（個別削除後）
        let updateMemosAtDeleteMemo: Driver<()>
        /// 新規作成画面への遷移
        let transitionCreateMemo: Driver<()>
        /// リスト表示するデータソース
        let listDataSource: BehaviorRelay<[Memo]>
        /// ボタンタイトルの更新
        let updateButtonTitle: Driver<String>
        /// エラーアラートをの表示
        let showErrorAlert: PublishRelay<String?>
    }
    
    func injection(input: Input) -> Output {

        let showErrorAlert = PublishRelay<String?>()

        let updateMemosAtWillAppear = input.viewWillAppear
            .flatMap { (_) -> Observable<()> in
                return input.memoRepository
                    .readAllMemos()
                    .catchError { (error) -> Observable<[Memo]> in
                        showErrorAlert.accept(error.localizedDescription)
                        return Observable.never()
                }
                .map { [weak self] (memos) in
                    self?.memos.accept(memos)
                }
        }
        .asDriver(onErrorDriveWith: Driver.empty())

        let updateMemosAtCompleteSaveMemo = input.didSaveMemo
            .flatMap { (_) -> Observable<()> in
                return input.memoRepository
                    .readAllMemos()
                    .catchError({ (error) -> Observable<[Memo]> in
                        showErrorAlert.accept(error.localizedDescription)
                        return Observable.never()
                    })
                    .map { [weak self] (memos) in
                        self?.memos.accept(memos)
                }
        }
        .asDriver(onErrorDriveWith: Driver.empty())

        let updateMemosAtDeleteAllMemo = input.tappedUnderRightButton
            .withLatestFrom(input.tableViewEditing)
            .flatMap { (isEditing) -> Driver<Void> in
                guard isEditing else { return Driver.never() }
                return input.showActionSheet
                    .flatMap { (event) -> Driver<Void> in
                        switch event.actionType {
                        case .allDelete:
                            return input.memoRepository
                                .deleteAll(entityName: "Memo")
                                .catchError({ (error) -> Observable<()> in
                                    showErrorAlert.accept(error.localizedDescription)
                                    return Observable.empty()
                                })
                                .flatMap { (_) -> Observable<()> in
                                    return input.memoRepository
                                        .readAllMemos()
                                        .catchError({ (error) -> Observable<[Memo]> in
                                            showErrorAlert.accept(error.localizedDescription)
                                            return Observable.never()
                                        })
                                        .map { [weak self] (memos) in
                                            self?.memos.accept(memos)
                                    }
                            }
                            .asDriver(onErrorDriveWith: Driver.empty())
                        case .cancel:
                            return Driver.empty()
                        }
                }
        }

        let updateMemosAtDeleteMemo = input.deleteMemoAction
            .flatMap { (uniqueId) -> Driver<()> in
                return input.memoRepository
                    .deleteMemo(uniqueId: uniqueId)
                    .catchError({ (error) -> Observable<()> in
                        showErrorAlert.accept(error.localizedDescription)
                        return Observable.empty()
                    })
                    .flatMap({ (_) -> Observable<()> in
                        return input.memoRepository
                            .readAllMemos()
                            .catchError({ (error) -> Observable<[Memo]> in
                                return Observable.never()
                            })
                            .map { [weak self] (memos) in
                                self?.memos.accept(memos)
                        }
                    })
                    .asDriver(onErrorDriveWith: Driver.empty())
        }

        let transitionCreateMemo = input.tappedUnderRightButton
            .withLatestFrom(input.tableViewEditing)
            .flatMap { (isEditing) -> Driver<()> in
                return isEditing ? Driver.never() : Driver.just(())
        }

        let updateButtonTitle = input.tableViewEditing
            .flatMap { (isEditing) -> Driver<String> in
                return Driver.just(isEditing ? "全て削除" : "メモ追加")
        }
        
        return Output(updateMemoList: memos.asDriver(),
                      updateMemosAtWillAppear: updateMemosAtWillAppear,
                      updateMemosAtCompleteSaveMemo: updateMemosAtCompleteSaveMemo,
                      updateMemosAtDeleteAllMemo: updateMemosAtDeleteAllMemo,
                      updateMemosAtDeleteMemo: updateMemosAtDeleteMemo,
                      transitionCreateMemo: transitionCreateMemo,
                      listDataSource: self.memos,
                      updateButtonTitle: updateButtonTitle,
                      showErrorAlert: showErrorAlert)
    }
}
