//
//  FlagFileMessageViewModel.swift
//  LarkFeed
//
//  Created by phoenix on 2022/5/10.
//

import UIKit
import Foundation
import LarkModel
import LarkUIKit
import LarkContainer
import LarkCore
import EENavigator
import LarkMessengerInterface
import LKCommonsLogging
import RustPB
import LarkKASDKAssemble
import LarkMessageCore

public final class FlagFileMessageViewModel: FlagMessageCellViewModel {
    private static let logger = Logger.log(FlagFileMessageViewModel.self, category: "LarkFeed.Flag.FlagFileMessageViewModel")

    override public class var identifier: String {
        return String(describing: FlagFileMessageViewModel.self)
    }

    override public var identifier: String {
        return FlagFileMessageViewModel.identifier
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
        let body = MessageFileBrowseBody(message: message, scene: .flag, downloadFileScene: .unknown)
        userResolver.navigator.push(body: body, from: window)
    }

    override public var needAuthority: Bool {
        return true
    }
}
