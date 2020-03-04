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
                XCTFail("新規作成時は初期表示でテキストが流れてこない想定")
            })
            .disposed(by: disposeBag)
    }

    func test_setupText_既存メモ作成時のメモ詳細の初期状態が既存メモが入った状態であること() {
        let testExpectation = expectation(description: "既存メモ作成時のメモ詳細の初期状態が既存メモが入った状態であること")

        let memoRepository = MemoRepositoryMock()
        let dummyUniqueId = "1000"
        let memo = MemoMock(uniqueId: dummyUniqueId,
                            title: "テスト1",
                            content: "コンテンツ1")
        memoRepository.dummyMemos.append(memo)

        let viewModelOutput = MemoDetailViewModel(memo: memo)
            .injection(input: MemoDetailViewModel.Input(memoRepository: memoRepository,
                                                        tappedDoneButton: Signal.never(),
                                                        textViewText: Driver.never(),
                                                        didSaveMemo: Observable.never()))
        viewModelOutput.setupText
            .drive(onNext: { text in
                XCTAssertEqual(text, "テスト1\nコンテンツ1")
                testExpectation.fulfill()
            })
            .disposed(by: disposeBag)

        wait(for: [testExpectation], timeout: 0.1)
    }

    func test_saveMemoText_returnMemoList_書き込まれたメモの保存処理実行完了と前画面へ戻る遷移イベントを購読できること_メモ新規作成時() {
        let memoRepository = MemoRepositoryMock()
        let textViewText = scheduler.createHotObservable([.next(1, "テスト1\nコンテンツ1")]).asDriver(onErrorDriveWith: Driver.empty())
        let tappedDoneButton = scheduler.createHotObservable([.next(2, ())]).asSignal(onErrorSignalWith: Signal.empty())
        let didSaveMemo = scheduler.createColdObservable([.next(3, Notification(name: .NSManagedObjectContextDidSave))]).asObservable()

        let viewModelOutput = MemoDetailViewModel(memo: nil)
            .injection(input: MemoDetailViewModel.Input(memoRepository: memoRepository,
                                                        tappedDoneButton: tappedDoneButton,
                                                        textViewText: textViewText,
                                                        didSaveMemo: didSaveMemo))

        let setupTextObserver = scheduler.createObserver(String.self)
        let saveMemoTextObserver = scheduler.createObserver(Void.self)
        let returnMemoListObserver = scheduler.createObserver(Void.self)

        viewModelOutput.setupText
            .drive(setupTextObserver)
            .disposed(by: disposeBag)

        viewModelOutput.saveMemoText
            .drive(saveMemoTextObserver)
            .disposed(by: disposeBag)

        viewModelOutput.returnMemoList
            .drive(returnMemoListObserver)
            .disposed(by: disposeBag)

        scheduler.start()

        // 発生イベントの確認
        let expectedSetupTextObserver: [Recorded<Event<String>>] =  []
        XCTAssertEqual(setupTextObserver.events, expectedSetupTextObserver)
        XCTAssertEqual(saveMemoTextObserver.events.count, 1)
        XCTAssertEqual(saveMemoTextObserver.events.first!.time, 2)
        XCTAssertEqual(returnMemoListObserver.events.count, 1)
        XCTAssertEqual(returnMemoListObserver.events.first!.time, 3)
        // 保存されているメモ内容確認
        XCTAssertEqual(memoRepository.dummyMemos.count, 1)
        XCTAssertEqual(memoRepository.dummyMemos.first!.uniqueId, "1")
        XCTAssertEqual(memoRepository.dummyMemos.first!.title, "テスト1")
        XCTAssertEqual(memoRepository.dummyMemos.first!.content, "コンテンツ1")
    }

    func test_saveMemoText_returnMemoList_書き込まれたメモの保存処理実行完了と前画面へ戻る遷移イベントを購読できること_メモ内容更新時() {
        let memoRepository = MemoRepositoryMock()
        let dummyUniqueId = "2000"
        let memo = MemoMock(uniqueId: dummyUniqueId,
                            title: "テスト2",
                            content: "コンテンツ2")
        memoRepository.dummyMemos.append(memo)

        let textViewText = scheduler.createHotObservable([.next(1, "テスト3\nコンテンツ3")]).asDriver(onErrorDriveWith: Driver.empty())
        let tappedDoneButton = scheduler.createHotObservable([.next(2, ())]).asSignal(onErrorSignalWith: Signal.empty())
        let didSaveMemo = scheduler.createColdObservable([.next(3, Notification(name: .NSManagedObjectContextDidSave))]).asObservable()

        let viewModelOutput = MemoDetailViewModel(memo: memo)
            .injection(input: MemoDetailViewModel.Input(memoRepository: memoRepository,
                                                        tappedDoneButton: tappedDoneButton,
                                                        textViewText: textViewText,
                                                        didSaveMemo: didSaveMemo))

        let setupTextObserver = scheduler.createObserver(String.self)
        let saveMemoTextObserver = scheduler.createObserver(Void.self)
        let returnMemoListObserver = scheduler.createObserver(Void.self)

        viewModelOutput.setupText
            .drive(setupTextObserver)
            .disposed(by: disposeBag)

        viewModelOutput.saveMemoText
            .drive(saveMemoTextObserver)
            .disposed(by: disposeBag)

        viewModelOutput.returnMemoList
            .drive(returnMemoListObserver)
            .disposed(by: disposeBag)

        scheduler.start()

        // 発生イベントの確認
        let expectedSetupTextObserver =  [Recorded.next(0, "テスト2\nコンテンツ2"), Recorded.completed(0)]
        XCTAssertEqual(setupTextObserver.events, expectedSetupTextObserver)
        XCTAssertEqual(saveMemoTextObserver.events.count, 1)
        XCTAssertEqual(saveMemoTextObserver.events.first!.time, 2)
        XCTAssertEqual(returnMemoListObserver.events.count, 1)
        XCTAssertEqual(returnMemoListObserver.events.first!.time, 3)
        // 保存されているメモ内容確認
        XCTAssertEqual(memoRepository.dummyMemos.count, 1)
        XCTAssertEqual(memoRepository.dummyMemos.first!.uniqueId, dummyUniqueId)
        XCTAssertEqual(memoRepository.dummyMemos.first!.title, "テスト3")
        XCTAssertEqual(memoRepository.dummyMemos.first!.content, "コンテンツ3")
    }
}
