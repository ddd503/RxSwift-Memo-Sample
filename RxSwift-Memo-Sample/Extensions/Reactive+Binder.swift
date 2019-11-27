//
//  Reactive+Binder.swift
//  RxSwift-Memo-Sample
//
//  Created by kawaharadai on 2019/11/27.
//  Copyright © 2019 kawaharadai. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension Reactive where Base: UIBarButtonItem {
    var isEnableEmpty: Binder<String> {
        return Binder(base) { buttonItem, string in
            // 空文字の時は非活性にする
            buttonItem.isEnabled = !string.isEmpty
        }
    }
}
