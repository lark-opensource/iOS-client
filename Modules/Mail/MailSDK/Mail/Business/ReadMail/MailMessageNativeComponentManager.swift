//
//  MailMessageNativeComponentManager.swift
//  MailSDK
//
//  Created by Bytedance on 2021/8/25.
//

import Foundation
import LarkWebviewNativeComponent

protocol MailMessageNativeComponentManagerDelegate: NativeAvatarComponentDelegate, AnyObject {
    func mailTitleView() -> MailReadTitleView?
}

class MailMessageNativeComponentManager: NativeComponentManageable {
    /// 唯一标示id 和 组件实例的映射表
    var components: [String: WeakComponentWrapper] = [:]

    weak var delegate: MailMessageNativeComponentManagerDelegate?

    func registerComponentType(_ types: [NativeComponentAble.Type]) { }

    func createCompentWithTagName(tagName: String) -> NativeComponentAble? {
        switch tagName {
        case "lk-native-avatar":
            let temp = NativeAvatarComponent()
            temp.delegate = delegate
            return temp
        case "lk-native-title":
            if let delegate = delegate {
                return delegate.mailTitleView()
            } else {
                return MailReadTitleView()
            }
        default:
            assertionFailure("MailMessageNativeComponentManager tag not handled \(tagName)")
            return nil
        }
    }
}
