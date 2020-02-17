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
    @IBOutlet weak private var emptyLabel: UILabel!
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

        let showActionSheet = showAlertObservable(title: nil, message: nil,
                                                  style: .actionSheet,
                                                  actions: [AlertActionType.allDelete.event,
                                                            AlertActionType.cancel.event])
            .asDriver(onErrorDriveWith: Driver.never())

        let viewModelOutput =
            viewModel.injection(input: MemoListViewModel.Input(memoRepository: MemoRepositoryImpl(memoDataStore: MemoDataStoreImpl()),
                                                               tableViewEditing: tableViewEditing.asDriver(onErrorDriveWith: Driver.empty()),
                                                               tappedUnderRightButton: underRightButton.rx.tap.asSignal(),
                                                               deleteMemoAction: tableView.rx.modelDeleted(Memo.self).compactMap { $0.uniqueId }.asDriver(onErrorDriveWith: Driver.empty()),
                                                               showActionSheet: showActionSheet,
                                                               didSaveMemo: NotificationCenter.default.rx
                                                                .notification(.NSManagedObjectContextDidSave)))
        viewModelOutput.updateMemoList
            .drive(onNext: { [weak self] memos in
                self?.tableView.reloadData()
                self?.countLabel.text = memos.isEmpty ? "メモなし" : "\(memos.count)件のメモ"
                self?.emptyLabel.isHidden = !memos.isEmpty
                if memos.isEmpty {
                    self?.setEditing(false, animated: true)
                }
            })
            .disposed(by: disposeBag)

        viewModelOutput.updateMemosAtStartUp
            .drive()
            .disposed(by: disposeBag)

        viewModelOutput.updateMemosAtCompleteSaveMemo
            .drive()
            .disposed(by: disposeBag)

        viewModelOutput.updateMemosAtDeleteAllMemo
            .drive()
            .disposed(by: disposeBag)

        viewModelOutput.updateMemosAtDeleteMemo
            .drive()
            .disposed(by: disposeBag)

        viewModelOutput.transitionCreateMemo
            .drive(onNext: { [weak self] in
                self?.transitionDetailMemoVC()
            })
            .disposed(by: disposeBag)

        viewModelOutput.updateButtonTitle
            .drive(onNext: { [weak self] buttonTitle in
                self?.underRightButton.setTitle(buttonTitle, for: .normal)
            })
            .disposed(by: disposeBag)

        viewModelOutput.listDataSource
            .bind(to: tableView.rx.items(cellIdentifier: MemoInfoCell.identifier,
                                         cellType: MemoInfoCell.self)) { (row, element, cell) in
                                            cell.setInfo(memo: element)
        }
        .disposed(by: disposeBag)

        /// テーブルビューのセルタップ時
        tableView.rx.modelSelected(Memo.self)
            .subscribe(onNext: { [weak self] memo in
                self?.transitionDetailMemoVC(memo: memo)
            })
            .disposed(by: disposeBag)

        /// テーブルビューの編集モード切り替え時
        tableViewEditing.asDriver()
            .drive(onNext: { [weak self] isEditing in
                self?.tableView.isEditing = isEditing
            })
            .disposed(by: disposeBag)

        /// 画面遷移後
        navigationController?.rx
            .didShow
            .subscribe({ [weak self] (_) in
                guard let self = self else { return }
                if let indexPathForSelectedRow = self.tableView.indexPathForSelectedRow {
                    self.tableView.deselectRow(at: indexPathForSelectedRow, animated: true)
                }
            })
            .disposed(by: disposeBag)
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableViewEditing.accept(editing)
    }

    /// メモ作成画面　or メモ編集画面に遷移（Memoを渡した場合はその情報を基に詳細画面を開き、渡さない場合は新規作成画面を開く）
    /// - Parameter memo: Memo
    private func transitionDetailMemoVC(memo: Memo? = nil) {
        let memoDetailVC = MemoDetailViewController(viewModel: MemoDetailViewModel(memo: memo))
        navigationController?.pushViewController(memoDetailVC, animated: true)
    }
}
