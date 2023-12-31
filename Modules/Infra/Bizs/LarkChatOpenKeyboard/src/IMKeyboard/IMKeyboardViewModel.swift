//
//  IMKeyboardViewModel.swift
//  LarkBaseKeyboard
//
//  Created by liluobin on 2023/3/19.
//

import UIKit
import LarkOpenKeyboard
import LarkModel
import RxSwift
import RxCocoa

open class IMKeyboardViewModel: OpenKeyboardViewModel<KeyboardContext, IMKeyboardMetaModel> {

    public var chatModel: Chat {
        return chat.value
    }

    public let chat: BehaviorRelay<Chat>

    let bag: DisposeBag = DisposeBag()

    public init(module: BaseKeyboardModule<KeyboardContext, IMKeyboardMetaModel>,
                chat: BehaviorRelay<Chat>) {
        self.chat = chat
        super.init(module: module)
        chat.observeOn(MainScheduler.instance)
            .subscribe { value in
                module.modelDidChange(model: IMKeyboardMetaModel(chat: value))
            }.disposed(by: bag)
    }
}
