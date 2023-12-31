//
//  ForwardProxy.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/12/10.
//

import Foundation
import EENavigator

public protocol MailForwardProxy {
    func forwardImage(
        _ image: UIImage,
        needFilterExternal: Bool,
        from: NavigatorFrom,
        shouldDismissFromVC: Bool,
        cancelCallBack: (() -> Void)?,
        forwardResultCallBack: @escaping ((MailAttachmentForwardResult?) -> Void))
}
