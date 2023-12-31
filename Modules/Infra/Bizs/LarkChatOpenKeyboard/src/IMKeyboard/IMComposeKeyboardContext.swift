//
//  IMComposeKeyboardContext.swift
//  LarkChatOpenKeyboard
//
//  Created by liluobin on 2023/4/24.
//

import UIKit
import LarkOpenKeyboard
import LarkModel
import RxSwift
import RxCocoa
import RustPB
import EditTextView
import LarkKeyboardView

/**
这里对IMComposeKeyboardContext的理解 就是处理当前场景下: 即富文本场景下，通用的数据
 */
public class IMComposeKeyboardContext: KeyboardContext {

    public func getReplyMessage() -> Message? {
        return self.resolver.resolve(ComposeOpenKeyboardService.self)?.getReplyMessage()
    }

    public var keyboardStatusManager: KeyboardStatusManager {
        return self.resolver.resolve(ComposeOpenKeyboardService.self)!.keyboardStatusManager
    }

    public func getRootVC() -> UIViewController {
        return self.resolver.resolve(ComposeOpenKeyboardService.self)!.getRootVC() ?? self.displayVC
    }

    public func dismissByCancel() {
        try? self.userResolver.resolve(type: ComposeOpenKeyboardService.self).dismissByCancel()
    }

}

public protocol ComposeOpenKeyboardService: OpenKeyboardService {
    func getReplyMessage() -> Message?
    var keyboardStatusManager: KeyboardStatusManager { get }
    func getRootVC() -> UIViewController?
    func dismissByCancel()
}

public class ComposeOpenKeyboardServiceEmptyIMP: OpenKeyboardServiceEmptyIMP, ComposeOpenKeyboardService {
    public func getReplyMessage() -> Message? { return nil }
    public var keyboardStatusManager: KeyboardStatusManager { return KeyboardStatusManager() }
    public func getRootVC() -> UIViewController? { return nil }
    public func dismissByCancel() {}
}
