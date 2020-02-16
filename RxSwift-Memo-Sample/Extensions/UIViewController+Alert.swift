//
//  UIViewController+Alert.swift
//  RxSwift-Memo-Sample
//
//  Created by kawaharadai on 2019/11/23.
//  Copyright © 2019 kawaharadai. All rights reserved.
//

import UIKit
import RxSwift

// アラート表示、タップ時のアクションまでに関する情報まとめ用
struct AlertEvent {
    let title: String?
    let message: String?
    let style: UIAlertAction.Style
    let actionType: AlertActionType

    init(title: String? = nil, message: String? = nil, style: UIAlertAction.Style, actionType: AlertActionType) {
        self.title = title
        self.message = message
        self.style = style
        self.actionType = actionType
    }
}

// アラートタップ時のアクション種別
enum AlertActionType {
    case allDelete
    case cancel

    var event: AlertEvent {
        switch self {
        case .allDelete:
            return AlertEvent(title: "すべて削除", style: .destructive, actionType: .allDelete)
        case .cancel:
            return AlertEvent(title: "キャンセル", style: .cancel, actionType: .cancel)
        }
    }
}

extension UIViewController {
    func showAlertObservable(title: String? = nil, message: String? = nil,
                             style: UIAlertController.Style, actions: [AlertEvent]) -> Observable<AlertEvent> {
        return Observable.create { (observer) -> Disposable in
            let alert = UIAlertController(title: title, message: message, preferredStyle: style)
            actions.forEach { (event) in
                // 購読用のアクションに詰め直し
                let observerAction = UIAlertAction(title: event.title, style: event.style) { (_) in
                    observer.onNext(event) // タップに紐付いたObservableAlertActionをストリームに流す
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
