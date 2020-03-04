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

    func test_updateMemosAtWillAppear_viewWillAppearのタイミングで保存中のメモを全件取得できること() {
        let memoRepository = MemoRepositoryMock()
        memoRepository.dummyMemos.append(contentsOf: [MemoMock(), MemoMock()])

        let viewWillAppear: Observable<[Any]> = scheduler.createColdObservable([.next(1, [()])]).asObservable()
        let viewModelOutput = MemoListViewModel()
            .injection(input: MemoListViewModel.Input(memoRepository: memoRepository,
                                                      viewWillAppear: viewWillAppear,
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

        viewModelOutput.updateMemosAtWillAppear
            .drive(onNext: { _ in
                XCTAssertTrue(true)
            })
            .disposed(by: disposeBag)
    }

    func test_updateMemosAtCompleteSaveMemo_メモ保存完了時のイベントを購読できること() {
        let memoRepository = MemoRepositoryMock()
        memoRepository.dummyMemos.append(contentsOf: [MemoMock(), MemoMock(), MemoMock()])
        // 仮装時間1を待ったのち保存完了通知を受け取るObservableを用意
        let didSaveMemo = scheduler.createColdObservable([.next(1, Notification(name: .NSManagedObjectContextDidSave))]).asObservable()
        let viewModelOutput = MemoListViewModel()
            .injection(input: MemoListViewModel.Input(memoRepository: memoRepository,
                                                      viewWillAppear: Observable.empty(),
                                                      tableViewEditing: Driver.just(false),
                                                      tappedUnderRightButton: Signal.just(()),
                                                      deleteMemoAction: Driver.just(""),
                                                      showActionSheet: Driver.just(.init(style: .default, actionType: .cancel)),
                                                      didSaveMemo: didSaveMemo))
        viewModelOutput.updateMemoList
            .skip(1)
            .drive(onNext: { memoList in
                XCTAssertEqual(memoList.count, 3)
            })
            .disposed(by: disposeBag)

        viewModelOutput.updateMemosAtCompleteSaveMemo
            .drive(onNext: { _ in
                XCTAssertTrue(true)
            })
            .disposed(by: disposeBag)

        scheduler.start()
    }

    func test_updateMemosAtDeleteAllMemo_メモ全件削除時のイベントを購読できること() {
        let memoRepository = MemoRepositoryMock()
        memoRepository.dummyMemos.append(contentsOf: [MemoMock(),
                                                      MemoMock(),
                                                      MemoMock(),
                                                      MemoMock()])
        /*
         以下の手順で網羅確認
         1 非編集時にボタンタップ（スルー）
         2 編集モードにする
         3 ボタンタップ
         4 アラート表示
         5 キャンセルタップ
         6 ボタンタップ
         7 アラート表示
         8 全削除
         */
        let tableViewEditing = scheduler.createHotObservable([.next(1, false),
                                                              .next(3, true)])
            .asDriver(onErrorDriveWith: Driver.empty())

        let tappedUnderRightButton = scheduler.createHotObservable([.next(2, ()),
                                                                    .next(4, ()),
                                                                    .next(6, ())])
            .asSignal(onErrorSignalWith: Signal.empty())

        let showActionSheet = scheduler.createHotObservable([.next(5, AlertEvent(style: .cancel, actionType: .cancel)),
                                                             .next(7, AlertEvent(style: .destructive, actionType: .allDelete))])
            .asDriver(onErrorDriveWith: Driver.empty())

        let viewModelOutput = MemoListViewModel()
            .injection(input: MemoListViewModel.Input(memoRepository: memoRepository,
                                                      viewWillAppear: Observable.empty(),
                                                      tableViewEditing: tableViewEditing,
                                                      tappedUnderRightButton: tappedUnderRightButton,
                                                      deleteMemoAction: Driver.just(""),
                                                      showActionSheet: showActionSheet,
                                                      didSaveMemo: Observable.just(Notification(name: .NSManagedObjectContextDidSave))))
        viewModelOutput.updateMemoList
            .skip(1)
            .drive(onNext: { memoList in
                XCTAssertEqual(memoList.count, 0)
            })
            .disposed(by: disposeBag)

        viewModelOutput.updateMemosAtDeleteAllMemo
            .drive(onNext: { _ in
                XCTAssertTrue(true)
            })
            .disposed(by: disposeBag)

        scheduler.start()
    }

    func test_updateMemosAtDeleteMemo_メモの個別削除時のイベントを購読できること() {
        let memoRepository = MemoRepositoryMock()
        let dummyUniqueId1 = "1000"
        let dummyUniqueId2 = "2000"
        memoRepository.dummyMemos.append(contentsOf: [MemoMock(uniqueId: dummyUniqueId1), MemoMock(uniqueId: dummyUniqueId2)])
        let deleteMemoAction = scheduler.createHotObservable([.next(1, dummyUniqueId1)]).asDriver(onErrorDriveWith: Driver.empty())
        let viewModelOutput = MemoListViewModel()
            .injection(input: MemoListViewModel.Input(memoRepository: memoRepository,
                                                      viewWillAppear: Observable.empty(),
                                                      tableViewEditing: Driver.just(false),
                                                      tappedUnderRightButton: Signal.just(()),
                                                      deleteMemoAction: deleteMemoAction,
                                                      showActionSheet: Driver.just(.init(style: .default, actionType: .cancel)),
                                                      didSaveMemo: Observable.just(Notification(name: .NSManagedObjectContextDidSave))))

        viewModelOutput.updateMemoList
            .skip(1)
            .drive(onNext: { memoList in
                XCTAssertEqual(memoList.count, 1)
                XCTAssertEqual(memoList.first!.uniqueId, dummyUniqueId2)
            })
            .disposed(by: disposeBag)

        viewModelOutput.updateMemosAtDeleteMemo
            .drive(onNext: { _ in
                XCTAssertTrue(true)
            })
            .disposed(by: disposeBag)

        scheduler.start()
    }

    func test_transitionCreateMemo_新規作成画面への遷移イベントを購読できること() {
        let memoRepository = MemoRepositoryMock()
        memoRepository.dummyMemos.append(contentsOf: [MemoMock(),
                                                      MemoMock(),
                                                      MemoMock(),
                                                      MemoMock()])

        let tableViewEditing = scheduler.createHotObservable([.next(1, true),
                                                              .next(4, false)])
            .asDriver(onErrorDriveWith: Driver.empty())

        let tappedUnderRightButton = scheduler.createHotObservable([.next(2, ()),
                                                                    .next(5, ())])
            .asSignal(onErrorSignalWith: Signal.empty())

        let showActionSheet = scheduler.createHotObservable([.next(3, AlertEvent(style: .cancel, actionType: .cancel))])
            .asDriver(onErrorDriveWith: Driver.empty())

        let viewModelOutput = MemoListViewModel()
            .injection(input: MemoListViewModel.Input(memoRepository: memoRepository,
                                                      viewWillAppear: Observable.empty(),
                                                      tableViewEditing: tableViewEditing,
                                                      tappedUnderRightButton: tappedUnderRightButton,
                                                      deleteMemoAction: Driver.just(""),
                                                      showActionSheet: showActionSheet,
                                                      didSaveMemo: Observable.just(Notification(name: .NSManagedObjectContextDidSave))))
        viewModelOutput.updateMemoList
            .skip(1)
            .drive(onNext: { memoList in
                XCTAssertEqual(memoList.count, 4)
            })
            .disposed(by: disposeBag)

        viewModelOutput.transitionCreateMemo
            .drive(onNext: { _ in
                XCTAssertTrue(true)
            })
            .disposed(by: disposeBag)

        scheduler.start()
    }

    func test_updateButtonTitle_ボタンタイトルの更新イベントを購読できること() {
        let memoRepository = MemoRepositoryMock()
        let tableViewEditing = scheduler.createHotObservable([.next(1, true),
                                                              .next(2, false),
                                                              .next(3, true)])
            .asDriver(onErrorDriveWith: Driver.empty())


        let viewModelOutput = MemoListViewModel()
            .injection(input: MemoListViewModel.Input(memoRepository: memoRepository,
                                                      viewWillAppear: Observable.empty(),
                                                      tableViewEditing: tableViewEditing,
                                                      tappedUnderRightButton: Signal.just(()),
                                                      deleteMemoAction: Driver.just(""),
                                                      showActionSheet: Driver.just(.init(style: .default, actionType: .cancel)),
                                                      didSaveMemo: Observable.just(Notification(name: .NSManagedObjectContextDidSave))))

        // 購読結果の蓄積用オブザーバー
        let observer = scheduler.createObserver(String.self)

        viewModelOutput.updateButtonTitle
            .drive(observer)
            .disposed(by: disposeBag)

        let expectedEvents = [
            Recorded.next(1, "全て削除"), // tableViewEditingにtureを流したらくるはずのタイトル
            Recorded.next(2, "メモ追加"), // tableViewEditingにfalseを流したらくるはずのタイトル
            Recorded.next(3, "全て削除")  // tableViewEditingにtureを流したらくるはずのタイトル
        ]

        scheduler.start()

        // 完了後に評価
        XCTAssertEqual(expectedEvents, observer.events)
    }

    func test_シナリオテスト_メモ5件作成_全削除_2件作成_1件目削除() {
        let memoRepository = MemoRepositoryMock()
        memoRepository.dummyMemos = (0..<5).map { MemoMock(uniqueId: "\($0)") }
        let dummyUniqueId1 = "1000"
        let dummyUniqueId2 = "2000"

        let viewWillAppear: Observable<[Any]> = scheduler.createColdObservable([.next(0, [()])]).asObservable()
        let tableViewEditing = scheduler.createHotObservable([.next(1, true),
                                                              .next(5, false),
                                                              .next(6, true)])
            .asDriver(onErrorDriveWith: Driver.empty())
        let tappedUnderRightButton = scheduler.createHotObservable([.next(2, ())]).asSignal(onErrorSignalWith: Signal.empty())
        let showActionSheet = scheduler.createHotObservable([.next(3, AlertEvent(style: .destructive, actionType: .allDelete))]).asDriver(onErrorDriveWith: Driver.empty())
        let didSaveMemo = scheduler.createColdObservable([.next(4, Notification(name: .NSManagedObjectContextDidSave))]).asObservable()
        let deleteMemoAction = scheduler.createHotObservable([.next(7, dummyUniqueId1)]).asDriver(onErrorDriveWith: Driver.empty())
        let viewModelOutput = MemoListViewModel()
        .injection(input: MemoListViewModel.Input(memoRepository: memoRepository,
                                                  viewWillAppear: viewWillAppear,
                                                  tableViewEditing: tableViewEditing,
                                                  tappedUnderRightButton: tappedUnderRightButton,
                                                  deleteMemoAction: deleteMemoAction,
                                                  showActionSheet: showActionSheet,
                                                  didSaveMemo: didSaveMemo))

        let memosObserver = scheduler.createObserver([Memo].self)
        viewModelOutput.updateMemoList
                   .skip(1)
                   .drive(memosObserver)
                   .disposed(by: disposeBag)

        viewModelOutput.updateMemosAtWillAppear
            .drive()
            .disposed(by: disposeBag)

        viewModelOutput.updateMemosAtCompleteSaveMemo
            .drive(onNext: {
                XCTAssertEqual(memoRepository.dummyMemos.count, 0)
                memoRepository.dummyMemos = [MemoMock(uniqueId: dummyUniqueId1),
                                             MemoMock(uniqueId: dummyUniqueId2)]
            })
            .disposed(by: disposeBag)

        viewModelOutput.updateMemosAtDeleteAllMemo
            .drive()
            .disposed(by: disposeBag)

        viewModelOutput.updateMemosAtDeleteMemo
            .drive()
            .disposed(by: disposeBag)

        viewModelOutput.transitionCreateMemo
        .drive(onNext: {
            XCTFail("呼ばれない想定")
        })
        .disposed(by: disposeBag)

        scheduler.start()

        let expectedEvents: [Recorded<Event<[Memo]>>] = [
            Recorded.next(0, [MemoMock(uniqueId: "0"),
                              MemoMock(uniqueId: "1"),
                              MemoMock(uniqueId: "2"),
                              MemoMock(uniqueId: "3"),
                              MemoMock(uniqueId: "4")]),
            Recorded.next(3, []),
            Recorded.next(4, []),
            Recorded.next(7, [MemoMock(uniqueId: dummyUniqueId2)])
        ]

        // メモリストの個数の推移を購読した結果：[5, 0, 0, 1]
        XCTAssertEqual(memosObserver.events.compactMap { $0.value.element?.count },
                       expectedEvents.compactMap { $0.value.element?.count })

        // メモリストの中身(uniqueId)の推移を購読した結果：[["0", "1", "2", "3", "4"], [], [], ["2000"]]
        XCTAssertEqual(memosObserver.events.compactMap { $0.value.element?.compactMap { $0.uniqueId } },
                       expectedEvents.compactMap { $0.value.element?.compactMap { $0.uniqueId } })
    }
}
