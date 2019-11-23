//
//  UIViewController+Alert.swift
//  RxSwift-Memo-Sample
//
//  Created by kawaharadai on 2019/11/23.
//  Copyright © 2019 kawaharadai. All rights reserved.
//

import UIKit
import RxSwift

struct ObservableAlertAction {
    let title: String?
    let message: String?
    let style: UIAlertAction.Style
    let task: (() -> ())?

    init(title: String? = nil, message: String? = nil, style: UIAlertAction.Style, task: (() -> ())? = nil) {
        self.title = title
        self.message = message
        self.style = style
        self.task = task
    }
}

extension UIViewController {
    func showAlert(title: String? = nil, message: String? = nil,
                   style: UIAlertController.Style, actions: [ObservableAlertAction]) -> Observable<ObservableAlertAction> {
        return Observable.create { (observer) -> Disposable in
            let alert = UIAlertController(title: title, message: message, preferredStyle: style)
            actions.forEach { (action) in
                // 購読用のアクションに詰め直し
                let observerAction = UIAlertAction(title: action.title, style: action.style) { (_) in
                    observer.onNext(action) // タップに紐付いたObservableAlertActionをストリームに流す
                    observer.onCompleted()
                }
                alert.addAction(observerAction)
            }

            // アラート表示
            self.present(alert, animated: true)

            // 破棄されるタイミング(onCompleted時)にアラートを閉じる
            return Disposables.create { alert.dismiss(animated: true, completion: nil) }
        }
    }
}
