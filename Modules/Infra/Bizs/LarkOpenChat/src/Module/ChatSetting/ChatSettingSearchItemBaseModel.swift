//
//  ChatSettingSearchItemBaseModel.swift
//  LarkOpenChat
//
//  Created by JackZhao on 2021/8/27.
//

import UIKit
import Foundation
import RxSwift
import LarkBadge
import LarkModel
import LarkContainer

public enum ChatSettingItemImageInfo {
    case image(UIImage)
    case key(String)
}

public protocol ChatSettingItemProtocol {
    var title: String { get }
    var badgePath: Path? { get }
    var imageInfo: ChatSettingItemImageInfo { get }
    var clickHandler: (UIViewController?) -> Void { get }
}

public struct ChatSettingSearchDetailItem: ChatSettingItemProtocol {
    public var type: ChatSettingSearchDetailItemType
    public var title: String
    public var badgePath: Path?
    public var imageInfo: ChatSettingItemImageInfo
    public var clickHandler: (UIViewController?) -> Void

    public init(type: ChatSettingSearchDetailItemType,
                title: String,
                badgePath: Path? = nil,
                imageInfo: ChatSettingItemImageInfo,
                clickHandler: @escaping (UIViewController?) -> Void) {
        self.type = type
        self.title = title
        self.badgePath = badgePath
        self.imageInfo = imageInfo
        self.clickHandler = clickHandler
    }
}

public protocol ChatSettingSerachDetailItemsFactory {
    init(userResolver: UserResolver)
    func createItems(chat: Chat) -> Observable<[ChatSettingSearchDetailItem]>
}
