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
        let transitionCreateMemo: Driver<()>
        let showAllDeleteAlert: Driver<()>
        let listDataSource: BehaviorRelay<[Memo]>
        let updateMemoCount: Driver<Int>
        let deleteAllMemo: Driver<()>
    }
    
    func injection(input: Input) -> Output {
        return Output(transitionCreateMemo: Driver.empty(),
                      showAllDeleteAlert: Driver.empty(),
                      listDataSource: self.memos,
                      updateMemoCount: Driver.just(self.memos.value.count),
                      deleteAllMemo: Driver.empty())
    }
}
