//
//  CoreDataError.swift
//  RxSwift-Memo-Sample
//
//  Created by kawaharadai on 2020/03/04.
//  Copyright © 2020 kawaharadai. All rights reserved.
//

enum CoreDataError: Error {
    case failedCreateEntity
    case failedGetManagedObject
    case failedPrepareRequest
    case failedFetchRequest
    case failedExecuteStoreRequest
    case notFoundContext
    case failedFetchMemoById
}
