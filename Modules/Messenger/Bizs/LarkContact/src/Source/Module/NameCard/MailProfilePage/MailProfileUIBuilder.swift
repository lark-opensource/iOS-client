//
//  MailProfileUIBuilder.swift
//  LarkContact
//
//  Created by tefeng liu on 2021/12/30.
//

import Foundation
import LarkSDKInterface
import LarkBizAvatar
import LarkUIKit
import RichLabel
import UIKit
import UniverseDesignIcon
import LarkAccount

/*
 public struct UserInfo {

     public var namecardID: String

     /// Returns true if `namecardID` has been explicitly set.
     public var hasNamecardID: Bool { get }

     /// Clears the value of `namecardID`. Subsequent reads from it will return its default value.
     public mutating func clearNamecardID()

     public var friendStatus: RustPB.Contact_V2_GetNamecardProfileResponse.UserInfo.FriendStatus

     /// Returns true if `friendStatus` has been explicitly set.
     public var hasFriendStatus: Bool { get }

     /// Clears the value of `friendStatus`. Subsequent reads from it will return its default value.
     public mutating func clearFriendStatus()

     /// 名称
     public var userName: String

     /// Returns true if `userName` has been explicitly set.
     public var hasUserName: Bool { get }

     /// Clears the value of `userName`. Subsequent reads from it will return its default value.
     public mutating func clearUserName()

     public var avatarKey: String

     /// Returns true if `avatarKey` has been explicitly set.
     public var hasAvatarKey: Bool { get }

     /// Clears the value of `avatarKey`. Subsequent reads from it will return its default value.
     public mutating func clearAvatarKey()

     /// 公司名
     public var companyName: String

     /// Returns true if `companyName` has been explicitly set.
     public var hasCompanyName: Bool { get }

     /// Clears the value of `companyName`. Subsequent reads from it will return its default value.
     public mutating func clearCompanyName()

     /// Some formats include enough information to transport fields that were
     /// not known at generation time. When encountered, they are stored here.
     public var unknownFields: SwiftProtobuf.UnknownStorage

     public enum FriendStatus : SwiftProtobuf.Enum {

         /// The raw type that can be used to represent all values of the conforming
         /// type.
         ///
         /// Every distinct value of the conforming type has a corresponding unique
         /// value of the `RawValue` type, but there may be values of the `RawValue`
         /// type that don't have a corresponding value of the conforming type.
         public typealias RawValue = Int

         /// 不展示button和...
         case forward

         /// 展示button和...
         case none

         /// Creates a new instance of the enum initialized to its default value.
         public init()

         /// Creates a new instance of the enum from the given raw integer value.
         ///
         /// For proto2 enums, this initializer will fail if the raw value does not
         /// correspond to a valid enum value. For proto3 enums, this initializer never
         /// fails; unknown values are created as instances of the `UNRECOGNIZED` case.
         ///
         /// - Parameter rawValue: The raw integer value from which to create the enum
         ///   value.
         public init?(rawValue: Int)

         /// The raw integer value of the enum value.
         ///
         /// For a recognized enum case, this is the integer value of the case as
         /// defined in the .proto file. For `UNRECOGNIZED` cases in proto3, this is
         /// the value that was originally decoded.
         public var rawValue: Int { get }
     }

     /// Creates a new message with all of its fields initialized to their default
     /// values.
     public init()
 }
 */

protocol MailProfileUIBuilderDelegate: AnyObject {
    func didSelectEmail(userProfile: NameCardUserProfile)
}

final class MailProfileUIBuilder {
    var userProfile: NameCardUserProfile?
    var email: String = ""
    var defaultName: String = ""
    var currentAvatarView: BizAvatar?
    var accountType: String = "None"

    weak var delegate: MailProfileUIBuilderDelegate?

    static var detailInfoTypes: [MailProfileCellItem.Type] {
        return [MailProfileNormalItem.self,
                MailProfilePhoneItem.self,
                MailProfileLinkItem.self]
    }

    func getAvtarView(completion: @escaping (BizAvatar) -> Void) {
        guard let userInfo = self.userProfile?.userInfo else {
            completion(BizAvatar())
            return
        }

        let bizView = BizAvatar()
        bizView.updateBorderSize(CGSize(width: 113, height: 113))
        bizView.border.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        bizView.border.isHidden = false
        bizView.border.layer.cornerRadius = 113 / 2
        bizView.layer.shadowOpacity = 1
        bizView.layer.shadowRadius = 8
        bizView.layer.shadowOffset = CGSize(width: 0, height: 4)
        bizView.layer.ud.setShadowColor(UIColor.ud.shadowDefaultMd)

        if !userInfo.avatarKey.isEmpty {
            /// Image 设置完成后才返回 AvatarView，避免闪白头像
            currentAvatarView = bizView
            bizView.setAvatarByIdentifier(userInfo.namecardID,
                                          avatarKey: userInfo.avatarKey,
                                          scene: .Profile,
                                          avatarViewParams: .init(sizeType: .size(108)),
                                          backgroundColorWhenError: UIColor.ud.textPlaceholder) { [weak self] _ in
                guard let bizView = self?.currentAvatarView else { return }
                completion(bizView)
                self?.currentAvatarView = nil
            }
        } else {
            let userName = userInfo.userName.isEmpty ? defaultName : userInfo.userName
            if userName.isEmpty {
                bizView.image = BundleResources.LarkContact.NameCard.namecard_default_avatar
            } else {
                bizView.image = MailGroupHelper.generateAvatarImage(withNameString: userName, shouldPrefix: true)
            }
            completion(bizView)
        }
    }

    func getNavigationBarAvatarView() -> UIImageView {
        guard let userInfo = self.userProfile?.userInfo else {
            return UIImageView()
        }

        let avatar = UIImageView()
        if userInfo.avatarKey.isEmpty && userInfo.userName.isEmpty && defaultName.isEmpty {
            avatar.image = BundleResources.LarkContact.NameCard.namecard_default_avatar
        } else {
            avatar.bt.setLarkImage(with: .avatar(key: userInfo.avatarKey,
                                                 entityID: userInfo.namecardID,
                                                 params: .init(sizeType: .size(108))))

        }
        avatar.ud.setMaskView()
        return avatar
    }

    func getBackgroundView() -> UIImageView {
        guard let userInfo = self.userProfile?.userInfo else {
            return UIImageView()
        }

        let imageView = UIImageView()
        imageView.image = BundleResources.LarkContact.MailProfile.mail_profile_background
        imageView.isUserInteractionEnabled = true
        imageView.contentMode = .scaleAspectFill

        return imageView
    }

    func getUserInfo() -> MailProfileUserInfo {
        guard let userInfo = userProfile?.userInfo else {
            return MailProfileUserInfo(name: "")
        }

        var company: LKLabel?

        if !userInfo.companyName.isEmpty {
            let label = LKLabel()
            let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.ud.textCaption, .font: UIFont.systemFont(ofSize: 14)]
            label.numberOfLines = 1
            label.backgroundColor = .clear
            label.outOfRangeText = NSAttributedString(string: "...", attributes: attributes)
            label.textColor = UIColor.ud.textCaption
            label.textVerticalAlignment = .bottom
            label.font = UIFont.systemFont(ofSize: 14)
            label.text = userInfo.companyName

            company = label
        }

        var tagViews: [UIView] = []
        let name = userInfo.userName.isEmpty ? defaultName : userInfo.userName

        return MailProfileUserInfo(name: name,
                                   nameTag: tagViews,
                                   companyView: company)
    }

    func getNavigationButton() -> UIButton? {
        guard let userInfo = self.userProfile?.userInfo else {
            return nil
        }
        let more = UIButton()
        more.setImage(UDIcon.moreBoldOutlined.ud.withTintColor(UIColor.ud.iconN1),
                             for: .normal)
        more.setImage(UDIcon.moreBoldOutlined.ud.withTintColor(UIColor.ud.iconN1),
                             for: .highlighted)

        return more
    }

    func getDetailInfos() -> [MailProfileCellItem] {
        guard let userProfile = self.userProfile else {
            return []
        }

        // 类型转换
        var fieldOrders = [NewUserProfile.Field]()
        fieldOrders.append(contentsOf: userProfile.fieldOrders.map({ (item) -> NewUserProfile.Field in
            var field = NewUserProfile.Field()
            if let fieldType = NewUserProfile.Field.FieldType(rawValue: item.fieldType.rawValue) {
                field.fieldType = fieldType
            } else {
                if item.fieldType == .phone {
                    field.fieldType = .sPhoneNumber
                }
            }
            field.key = item.key
            field.jsonFieldVal = item.jsonFieldVal
            var i18NNames = NewUserProfile.I18nVal()
            i18NNames.defaultVal = item.i18NNames.defaultVal
            i18NNames.i18NVals = item.i18NNames.i18NVals
            field.i18NNames = i18NNames
            return field
        }))

        var infos: [MailProfileCellItem] = []
        for field in fieldOrders {
            for type in MailProfileUIBuilder.detailInfoTypes {
                if var item = type.creatItemByField(field) {
                    if var linkItem = item as? MailProfileLinkItem {
                        linkItem.accountType = accountType
                        item = linkItem
                    }
                    infos.append(item)
                }
            }
        }
        return infos
    }
}
