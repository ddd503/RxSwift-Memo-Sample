//
//  UIView+Layout.swift
//  RxSwift-Memo-Sample
//
//  Created by kawaharadai on 2019/11/27.
//  Copyright © 2019 kawaharadai. All rights reserved.
//

import UIKit

extension UIView {
    /// 自身の表示位置を上or下にアニメーションさせて変更する
    ///
    /// - Parameters:
    ///   - isTransform: trueの場合上に移動、falseの場合、元の位置に戻る
    ///   - moveValue: 移動させる長さ
    ///   - duration: 移動アニメーションの実行時間
    ///   - curve: アニメーションカーブ
    ///   - shouldOverwrite: すでにtransformが設定されていた時に上書きするか
    func moveUpTransformIfNeeded(isTransform: Bool, moveValue: CGFloat = 0, duration: TimeInterval = 0.3,
                                 delay: TimeInterval = 0, curve: AnimationCurve? = nil, shouldOverwrite: Bool = false) {

        let curve = curve ?? .easeIn

        if isTransform {
            if !shouldOverwrite {
                // 上書きを許可しない場合は、すでに変形済みならリターン（デフォルトでは上書きを許可していない）
                guard transform.isIdentity else { return }
            }
            let transform = CGAffineTransform(translationX: 0, y: -moveValue)
            let animator = UIViewPropertyAnimator(duration: duration, curve: curve) { [weak self] in
                self?.transform = transform
            }
            animator.startAnimation(afterDelay: delay)
        } else {
            guard !transform.isIdentity else { return }
            let animator = UIViewPropertyAnimator(duration: duration, curve: curve) { [weak self] in
                self?.transform = .identity
            }
            animator.startAnimation(afterDelay: delay)
        }
    }
}
