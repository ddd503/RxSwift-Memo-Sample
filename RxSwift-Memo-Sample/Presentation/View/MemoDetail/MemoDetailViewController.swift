//
//  MemoDetailViewController.swift
//  RxSwift-Memo-Sample
//
//  Created by kawaharadai on 2019/11/24.
//  Copyright © 2019 kawaharadai. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class MemoDetailViewController: UIViewController {

    @IBOutlet weak private var textView: UITextView!
    private let viewModel: MemoDetailViewModel
    private var doneButtonItem: UIBarButtonItem!
    private var disposeBag = DisposeBag()

    init(viewModel: MemoDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: String(describing: MemoDetailViewController.self), bundle: .main)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        doneButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: nil)
        navigationItem.rightBarButtonItem = doneButtonItem
        textView.becomeFirstResponder()

        let viewModelOutput =
            viewModel.injection(input: MemoDetailViewModel.Input(memoRepository: MemoRepositoryImpl(memoDataStore: MemoDataStoreImpl()),
                                                                 tappedDoneButton: doneButtonItem.rx.tap.asSignal(),
                                                                 textViewText: textView.rx.text.orEmpty.asDriver(),
                                                                 didSaveMemo: NotificationCenter.default.rx.notification(.NSManagedObjectContextDidSave)))

        viewModelOutput.setupText
            .drive(onNext: { [weak self] text in
                self?.textView.text = text
            })
            .disposed(by: disposeBag)

        viewModelOutput.saveMemoText
            .drive()
            .disposed(by: disposeBag)

        viewModelOutput.returnMemoList
            .drive(onNext: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)

        // TextViewに文字が入力されていない時はDoneボタンを非活性にする
        textView.rx.text
            .orEmpty
            .asObservable()
            .bind(to: doneButtonItem.rx.isEnableEmpty)
            .disposed(by: disposeBag)
    }
}
