//
//  FavoriteFolderMessageViewModel.swift
//  LarkChat
//
//  Created by 赵家琛 on 2021/4/21.
//

import UIKit
import Foundation
import LarkModel
import LarkContainer
import LarkCore
import EENavigator
import LarkMessengerInterface
import LarkMessageCore

public final class FavoriteFolderMessageViewModel: FavoriteMessageViewModel {
    override public class var identifier: String {
        return String(describing: FavoriteFolderMessageViewModel.self)
    }

    override public var identifier: String {
        return FavoriteFolderMessageViewModel.identifier
    }

    private var folderContent: FolderContent {
        var name = ""
        if let folderContent = message.content as? FolderContent {
            if self.dynamicAuthorityEnum.authorityAllowed {
                return folderContent
            }
            name = folderContent.name
        }
        return FolderContent(
            key: "",
            name: name,
            size: 0,
            fileSource: .unknown,
            lanTransStatus: .pending
        )
    }

    var permissionPreview: (Bool, ValidateResult?) {
        return checkPermissionPreview()
    }

    var name: String {
        return folderContent.name
    }

    var size: String {
        let size = ByteCountFormatter.string(fromByteCount: folderContent.size, countStyle: .binary)
        return "\(size)"
    }

    var icon: UIImage {
        return Resources.icon_folder_message
    }

    func folderViewTapped(withDispatcher dispatcher: RequestDispatcher, in window: UIWindow) {
        if !self.dynamicAuthorityEnum.authorityAllowed {
            self.chatSecurity?.alertForDynamicAuthority(event: .receive, result: self.dynamicAuthorityEnum, from: window)
            return
        }
        let permissionPreview = self.permissionPreview
        if !permissionPreview.0 {
            self.chatSecurity?.authorityErrorHandler(event: .localFilePreview, authResult: permissionPreview.1, from: window, errorMessage: nil, forceToAlert: true)
            return
        }
        let body = FolderManagementBody(message: message, messageId: nil, scene: .favorite(favoriteId: self.favorite.id), downloadFileScene: .favorite)
        navigator.push(body: body, from: window)
    }

    override public var needAuthority: Bool {
        return true
    }
}
