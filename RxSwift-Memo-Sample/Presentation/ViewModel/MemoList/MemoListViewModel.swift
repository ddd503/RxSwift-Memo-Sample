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
        let vcEditing: Driver<Bool>
        let tappedAdd: Signal<()>
        let tappedAllDelete: Signal<()>
    }

    struct Output {
        let transitionCreateMemo: Driver<()>
        let transitionDetailMemo: Driver<()>
    }

    func injection(input: Input) -> Output {
        return Output(transitionCreateMemo: Driver.empty(),
                      transitionDetailMemo: Driver.empty())
    }
}
