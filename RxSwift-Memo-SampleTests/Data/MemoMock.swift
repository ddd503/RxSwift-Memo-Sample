//
//  MemoMock.swift
//  RxSwift-Memo-SampleTests
//
//  Created by kawaharadai on 2020/02/16.
//  Copyright © 2020 kawaharadai. All rights reserved.
//

import Foundation
@testable import RxSwift_Memo_Sample

class MemoMock: Memo {
    var id = ""
    var titleText: String = ""
    var contentText: String = ""
    var editMemoDate: Date?

    convenience init(uniqueId: String = "", title: String = "",
                     content: String = "", editDate: Date = Date()) {
        self.init()
        self.id = uniqueId
        self.titleText = title
        self.contentText = content
        self.editMemoDate = editDate
    }

    override var uniqueId: String? {
        set {}
        get { return self.id }
    }

    override var title: String? {
        set {}
        get { return self.titleText }
    }

    override var content: String? {
        set {}
        get { return self.contentText }
    }

    override var editDate: Date? {
        set {}
        get { return self.editMemoDate }
    }
}
