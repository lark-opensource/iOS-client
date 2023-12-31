//
//  ChatterResignMaskFooterModule.swift
//  LarkChat
//
//  Created by Zigeng on 2022/7/9.
//

import Foundation
import LarkOpenChat
import LarkOpenIM
import RxSwift
import RxCocoa
import UIKit

public final class ChatterResignMaskFooterModule: ChatFooterSubModule {
    public override class var name: String { "ChatterResignMaskFooterModule" }
    public override var type: ChatFooterType {
        return .resignChatMask
    }
    private var resignMask: UIView?
    public override func contentView() -> UIView? {
        return resignMask
    }

    public override class func canInitialize(context: ChatFooterContext) -> Bool {
        return true
    }
    public override func canHandle(model: ChatFooterMetaModel) -> Bool {
        return model.chat.chatterHasResign
    }
    public override func handler(model: ChatFooterMetaModel) -> [Module<ChatFooterContext, ChatFooterMetaModel>] {
        return [self]
    }
    public override func createViews(model: ChatFooterMetaModel) {
        super.createViews(model: model)
        self.display = true
        self.resignMask = ChatterResignChatMask(frame: .zero)
    }
}

public final class CryptoChatterResignMaskFooterModule: CryptoChatFooterSubModule {
    public override class var name: String { "CryptoChatterResignMaskFooterModule" }
    public override var type: ChatFooterType {
        return .resignChatMask
    }
    private var resignMask: UIView?
    public override func contentView() -> UIView? {
        return resignMask
    }

    public override class func canInitialize(context: ChatFooterContext) -> Bool {
        return true
    }
    public override func canHandle(model: ChatFooterMetaModel) -> Bool {
        return model.chat.chatterHasResign
    }
    public override func handler(model: ChatFooterMetaModel) -> [Module<ChatFooterContext, ChatFooterMetaModel>] {
        return [self]
    }
    public override func createViews(model: ChatFooterMetaModel) {
        super.createViews(model: model)
        self.display = true
        self.resignMask = ChatterResignChatMask(frame: .zero)
    }
}
