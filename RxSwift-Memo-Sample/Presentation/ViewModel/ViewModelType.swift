//
//  ViewModelType.swift
//  RxSwift-Memo-Sample
//
//  Created by kawaharadai on 2019/12/08.
//  Copyright © 2019 kawaharadai. All rights reserved.
//

protocol ViewModelType {
    associatedtype Input
    associatedtype Output

    func injection(input: Input) -> Output
}
