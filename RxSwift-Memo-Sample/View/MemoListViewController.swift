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
        viewModel = MemoListViewModel()
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
        print("削除アクションシートを表示")
    }

}
