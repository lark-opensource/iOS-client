// 
// Created by duanxiaochen.7 on 2020/3/29.
// Affiliated with DocsSDK.
// 
// Description:

import Foundation

@frozen
public struct BTCapsuleModel: Equatable {
    public var id: String // 从group开始用id, 后续都用id字段来传递，方便复用
    public var text: String
    public var color: BTColorModel
    public var isSelected: Bool
    public var font: UIFont
    public var avatarUrl: String
    public var userID: String
    public var name: String
    public var enName: String
    public var chatterType: BTChatterType
    public var token: String
    public var isShow: Bool?
    public var callbackId: String?
    
    public var avatarKey: String?

    public init(id: String,
                text: String,
                color: BTColorModel, isSelected: Bool,
                font: UIFont = UIFont.systemFont(ofSize: 14, weight: .medium),
                token: String = "",
                avatarUrl: String = "",
                userID: String = "",
                name: String = "",
                enName: String = "",          // 别名，已国际化
                displayName: String? = nil,
                chatterType: BTChatterType = .user,
                isShow: Bool? = nil,
                callbackId: String? = nil) {
        self.id = id
        self.color = color
        self.isSelected = isSelected
        self.font = font
        self.avatarUrl = avatarUrl
        self.userID = userID
        self.chatterType = chatterType
        self.token = token
        self.isShow = isShow
        self.callbackId = callbackId
        // 优先展示别名（文档正文目前还不支持别名，这里会带到正文中，因此还是保持原真名逻辑，后续正文支持后再解除下方代码注释）
//        if let displayName = displayName, !displayName.isEmpty {
//            self.text = displayName
//            self.name = displayName
//            self.enName = displayName
//        } else {
            self.text = text
            self.name = name
            self.enName = enName
//        }
    }
}
