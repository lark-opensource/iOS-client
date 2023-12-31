//
//  FavoriteFileMessageViewModel.swift
//  Lark
//
//  Created by lichen on 2018/6/7.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import LarkModel
import LarkUIKit
import LarkContainer
import LarkCore
import LarkFoundation
import EENavigator
import LarkMessengerInterface
import LKCommonsLogging
import RustPB
import LarkKASDKAssemble
import LarkMessageCore

public final class FavoriteFileMessageViewModel: FavoriteMessageViewModel {
    private static let logger = Logger.log(FavoriteFileMessageViewModel.self, category: "LarkChat.Favorite.FavoriteFileMessageViewModel")

    override public class var identifier: String {
        return String(describing: FavoriteFileMessageViewModel.self)
    }

    override public var identifier: String {
        return FavoriteFileMessageViewModel.identifier
    }

    var permissionPreview: (Bool, ValidateResult?) {
        return checkPermissionPreview()
    }

    private var fileContent: FileContent {
        var name = ""
        if let fileContent = message.content as? FileContent {
            if self.dynamicAuthorityEnum.authorityAllowed {
                return fileContent
            }
            name = fileContent.name
        }
        return FileContent(
            key: "",
            name: name,
            size: 0,
            mime: "",
            filePath: "",
            cacheFilePath: "",
            fileSource: RustPB.Basic_V1_File.Source.unknown,
            namespace: "",
            isInMyNutStore: false,
            lanTransStatus: .pending,
            hangPoint: nil,
            fileAbility: .unknownSupportState,
            filePermission: .unknownCanState,
            fileLastUpdateUserId: 0,
            fileLastUpdateTimeMs: 0,
            filePreviewStage: .normal
        )
    }

    var name: String {
        return fileContent.name
    }

    var size: String {
        let size = ByteCountFormatter.string(fromByteCount: fileContent.size, countStyle: .binary)
        return "\(size)"
    }

    var icon: UIImage {
        return LarkCoreUtils.fileLadderIcon(with: name)
    }

    @ScopedInjectedLazy var dependency: DriveSDKFileDependency?
    @ScopedInjectedLazy private var fileUtil: FileUtilService?
    func fileViewTapped(withDispatcher dispatcher: RequestDispatcher, in window: UIWindow) {
        if !self.dynamicAuthorityEnum.authorityAllowed {
            self.chatSecurity?.alertForDynamicAuthority(event: .receive,
                                                       result: dynamicAuthorityEnum,
                                                       from: window)
            return
        }
        if !permissionPreview.0 {
            self.chatSecurity?.authorityErrorHandler(event: .localFilePreview, authResult: permissionPreview.1, from: window, errorMessage: nil, forceToAlert: true)
            return
        }
        let body = MessageFileBrowseBody(message: message, scene: .favorite(favoriteId: favorite.id), downloadFileScene: .favorite)
        navigator.push(body: body, from: window)
    }

    override public var needAuthority: Bool {
        return true
    }
}
