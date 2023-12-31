//
//  FlagFolderMessageViewModel.swift
//  LarkFeed
//
//  Created by phoenix on 2022/5/10.
//

import UIKit
import Foundation
import LarkModel
import LarkContainer
import LarkCore
import EENavigator
import LarkMessengerInterface
import UniverseDesignIcon
import UniverseDesignColor
import LarkMessageCore

public final class FlagFolderMessageViewModel: FlagMessageCellViewModel {

    override public class var identifier: String {
        return String(describing: FlagFolderMessageViewModel.self)
    }

    override public var identifier: String {
        return FlagFolderMessageViewModel.identifier
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

    var name: String {
        return folderContent.name
    }

    var size: String {
        let size = ByteCountFormatter.string(fromByteCount: folderContent.size, countStyle: .binary)
        return "\(size)"
    }

    var icon: UIImage {
        return UDIcon.getIconByKey(.fileFolderColorful, size: CGSize(width: 36, height: 36))
    }

    func folderViewTapped(withDispatcher dispatcher: RequestDispatcher, in window: UIWindow) {
        if !dynamicAuthorityEnum.authorityAllowed {
            self.chatSecurity?.alertForDynamicAuthority(event: .receive,
                                                        result: dynamicAuthorityEnum,
                                                        from: window)
            return
        }
        if !permissionPreview.0 {
            self.chatSecurity?.authorityErrorHandler(event: .localFilePreview, authResult: self.permissionPreview.1, from: window, errorMessage: nil, forceToAlert: true)
            return
        }
        let body = FolderManagementBody(message: message, messageId: nil, scene: .flag, downloadFileScene: .favorite)
        userResolver.navigator.push(body: body, from: window)
    }

    override public var needAuthority: Bool {
        return true
    }
}
