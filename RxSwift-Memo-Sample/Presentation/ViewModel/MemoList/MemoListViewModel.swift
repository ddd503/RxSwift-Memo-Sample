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

    struct Input {
        let memosCount: Driver<Int>
        let memoDataStore: MemoDataStoreNew
        let addButtonTap: Signal<()>
        let isEditing: Driver<Bool>
    }

    struct Output {
        let didChangeMemoCount: Driver<String>
        let deleteAllMemo: Signal<()>
        let showAllDeleteAlert: Signal<()>
    }

    func injection(input: Input) -> Output {
        let didChangeMemoCount = input.memosCount.flatMap { (count) -> Driver<String> in
            let text = count <= 0 ? "メモなし" : "\(count)件のメモ"
            return Driver.just(text)
        }

        let isEditingWhenTapAddBotton = input.addButtonTap.withLatestFrom(input.isEditing)

        let showAllDeleteAlert = isEditingWhenTapAddBotton.flatMapLatest { (isEditing) -> Signal<()> in
            return isEditing ? Signal.just(()) : Signal.never()
        }

        let deleteAllMemo = input.memoDataStore
            .deleteAll()
            .asSignal(onErrorSignalWith: Signal.never())

        return Output(didChangeMemoCount: didChangeMemoCount,
                      deleteAllMemo: deleteAllMemo,
                      showAllDeleteAlert: showAllDeleteAlert)
    }
}
