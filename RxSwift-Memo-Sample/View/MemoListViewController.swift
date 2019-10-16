//
//  MemoListViewController.swift
//  RxSwift-Memo-Sample
//
//  Created by kawaharadai on 2019/10/16.
//  Copyright © 2019 kawaharadai. All rights reserved.
//

import UIKit
import RxSwift

final class MemoListViewController: UIViewController {

    private lazy var viewModel = MemoListViewModel()
    private var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
    }

    private func bind() {
        // ViewModel側のObservableプロパティとデータバインディングする(主に描画処理に関するoutput)
    }
}
