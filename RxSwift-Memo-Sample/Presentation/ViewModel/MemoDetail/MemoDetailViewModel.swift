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
            // 既存メモの更新時
            setupText = Driver.just((memo.title ?? "") + "\n" + (memo.content ?? ""))
            saveMemoText = input.tappedDoneButton.withLatestFrom(input.textViewText).flatMap({ (text) -> Driver<()> in
                return input.memoRepository
                    .updateMemo(memo: memo, text: text)
                    .asDriver(onErrorDriveWith: Driver.never())
            })
        } else {
            // 新規メモの作成時
            setupText = Driver.never()
            saveMemoText = input.tappedDoneButton.withLatestFrom(input.textViewText).flatMap({ (text) -> Driver<()> in
                return input.memoRepository
                    .createMemo(text: text, uniqueId: nil)
                    .asDriver(onErrorDriveWith: Driver.never())
            })
        }

        let returnMemoList = NotificationCenter.default.rx
            .notification(.NSManagedObjectContextDidSave)
            .map { _ in }
            .asDriver(onErrorDriveWith: Driver.never())
        
        return Output(setupText: setupText,
                      saveMemoText: saveMemoText,
                      returnMemoList: returnMemoList)
    }
}
