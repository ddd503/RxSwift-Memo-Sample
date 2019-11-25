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

    init(memo: Memo?, text: Observable<String?>, memoDataStore: MemoDataStoreNew, tappedDone: Signal<()>) {
        // タップアクション、メモ作成 or メモ更新

        // CoreData保存完了、画面閉じる

        // キーボード表示ハンドリング、Viewとbind
    }
    
}
