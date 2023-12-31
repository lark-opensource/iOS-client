//
//  ChatSettingFuctionBaseModel.swift
//  LarkOpenChat
//
//  Created by JackZhao on 2021/8/27.
//

import UIKit
import Foundation
import LarkBadge
import LarkModel
import RxSwift

public struct ChatSettingFunctionItem: ChatSettingItemProtocol {
    public var type: ChatSettingFunctionItemType
    public let title: String
    public let badgePath: Path?
    public let imageInfo: ChatSettingItemImageInfo
    public let clickHandler: (UIViewController?) -> Void

    public init(
        type: ChatSettingFunctionItemType,
        title: String,
        imageInfo: ChatSettingItemImageInfo,
        badgePath: Path? = nil,
        clickHandler: @escaping (UIViewController?) -> Void) {
        self.type = type
        self.title = title
        self.imageInfo = imageInfo
        self.badgePath = badgePath
        self.clickHandler = clickHandler
    }
}

public protocol ChatSettingFunctionItemsFactory: NSObject {
    func createExtensionFuncs(chat: Chat,
                              rootPath: Path) -> Observable<[ChatSettingFunctionItem]>
    func badgeShow(for path: Path, show: Bool, type: BadgeType)
}

public extension ChatSettingFunctionItemsFactory {
    func badgeShow(for path: Path, show: Bool, type: BadgeType) {
        if show {
            BadgeManager.setBadge(path, type: type)
        } else {
            BadgeManager.clearBadge(path)
        }
    }
}
