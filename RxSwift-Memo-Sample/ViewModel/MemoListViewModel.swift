//
//  MemoListViewModel.swift
//  RxSwift-Memo-Sample
//
//  Created by kawaharadai on 2019/10/17.
//  Copyright © 2019 kawaharadai. All rights reserved.
//

import RxCocoa
import RxSwift

class MemoListViewModel {
    var memos = BehaviorRelay<[Memo]>(value: [])
    let countLabelText: Driver<String>
//    let isEditing: Observable<Bool>
//    let tapAction: Signal<()>

    init(isEditing: Observable<Bool>, tapAddButton: Signal<()>) {


        countLabelText = memos.asObservable()
            .flatMap({ (memos) -> Observable<String> in
                let text = memos.isEmpty ? "メモなし" : "\(memos.count)件のメモ"
                return Observable.of(text)
            })
            .asDriver(onErrorJustReturn: "メモなし")
    }
}
