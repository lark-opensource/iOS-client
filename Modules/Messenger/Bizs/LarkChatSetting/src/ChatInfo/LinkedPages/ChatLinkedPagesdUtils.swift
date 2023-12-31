//
//  ChatLinkedPagesdUtils.swift
//  LarkChatSetting
//
//  Created by zhaojiachen on 2023/10/27.
//

import Foundation
import LarkContainer
import UniverseDesignActionPanel
import LarkNavigator
import UniverseDesignIcon
import LarkSwipeCellKit
import LarkModel
import LKCommonsLogging

class ChatLinkedPagesdUtils {
    private static let logger = Logger.log(ChatLinkedPagesdUtils.self, category: "Module.IM.ChatLinkedPages")

    static func getSwipeDeleteAction(
        chat: Chat,
        userID: String,
        targetVC: UIViewController?,
        navigator: UserNavigator,
        deleteHandler: @escaping () -> Void
    ) -> SwipeAction? {
        guard checkDeletePermission(chat: chat, userID: userID) else {
            return nil
        }
        let deleteAction = SwipeAction(
            style: .destructive,
            title: BundleI18n.LarkChatSetting.Lark_GroupLinkPage_Unlink_Mobile_Button,
            handler: { [weak targetVC] (_, _, _) in
                guard let targetVC = targetVC else { return }
                Self.showAlert(
                    targetVC: targetVC,
                    navigator: navigator,
                    confirmHandler: { deleteHandler() }
                )
            }
        )
        deleteAction.hidesWhenSelected = true
        deleteAction.backgroundColor = UIColor.ud.functionDangerContentDefault
        deleteAction.font = UIFont.systemFont(ofSize: 12)
        deleteAction.textColor = UIColor.ud.staticWhite
        deleteAction.image = UDIcon.getIconByKey(.unboundGroupOutlined, iconColor: UIColor.ud.staticWhite, size: CGSize(width: 16, height: 16))
        return deleteAction
    }

    static func getSwipeOptions() -> SwipeOptions {
        var options = SwipeOptions()
        options.buttonStyle = .horizontal
        options.buttonHorizontalPadding = 12
        options.buttonSpacing = 4
        return options
    }

    static func showAlert(targetVC: UIViewController, navigator: UserNavigator, confirmHandler: @escaping () -> Void) {
        let actionSheet = UDActionSheet(config: UDActionSheetUIConfig(isShowTitle: true))
        actionSheet.setTitle( BundleI18n.LarkChatSetting.Lark_GroupLinkPage_OnceUnlinkedRemove_Description)
        actionSheet.addDestructiveItem(text: BundleI18n.LarkChatSetting.Lark_GroupLinkPage_Unlink_Button) {
            confirmHandler()
        }
        actionSheet.setCancelItem(text: BundleI18n.LarkChatSetting.Lark_GroupLinkPage_NotNow_Button)
        navigator.present(actionSheet, from: targetVC)
    }

    static func renderIconView(_ imageView: UIImageView, entity: InlinePreviewEntity) {

        func setImage(_ imageView: UIImageView, image: UIImage) {
            imageView.image = image
        }

        if let header = entity.unifiedHeader, header.hasIcon {
            let colorIcon = header.icon
            if let image = colorIcon.udIcon.unicodeImage {
                setImage(imageView, image: image)
                return
            } else if let image = colorIcon.udIcon.udImage {
                setImage(imageView, image: image)
                return
            }
            let key = !colorIcon.icon.key.isEmpty ? colorIcon.icon.key : colorIcon.faviconURL
            if !key.isEmpty {
                let customIconColor = colorIcon.iconColor.color
                imageView.bt.setLarkImage(.default(key: key), completion: { [weak imageView] res in
                    switch res {
                    case .success(let imageResult):
                        if let image = imageResult.image, let imageView = imageView {
                            if let customIconColor = customIconColor {
                                setImage(imageView, image: image.ud.withTintColor(customIconColor))
                            } else {
                                setImage(imageView, image: image)
                            }
                        }
                    case .failure(let error):
                        Self.logger.info("ChatLinkedPagesdUtils renderIconView fail", error: error)
                    }
                })
                return
            }
        }

        let tintColor = UIColor.ud.B500
        if let image = entity.udIcon?.unicodeImage {
            setImage(imageView, image: image)
            return
        } else if let image = entity.udIcon?.udImage {
            setImage(imageView, image: image.ud.withTintColor(tintColor))
            return
        }
        let key = entity.iconKey ?? entity.iconUrl
        if let key = key, !key.isEmpty {
            imageView.bt.setLarkImage(.default(key: key), completion: { [weak imageView] res in
                switch res {
                case .success(let imageResult):
                    if let image = imageResult.image, let imageView = imageView {
                        setImage(imageView, image: image.ud.withTintColor(tintColor))
                    }
                case .failure(let error):
                    Self.logger.info("ChatLinkedPagesdUtils renderIconView fail", error: error)
                }
            })
            return
        }

        if let image = entity.iconImage {
            setImage(imageView, image: image.ud.withTintColor(tintColor))
        }
    }

    static func checkDeletePermission(chat: Chat, userID: String) -> Bool {
        if chat.chatPinPermissionSetting == .allMembers {
            return true
        } else if chat.chatPinPermissionSetting == .onlyManager {
            if chat.isGroupAdmin || chat.ownerId == userID {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
}
