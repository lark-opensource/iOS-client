//
//  MessageStateInterceptor.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/2/7.
//

import Foundation
import LarkModel
import LarkMessageBase
import LarkMenuController
import LarkSDKInterface
import LarkContainer
import LarkSearchCore
import LarkUIKit
import LarkGuide
import LarkSetting
import RustPB
import LKCommonsLogging
import UniverseDesignToast

public final class MessageStateActionInterceptor: MessageActioSubnInterceptor {
    public required init() { }
    public static var subType: MessageActionSubInterceptorType { .messageState }
    public func intercept(context: MessageActionInterceptorContext) -> [MessageActionType: MessageActionInterceptedType] {
        var interceptedActions: [MessageActionType: MessageActionInterceptedType] = [:]
        let fileLanTransing: Bool = {
            if let fileContent = context.message.content as? FileContent, fileContent.fileSource == .lanTrans,
               fileContent.lanTransStatus == .pending || fileContent.lanTransStatus == .accept { return true }
            return false
        }()
        let folderLanTransing: Bool = {
            if let folderContent = context.message.content as? FolderContent, folderContent.fileSource == .lanTrans,
               folderContent.lanTransStatus == .pending || folderContent.lanTransStatus == .accept { return true }
            return false
        }()
        /// (尚)未发送成功
        /// 正在局域网传输ing
        if context.message.localStatus != .success || fileLanTransing || folderLanTransing {
            MessageActionType.allCases.forEach { type in
                switch type {
                case .delete, .copy, .cardCopy, .search:
                    break
                default:
                    interceptedActions.updateValue(.hidden, forKey: type)
                }
            }
        }
        return interceptedActions
    }
}
