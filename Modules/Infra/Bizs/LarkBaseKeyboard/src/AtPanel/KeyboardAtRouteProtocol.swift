//
//  KeyboardAtContainerProtocol.swift
//  LarkBaseKeyboard
//
//  Created by liluobin on 2023/5/12.
//

import UIKit
import LarkSetting

/// 为什么要有这个KeyboardAtRouteProtocol，现有IM中插入@之后，可以点击跳转对应的profile
/// 但是这个功能做的不是太好，需要禁止一些TextView的属性，以及每个都要实现一个跳转的逻辑
/// 所以将公共逻辑收敛一下，方便使用，也省得遗漏 其他业务方接入成本也能低些

public protocol KeyboardAtRouteProtocol: AnyObject {

    func setSupportAtForTextView(_ textView: UITextView)

    func textView(_ textView: UITextView,
                            shouldInteractWith URL: URL,
                            in characterRange: NSRange,
                         interaction: UITextItemInteraction,
                         onAtClick: ((String) -> Void)? ) -> Bool
}

public extension KeyboardAtRouteProtocol {

    func setSupportAtForTextView(_ textView: UITextView) {
        if FeatureGatingManager.shared.featureGatingValue(with: "messenger.input.click_profile") {
            textView.textDragInteraction?.isEnabled = false
            textView.linkTextAttributes = [:]
        }
    }

    func textView(_ textView: UITextView,
                            shouldInteractWith URL: URL,
                            in characterRange: NSRange,
                         interaction: UITextItemInteraction,
                         onAtClick: ((String) -> Void)?) -> Bool {
        guard FeatureGatingManager.shared.featureGatingValue(with: "messenger.input.click_profile") else { return false }
        guard interaction == .invokeDefaultAction else { return false }
        if let link = LinkAttributeValue(rawValue: URL) {
            switch link {
            case .at:
                var id: String = ""
                textView.attributedText.enumerateAttribute(AtTransformer.UserIdAttributedKey, in: characterRange) { value, _, _ in
                    if let info = value as? AtChatterInfo {
                        id = info.id
                    }
                }
                onAtClick?(id)
            default:
                break
            }
        }
        return false
    }
}
