//
//  TopNoticeBannerModel.swift
//  LarkMessageCore
//
//  Created by liluobin on 2021/11/3.
//

import Foundation
import UIKit
import LarkModel
import LarkMessengerInterface
import LarkContainer

public final class TopNoticeBannerModel: UserResolverWrapper {
    @ScopedInjectedLazy var chatSecurityControlService: ChatSecurityControlService?
    @ScopedInjectedLazy var messageDynamicAuthorityService: MessageDynamicAuthorityService?
    public let userResolver: UserResolver
    public enum ImageType {
        case key(imagekey: String, isVideo: Bool, authorityMessage: Message, anonymousId: String)
        case icon
        case sticker(key: String, stickerSetID: String)
    }
    var title: NSAttributedString
    var name: String
    var type: ImageType {
        didSet {
            resetHasPermissionPreview()
        }
    }
    var placeholderImage: UIImage?
    var closeCallBack: ((UIButton?) -> Void)?
    var tapCallBack: (() -> Void)?
    var fromUserClick: ((Chatter?) -> Void)?
    var fromChatter: Chatter?

    public init(userResolver: UserResolver,
         title: NSAttributedString,
         name: String,
         type: ImageType,
         fromChatter: Chatter? = nil,
         placeholderImage: UIImage? = nil,
         closeCallBack: ((UIButton?) -> Void)? = nil,
         tapCallBack: (() -> Void)? = nil,
         fromUserClick: ((Chatter?) -> Void)? = nil) {
        self.userResolver = userResolver
        self.title = title
        self.name = name
        self.type = type
        self.fromChatter = fromChatter
        self.fromUserClick = fromUserClick
        self.placeholderImage = placeholderImage
        self.closeCallBack = closeCallBack
        self.tapCallBack = tapCallBack
    }

    private var _permissionPreview: (Bool, ValidateResult?)?
    var permissionPreview: (Bool, ValidateResult?) {
        if let cache = _permissionPreview {
            return cache
        }

        let value: (Bool, ValidateResult?)
        switch type {
        case .key(_, _, let authorityMessage, let anonymousId):
            value = chatSecurityControlService?.checkPermissionPreview(anonymousId: anonymousId, message: authorityMessage) ?? (true, nil)
        default:
            value = (true, nil)
        }
        _permissionPreview = value
        return value
    }
    //重置_hasPermissionPreview的值，下次获取时需重新计算
    private func resetHasPermissionPreview() {
        _permissionPreview = nil
    }
}
