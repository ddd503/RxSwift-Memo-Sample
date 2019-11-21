//
//  MemoListViewModel.swift
//  RxSwift-Memo-Sample
//
//  Created by kawaharadai on 2019/10/17.
//  Copyright © 2019 kawaharadai. All rights reserved.
//

import RxCocoa
import RxSwift

class MemoListViewModel {
    private var disposeBag = DisposeBag()
    var memos = BehaviorRelay<[Memo]>(value: [])
    let countLabelText: Driver<String>
    let showDeleteActionSheet = PublishRelay<Void>()
    let transitionAddMemoVC = PublishRelay<Void>()
    
    init(isEditing: Observable<Bool>, tapAddButton: Signal<()>) {
        countLabelText = memos.asObservable()
            .flatMap({ (memos) -> Observable<String> in
                let text = memos.isEmpty ? "メモなし" : "\(memos.count)件のメモ"
                return Observable.of(text)
            })
            .asDriver(onErrorJustReturn: "メモなし")
        
        let tapAction = Observable.combineLatest(tapAddButton.asObservable(), isEditing)
        tapAction.subscribe(onNext: { _, isEditing in
            isEditing ? self.showDeleteActionSheet.accept(()) : self.transitionAddMemoVC.accept(())
        })
            .disposed(by: disposeBag)
    }
}
