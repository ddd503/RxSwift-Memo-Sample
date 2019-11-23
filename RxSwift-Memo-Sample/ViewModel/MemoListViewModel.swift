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
    let memoDataStore: MemoDataStore

    init(memoDataStore: MemoDataStore) {
        self.memoDataStore = memoDataStore
        countLabelText = memos.asObservable()
            .flatMap({ (memos) -> Observable<String> in
                let text = memos.isEmpty ? "メモなし" : "\(memos.count)件のメモ"
                return Observable.of(text)
            })
            .asDriver(onErrorJustReturn: "メモなし")
    }
}
