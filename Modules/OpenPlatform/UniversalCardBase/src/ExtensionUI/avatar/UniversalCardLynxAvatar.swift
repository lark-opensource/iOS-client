//
//  UniversalCardLynxAvatar.swift
//  UniversalCardBase
//
//  Created by zhujingcheng on 8/29/23.
//

import Foundation
import Lynx
import LarkBizAvatar
import ByteWebImage
import LarkContainer
import LKCommonsLogging
import UniversalCardInterface

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

public final class UniversalCardLynxAvatar: LynxUIView {
    public static let name: String = "universal-card-avatar"
    private var cardContext: UniversalCardContext?
    private static let logger = Logger.oplog(UniversalCardLynxAvatar.self, category: "UniversalCardLynxAvatar")
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
            cardContext = getCardContext()
            
            guard let personID = personID else {
                avatarView.image = BundleResources.UniversalCardBase.universal_card_avatar
                Self.logger.info("personID not found")
                return
            }
            
            var hasAvatarKey = false
            if let avatarKey = avatarProps.avatarKey, !avatarKey.isEmpty {
                hasAvatarKey = true
                avatarView.setAvatarByIdentifier(personID, avatarKey: avatarKey, placeholder: BundleResources.UniversalCardBase.universal_card_avatar)
            }
            
            guard let cardContext = cardContext,
                  let actionService = cardContext.dependency?.actionService else {
                if !hasAvatarKey {
                    avatarView.image = BundleResources.UniversalCardBase.universal_card_avatar
                }
                Self.logger.error("cardContext or actionService not found")
                return
            }
            
            let actionContext = UniversalCardActionContext(
                trace: cardContext.renderingTrace?.subTrace() ?? cardContext.trace.subTrace()
            )
            actionService.fetchUsers(context: actionContext, ids: [personID]) { [weak self] err, info in
                DispatchQueue.main.async(execute: {
                    guard let info = info, !info.isEmpty else {
                        if !hasAvatarKey {
                            self?.avatarView.image = BundleResources.UniversalCardBase.universal_card_avatar
                        }
                        Self.logger.error("fetch user error: \(err?.localizedDescription ?? "")")
                        return
                    }
                    self?.avatarView.setAvatarByIdentifier(personID, avatarKey: info[personID]?.avatarKey ?? "", placeholder: BundleResources.UniversalCardBase.universal_card_avatar)
                })
            }
        } catch let error {
            avatarView.image = BundleResources.UniversalCardBase.universal_card_avatar
            Self.logger.error("props serialize failed: \(error.localizedDescription)")
        }
    }
    
    @objc
    private func onAvatarTapped() {
        guard let cardContext = cardContext,
              let actionService = cardContext.dependency?.actionService,
              clickable else {
            Self.logger.error("avatar open profile failed, clickable:\(clickable)")
            return
        }
        
        let actionContext = UniversalCardActionContext(
            trace: cardContext.renderingTrace?.subTrace() ?? cardContext.trace.subTrace()
        )
        guard let personID = personID, !personID.isEmpty else {
            actionService.showToast(context: actionContext, type: .info, text: BundleI18n.UniversalCardBase.OpenPlatform_CardCompt_UnknownUser, on: nil)
            return
        }
        
        guard let sourceVC = cardContext.sourceVC else {
            Self.logger.error("avatar open profile failed, sourceVC is nil")
            return
        }
        actionService.openProfile(context: actionContext, id: personID, from: sourceVC)
    }
}
