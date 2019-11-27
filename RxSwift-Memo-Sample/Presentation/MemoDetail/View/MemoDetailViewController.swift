//
//  MemoDetailViewController.swift
//  RxSwift-Memo-Sample
//
//  Created by kawaharadai on 2019/11/24.
//  Copyright © 2019 kawaharadai. All rights reserved.
//

import UIKit
import RxSwift

class MemoDetailViewController: UIViewController {

    @IBOutlet weak private var textView: UITextView!
    private var doneButtonItem: UIBarButtonItem!
    private let memo: Memo?
    private var disposeBag = DisposeBag()

    init(memo: Memo?) {
        self.memo = memo
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

        // bind

        let viewModel = MemoDetailViewModel(memo: memo,
                                            textViewText: textView.rx.text.orEmpty.asDriver(),
                                            memoDataStore: MemoDataStoreNewImpl(),
                                            tappedDone: doneButtonItem.rx.tap.asSignal())

        viewModel.startSaveMemo
            .drive(onNext: { memo in
                print("変更があったメモ: \(memo)")
            })
            .disposed(by: disposeBag)

        viewModel.completeSaveMemo
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] notification in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
    }

}
