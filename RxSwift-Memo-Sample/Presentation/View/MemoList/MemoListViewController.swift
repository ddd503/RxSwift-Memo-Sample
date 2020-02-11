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
    
    @IBOutlet weak private var underRightButton: UIButton!
    @IBOutlet weak private var countLabel: UILabel!
    @IBOutlet weak private var tableView: UITableView! {
        didSet {
            tableView.register(MemoInfoCell.nib(), forCellReuseIdentifier: MemoInfoCell.identifier)
            tableView.tableFooterView = UIView()
        }
    }
    private let viewModel = MemoListViewModel()
    private var tableViewEditing = BehaviorRelay<Bool>(value: false)
    private var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = editButtonItem
        
        let viewModelOutput =
            viewModel.injection(input: MemoListViewModel.Input(memoDataStore: MemoDataStoreImpl(),
                                                               tableViewEditing: tableViewEditing.asDriver(onErrorDriveWith: Driver.never()),
                                                               tappedUnderRightButton: underRightButton.rx.tap.asSignal()))
        // メモリストの取得
        viewModelOutput.updateMemosAtStartUp
            .drive(onNext: { [weak self] in
                self?.tableView.reloadData()
            })
            .disposed(by: disposeBag)

        // メモ保存完了通知
        viewModelOutput.updateMemosAtCompleteSaveMemo
            .drive(onNext: { [weak self]  in
                self?.tableView.reloadData()
            })
            .disposed(by: disposeBag)

        // 新規作成画面へ遷移
        viewModelOutput.transitionCreateMemo
            .drive(onNext: { [weak self] in
                self?.transitionDetailMemoVC()
            })
            .disposed(by: disposeBag)

        // メモ数表示の更新
        viewModelOutput.updateMemoCount
            .drive(onNext: { [weak self] memoCount in
                self?.countLabel.text = (memoCount > 0) ? "\(memoCount)件のメモ" : "メモなし"
            })
            .disposed(by: disposeBag)

        // ボタンタイトルの更新
        viewModelOutput.updateButtonTitle
            .drive(onNext: { [weak self] buttonTitle in
                self?.underRightButton.setTitle(buttonTitle, for: .normal)
            })
            .disposed(by: disposeBag)

        // 全削除アラートを出す
        viewModelOutput.showAllDeleteAlert
            .drive(onNext: { [weak self] (_) in
                guard let self = self else { return }
                let allDelete = ObservableAlertAction(title: "すべて削除",
                                                      style: .destructive) {
                                                        viewModelOutput.updateMemosAtDeleteAllMemo
                                                            .drive(onNext: { [weak self]  in
                                                                // アニメーション入れるならIndexPathで更新かける
                                                                self?.tableView.reloadData()
                                                            })
                                                            .disposed(by: self.disposeBag)
                }
                let cancel = ObservableAlertAction(title: "キャンセル",
                                                   style: .cancel, task: nil)

                self.showAlert(title: nil, message: nil,
                               style: .actionSheet, actions: [allDelete, cancel])
                    .subscribe(onNext: { action in
                        action.task?()
                    })
                    .disposed(by: self.disposeBag)
            })
            .disposed(by: disposeBag)

        // TableViewDataSource
        viewModelOutput.listDataSource
            .bind(to: tableView.rx.items(cellIdentifier: MemoInfoCell.identifier,
                                         cellType: MemoInfoCell.self)) { (row, element, cell) in
                                            cell.setInfo(memo: element)
        }
        .disposed(by: disposeBag)

        // TableView didSelect Item (新規作成画面へ遷移)
        tableView.rx.modelSelected(Memo.self)
            .subscribe(onNext: { [weak self] memo in
                self?.transitionDetailMemoVC(memo: memo)
            })
            .disposed(by: disposeBag)
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.isEditing = isEditing
        tableViewEditing.accept(editing)
    }

    /// メモ作成画面　or メモ編集画面に遷移（Memoを渡した場合はその情報を基に詳細画面を開き、渡さない場合は新規作成画面を開く）
    /// - Parameter memo: Memo
    private func transitionDetailMemoVC(memo: Memo? = nil) {
        let memoDetailVC = MemoDetailViewController(memo: memo)
        navigationController?.pushViewController(memoDetailVC, animated: true)
    }
}
