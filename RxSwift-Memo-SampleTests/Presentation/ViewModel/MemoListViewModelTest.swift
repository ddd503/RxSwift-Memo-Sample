//
//  MemoListViewModelTest.swift
//  RxSwift-Memo-SampleTests
//
//  Created by kawaharadai on 2020/02/16.
//  Copyright © 2020 kawaharadai. All rights reserved.
//

import XCTest
import RxSwift
import RxCocoa
import RxTest
@testable import RxSwift_Memo_Sample

class MemoListViewModelTest: XCTestCase {

    private var scheduler = TestScheduler(initialClock: 0)
    private var disposeBag = DisposeBag()

    override func setUp() {
        // スケジューラーの初期化
        scheduler = TestScheduler(initialClock: 0)
    }

    func test_updateMemosAtStartUp_購読時に保存中のメモを全件取得できること() {
        let memoRepository = MemoRepositoryMock()
        memoRepository.dummyMemos.append(contentsOf: [MemoMock(), MemoMock()])
        let viewModelOutput = MemoListViewModel()
            .injection(input: MemoListViewModel.Input(memoRepository: memoRepository,
                                                      tableViewEditing: Driver.just(false),
                                                      tappedUnderRightButton: Signal.just(()),
                                                      deleteMemoAction: Driver.just(""),
                                                      showActionSheet: Driver.just(.init(style: .default, actionType: .cancel)),
                                                      didSaveMemo: Observable.just(Notification(name: .NSManagedObjectContextDidSave))))

        // 宣言時ではなく、購読時の評価をしたいため、初回をskipする
        viewModelOutput.updateMemoList
            .skip(1)
            .drive(onNext: { memoList in
                XCTAssertEqual(memoList.count, 2)
            })
            .disposed(by: disposeBag)

        viewModelOutput.updateMemosAtStartUp
            .drive(onNext: { _ in
                XCTAssertTrue(true)
            })
            .disposed(by: disposeBag)
    }

    func test_updateMemosAtCompleteSaveMemo_メモ保存完了時のイベントを購読できること() {}

    func test_updateMemosAtDeleteAllMemo_メモ全件削除時のイベントを購読できること() {}

    func test_updateMemosAtDeleteMemo_メモの個別削除時のイベントを購読できること() {}

    func test_transitionCreateMemo_新規作成画面への遷移イベントを購読できること() {}

    func test_updateButtonTitle_ボタンタイトルの更新イベントを購読できること() {}

}
