//
//  MemoDetailViewModel.swift
//  RxSwift-Memo-Sample
//
//  Created by kawaharadai on 2019/11/24.
//  Copyright © 2019 kawaharadai. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import UIKit

class MemoDetailViewModel {

    let startSaveMemo: Driver<Memo>
    let completeSaveMemo: Observable<Notification>

    init(memo: Memo?, textViewText: Driver<String>, memoDataStore: MemoDataStore, tappedDone: Signal<()>) {
        // タップアクション → メモ作成 or メモ更新
        startSaveMemo = tappedDone.withLatestFrom(textViewText)
            .flatMapLatest({ (text) -> Driver<Memo> in
                if let memo = memo {
                    return memoDataStore.updateMemo(memo: memo, text: text).asDriver(onErrorJustReturn: memo)
                } else {
                    let createMemo = memoDataStore.createMemo(text: text)
                    return createMemo.asDriver(onErrorJustReturn: Memo())
                }
            })

        // メモ保存完了
        completeSaveMemo = NotificationCenter.default.rx.notification(.NSManagedObjectContextDidSave)
    }
    
}
