//
//  MsgCardLynxAvatar.swift
//  LarkMessageCard
//
//  Created by zhujingcheng on 8/29/23.
//

import Foundation
import Lynx
import LarkBizAvatar
import ByteWebImage
import LarkContainer
import LKCommonsLogging

struct AvatarProps: Decodable {
    let personID: String?
    let avatarKey: String?
    let key: String
    let clickable: Bool?
    
    static func from(dict: [String: Any?]) throws -> Self {
        return try JSONDecoder().decode(
            AvatarProps.self,
            from: JSONSerialization.data(withJSONObject: dict)
        )
    }
}

public final class MsgCardLynxAvatar: LynxUIView {
    public static let name: String = "universal-card-avatar"
    
    @Injected private var cardContextManager: MessageCardContextManagerProtocol
    private var cardContext: MessageCardContainer.Context?
    private static let logger = Logger.oplog(MsgCardLynxAvatar.self, category: "MsgCardLynxAvatar")
    private var personID: String?
    private var clickable = false
    
    lazy private var avatarView: BizAvatar = {
        let avatar = BizAvatar()
        avatar.clipsToBounds = true
        avatar.onTapped = { [weak self] _ in
            self?.onAvatarTapped()
        }
        return avatar
    }()
    
    @objc
    public static func propSetterLookUp() -> [[String]] {
        return [
            ["props", NSStringFromSelector(#selector(setProps))],
        ]
    }
    
    @objc
    public override func createView() -> UIView? {
        return avatarView
    }

    @objc
    func setProps(props: Any?, requestReset _: Bool) {
        guard let props = props as? [String: Any?] else  {
            Self.logger.error("wrong props type \(String(describing: props.self))")
            return
        }
        
        do {
            let avatarProps = try AvatarProps.from(dict: props)
            personID = avatarProps.personID
            clickable = avatarProps.clickable ?? false
            cardContext = cardContextManager.getContext(key: avatarProps.key)
            
            guard let personID = personID else {
                avatarView.image = BundleResources.LarkMessageCard.universal_card_avatar
                Self.logger.error("personID not found")
                return
            }
            
            var hasAvatarKey = false
            if let avatarKey = avatarProps.avatarKey, !avatarKey.isEmpty {
                hasAvatarKey = true
                avatarView.setAvatarByIdentifier(personID, avatarKey: avatarKey, placeholder: BundleResources.LarkMessageCard.universal_card_avatar)
            }
            
            guard let actionService = cardContext?.dependency?.actionService else {
                if !hasAvatarKey {
                    avatarView.image = BundleResources.LarkMessageCard.universal_card_avatar
                }
                Self.logger.error("actionService not found")
                return
            }
            actionService.fetchUsers(ids: [personID], callback: { [weak self] err, info in
                DispatchQueue.main.async(execute: {
                    guard let info = info, !info.isEmpty else {
                        if !hasAvatarKey {
                            self?.avatarView.image = BundleResources.LarkMessageCard.universal_card_avatar
                        }
                        Self.logger.error("fetch user error: \(err?.localizedDescription ?? "")")
                        return
                    }
                    
                    self?.avatarView.setAvatarByIdentifier(personID, avatarKey: info[personID]?.avatarKey ?? "", placeholder: BundleResources.LarkMessageCard.universal_card_avatar)
                })
            })
        } catch let error {
            avatarView.image = BundleResources.LarkMessageCard.universal_card_avatar
            Self.logger.error("props serialize failed: \(error.localizedDescription)")
        }
    }
    
    @objc
    private func onAvatarTapped() {
        guard let actionService = cardContext?.dependency?.actionService,
              clickable else {
            Self.logger.error("avatar open profile failed, clickable: \(clickable)")
            return
        }
        
        guard let personID = personID, !personID.isEmpty else {
            actionService.showToast(context: MessageCardActionContext(), type: .info, text: BundleI18n.LarkMessageCard.OpenPlatform_CardCompt_UnknownUser, on: nil)
            return
        }
        
        actionService.openProfile(context: MessageCardActionContext(), chatterID: personID)
    }
}
