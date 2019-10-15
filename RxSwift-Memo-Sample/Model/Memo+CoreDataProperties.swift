//
//  Memo+CoreDataProperties.swift
//  RxSwift-Memo-Sample
//
//  Created by kawaharadai on 2019/10/16.
//  Copyright © 2019 kawaharadai. All rights reserved.
//
//

import Foundation
import CoreData


extension Memo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Memo> {
        return NSFetchRequest<Memo>(entityName: "Memo")
    }

    @NSManaged public var uniqueId: String?
    @NSManaged public var title: String?
    @NSManaged public var content: String?
    @NSManaged public var editDate: Date?

}
