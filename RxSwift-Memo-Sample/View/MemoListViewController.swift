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

    @IBOutlet weak private var editButton: UIBarButtonItem!
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
        viewModel = MemoListViewModel(isEditing: isEditingObservable,
                                      tapAddButton: addButton.rx.tap.asSignal())
        bind()
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
        tableView.rx.modelSelected(Memo.self).subscribe(onNext: { memo in
            // TODO: メモ詳細をDIで作成 → 画面遷移
        })
            .disposed(by: disposeBag)

        viewModel.showDeleteActionSheet
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { _ in
                print("アクションシート表示")
            })
            .disposed(by: disposeBag)

        viewModel.transitionAddMemoVC
        .observeOn(MainScheduler.asyncInstance)
        .subscribe(onNext: { _ in
            print("メモ追加画面へ遷移")
        })
        .disposed(by: disposeBag)
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.isEditing = editing
    }

}

extension UIViewController {
    var isEditingObservable: Observable<Bool> {
        return Observable.of(self.isEditing)
    }
}
