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

class MemoDetailViewModel: ViewModelType {

    struct Input {
        let memoRepository: MemoRepository
        let tappedDoneButton: Signal<()>
        let textViewText: Driver<String>
        let didSaveMemo: Observable<Notification>
    }

    struct Output {
        /// メモを表示（メモがあれば）
        let setupText: Driver<String>
        /// メモを保存する
        let saveMemoText: Driver<()>
        /// リスト画面に戻る
        let returnMemoList: Driver<()>
    }

    private let memo: Memo?

    init(memo: Memo?) {
        self.memo = memo
    }

    func injection(input: Input) -> Output {
        let setupText: Driver<String>
        let saveMemoText: Driver<()>

        if let memo = self.memo {
            // 既存メモの編集時
            setupText = Driver.just((memo.title ?? "") + "\n" + (memo.content ?? ""))
            saveMemoText = input.tappedDoneButton.withLatestFrom(input.textViewText)
                .flatMap({ (text) -> Driver<()> in
                    guard let uniqueId = memo.uniqueId else { return Driver.empty() }
                    return input.memoRepository
                        .updateMemo(uniqueId: uniqueId, text: text)
                        .asDriver(onErrorDriveWith: Driver.empty())
                })
        } else {
            // 新規メモの作成時
            setupText = Driver.never()
            saveMemoText = input.tappedDoneButton.withLatestFrom(input.textViewText)
                .flatMap({ (text) -> Driver<()> in
                    return input.memoRepository
                        .createMemo(text: text, uniqueId: nil)
                        .map {_ in }
                        .asDriver(onErrorDriveWith: Driver.empty())
                })
        }
        
        let returnMemoList = input.didSaveMemo
            .map { _ in }
            .asDriver(onErrorDriveWith: Driver.empty())
        
        return Output(setupText: setupText,
                      saveMemoText: saveMemoText,
                      returnMemoList: returnMemoList)
    }
}
