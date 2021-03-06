//
//  MemoInfoCell.swift
//  RxSwift-Memo-Sample
//
//  Created by kawaharadai on 2019/11/20.
//  Copyright © 2019 kawaharadai. All rights reserved.
//

import UIKit

class MemoInfoCell: UITableViewCell {

    @IBOutlet weak private var titleLabel: UILabel!
    @IBOutlet weak private var contentLabel: UILabel!
    @IBOutlet weak private var dateLabel: UILabel!

    static var identifier: String {
        return String(describing: self)
    }

    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: .main)
    }

    func setInfo(memo: Memo) {
        titleLabel.text = memo.title
        contentLabel.text = memo.content
        guard let editDate = memo.editDate else { return }
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.dateFormat = "yyyy/MM/dd  HH:mm"
        dateLabel.text = dateFormatter.string(from: editDate)
    }
}
