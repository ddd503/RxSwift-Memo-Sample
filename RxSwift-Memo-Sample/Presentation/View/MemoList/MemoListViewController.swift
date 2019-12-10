//
//  MemoListViewController.swift
//  RxSwift-Memo-Sample
//
//  Created by kawaharadai on 2019/10/16.
//  Copyright © 2019 kawaharadai. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class MemoListViewController: UIViewController, UITableViewDelegate {

    @IBOutlet weak private var addButton: UIButton!
    @IBOutlet weak private var countLabel: UILabel!
    @IBOutlet weak private var tableView: UITableView! {
        didSet {
            tableView.register(MemoInfoCell.nib(), forCellReuseIdentifier: MemoInfoCell.identifier)
            tableView.tableFooterView = UIView()
        }
    }
    private var memos = BehaviorRelay<[Memo]>(value: [])
    private var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = editButtonItem

        // bind

        let viewModelOutput = MemoListViewModel()
            .injection(input: MemoListViewModel.Input(memosCount: Driver.just(memos.value.count),
                                                      memoDataStore: MemoDataStoreNewImpl(),
                                                      addButtonTap: addButton.rx.tap.asSignal(),
                                                      isEditing: tableView.rx_isEditing.asDriver(onErrorJustReturn: false)))

        viewModelOutput.didChangeMemoCount
            .drive(countLabel.rx.text)
            .disposed(by: disposeBag)

        viewModelOutput.showAllDeleteAlert
            .emit(onNext: { [weak self] (_) in
                guard let self = self else { return }
                let allDelete =
                    ObservableAlertAction(title: "すべて削除",
                                          style: .destructive) {
                                            viewModelOutput.deleteAllMemo
                                                .emit(onNext: {
                                                    print("メモ全削除")
                                                })
                                                .disposed(by: self.disposeBag)
                }
                let cancel =
                    ObservableAlertAction(title: "キャンセル",
                                          style: .cancel, task: nil)

                self.showAlert(title: nil, message: nil,
                               style: .actionSheet, actions: [allDelete, cancel])
                    .subscribe(onNext: { action in
                        action.task?()
                    })
                    .disposed(by: self.disposeBag)
            })
            .disposed(by: disposeBag)

        memos
            .bind(to: tableView.rx.items(cellIdentifier: MemoInfoCell.identifier,
                                         cellType: MemoInfoCell.self)) { (row, element, cell) in
                                            cell.setInfo(memo: element)
        }
        .disposed(by: disposeBag)

        tableView.rx
            .modelSelected(Memo.self)
            .subscribe(onNext: { [weak self] memo in
                self?.transitionDetailMemoVC(memo: memo)
            })
            .disposed(by: disposeBag)
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        updateDisplay(at: editing)
    }

    private func updateDisplay(at isEditing: Bool) {
        tableView.isEditing = isEditing
        addButton.setTitle(isEditing ? "全て削除" : "メモ追加", for: .normal)
    }

    private func transitionDetailMemoVC(memo: Memo?) {
        let memoDetailVC = MemoDetailViewController(memo: memo)
        navigationController?.pushViewController(memoDetailVC, animated: true)
    }
}

extension UITableView {
    var rx_isEditing: Observable<Bool> {
        return Observable<Bool>.create { (observer) in
            observer.onNext(self.isEditing)
            observer.onCompleted()
            return Disposables.create()
        }
    }
}
