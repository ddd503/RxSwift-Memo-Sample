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
            tableView.delegate = self
            tableView.register(MemoInfoCell.nib(), forCellReuseIdentifier: MemoInfoCell.identifier)
            tableView.tableFooterView = UIView()
        }
    }

    private var viewModel: MemoListViewModel!
    private var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = editButtonItem
        viewModel = MemoListViewModel(memoDataStore: MemoDataStoreNewImpl())
        bind()
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        updateDisplay(at: editing)
    }

    private func bind() {
        viewModel.memos
            .asObservable()
            .bind(to: tableView.rx.items(cellIdentifier: MemoInfoCell.identifier,
                                         cellType: MemoInfoCell.self)) { (row, element, cell) in
                                            cell.setInfo(memo: element)
        }
        .disposed(by: disposeBag)

        viewModel.countLabelText
            .drive(countLabel.rx.text)
            .disposed(by: disposeBag)

        tableView.rx
            .modelSelected(Memo.self)
            .subscribe(onNext: { [weak self] memoInfo in
                self?.transitionDetailMemoVC(memoInfo: memoInfo)
            })
            .disposed(by: disposeBag)

        addButton.rx
            .tap
            .subscribe { [weak self] (_) in
                if let self = self {
                    self.tableView.isEditing ? self.showAllDeleteActionSheet() : self.transitionDetailMemoVC(memoInfo: nil)
                }
        }
        .disposed(by: disposeBag)
    }

    // Private

    private func updateDisplay(at isEditing: Bool) {
        tableView.isEditing = isEditing
        addButton.setTitle(isEditing ? "全て削除" : "メモ追加", for: .normal)
    }

    private func transitionDetailMemoVC(memoInfo: Memo?) {
        print("メモ作成画面へ遷移")
    }

    private func showAllDeleteActionSheet() {
        let allDelete = ObservableAlertAction(title: "すべて削除", style: .destructive) { [weak self] in
            guard let self = self else { return }
            self.viewModel.deleteAllMemo
                .catchError({ (error) -> Observable<()> in
                    print(error.localizedDescription)
                    return Observable.empty() // エラーがあっても完了まで流す
                })
                .subscribe(onCompleted: {
                    self.setEditing(false, animated: true)
                })
                .disposed(by: self.disposeBag)
        }

        let cancel = ObservableAlertAction(title: "キャンセル", style: .cancel, task: nil)
        showAlertView(title: nil, message: nil, style: .actionSheet, actions: [allDelete, cancel])
    }

    private func showAlertView(title: String? = nil, message: String? = nil,
                           style: UIAlertController.Style, actions: [ObservableAlertAction]) {
        showAlert(title: nil, message: nil, style: style, actions: actions)
            .subscribe(onNext: { action in
                action.task?()
            })
            .disposed(by: disposeBag)
    }

}
