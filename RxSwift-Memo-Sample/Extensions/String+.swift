//
//  String+.swift
//  RxSwift-Memo-Sample
//
//  Created by kawaharadai on 2019/11/26.
//  Copyright © 2019 kawaharadai. All rights reserved.
//

import Foundation

extension String {
    /// 1行目のテキスト
    var firstLine: String {
        let lines = components(separatedBy: "\n")
        return lines.first ?? ""
    }

    /// 2行目以降のテキスト
    var afterSecondLine: String {
        var lines = components(separatedBy: "\n")
        guard lines.count > 1 else { return "" }
        // 1行目を削除
        lines.remove(at: 0)
        var text = lines.joined(separator: "\n")
        // 文末の改行を削除する
        text.removeLastIfNeeded(character: "\n", index: 1)
        return text
    }

    /// 特定の文字列が語尾の場合に文末を削除する
    ///
    /// - Parameters:
    ///   - character: この文字が語尾なら文末から文字列を削除する
    ///   - index: 文末から何文字削除するか
    mutating func removeLastIfNeeded(character: Character, index: Int) {
        guard let lastCharacter = self.last, lastCharacter == character else { return }
        removeLast(index)
    }
}
