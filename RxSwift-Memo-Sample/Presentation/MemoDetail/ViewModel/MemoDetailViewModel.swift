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

class MemoDetailViewModel {

    let completeSaveMemo: Observable<Notification>

    init(memo: Memo?, textViewText: Driver<String>, memoDataStore: MemoDataStoreNew, tappedDone: Signal<()>) {

        // タップアクション → メモ作成 or メモ更新
        let _ = tappedDone.withLatestFrom(textViewText).map { (text) in
            if let memo = memo {
                memoDataStore.updateMemo(memo: memo, text: text)
            } else {
                let _ =  memoDataStore.createMemo(text: text)
            }
        }

        // CoreData保存完了、画面閉じる
        completeSaveMemo = NotificationCenter.default.rx.notification(.NSManagedObjectContextDidSave)
        
        // キーボード表示ハンドリング、Viewとbind
    }
    
}
