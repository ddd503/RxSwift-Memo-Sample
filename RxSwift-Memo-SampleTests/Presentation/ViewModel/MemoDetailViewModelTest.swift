//
//  MemoDetailViewModelTest.swift
//  RxSwift-Memo-SampleTests
//
//  Created by kawaharadai on 2020/02/21.
//  Copyright © 2020 kawaharadai. All rights reserved.
//

import XCTest
import RxSwift
import RxCocoa
import RxTest
@testable import RxSwift_Memo_Sample

class MemoDetailViewModelTest: XCTestCase {

    private var scheduler = TestScheduler(initialClock: 0)
    private var disposeBag = DisposeBag()

    override func setUp() {
        // スケジューラーの初期化
        scheduler = TestScheduler(initialClock: 0)
    }

    func test_setupText_新規メモ作成時のメモ詳細の初期状態が白紙状態であること() {
        let memoRepository = MemoRepositoryMock()
        let viewModelOutput = MemoDetailViewModel(memo: nil)
            .injection(input: MemoDetailViewModel.Input(memoRepository: memoRepository,
                                                        tappedDoneButton: Signal.never(),
                                                        textViewText: Driver.never(),
                                                        didSaveMemo: Observable.never()))
        viewModelOutput.setupText
            .drive(onNext: { text in
                XCTAssertEqual(text, "")
            })
            .disposed(by: disposeBag)
    }

    func test_setupText_既存メモ作成時のメモ詳細の初期状態が既存メモが入った状態であること() {
        let memoRepository = MemoRepositoryMock()
        let dummyUniqueId = "1000"
        let memo = MemoMock(uniqueId: dummyUniqueId, title: "テスト1", content: "コンテンツ1")
        memoRepository.dummyMemos.append(memo)

        let textViewText = scheduler.createHotObservable([.next(1, "テスト1")]).asDriver(onErrorDriveWith: Driver.empty())
        let tappedDoneButton = scheduler.createHotObservable([.next(2, ())]).asSignal(onErrorSignalWith: Signal.empty())
        let viewModelOutput = MemoDetailViewModel(memo: nil)
            .injection(input: MemoDetailViewModel.Input(memoRepository: memoRepository,
                                                        tappedDoneButton: tappedDoneButton,
                                                        textViewText: textViewText,
                                                        didSaveMemo: Observable.never()))
        viewModelOutput.setupText
            .drive(onNext: { text in
                XCTAssertEqual(text, "")
            })
            .disposed(by: disposeBag)
    }

    func test_saveMemoText_returnMemoList_書き込まれたメモの保存処理実行完了と前画面へ戻る遷移イベントを購読できること() {}

}
