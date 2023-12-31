//
//  FlagVideoMessageViewModel.swift
//  LarkFeed
//
//  Created by phoenix on 2022/5/10.
//

import UIKit
import Foundation
import LarkModel
import LarkContainer
import LarkCore
import RustPB
import EENavigator
import LarkMessageCore

final class FlagVideoMessageViewModel: FlagMessageCellViewModel {

    override class var identifier: String {
        return String(describing: FlagVideoMessageViewModel.self)
    }

    override var identifier: String {
        return FlagVideoMessageViewModel.identifier
    }

    var messageContent: MediaContent? {
        guard self.dynamicAuthorityEnum.authorityAllowed else { return nil}
        return self.message.content as? MediaContent
    }

    func showVideo(withDispatcher dispatcher: RequestDispatcher, imageView: UIImageView) {
        if !self.dynamicAuthorityEnum.authorityAllowed {
            self.chatSecurity?.alertForDynamicAuthority(event: .receive,
                                                        result: dynamicAuthorityEnum,
                                                        from: imageView.window)
            return
        }
        if !permissionPreview.0 {
            guard let window = imageView.window else {
                assertionFailure()
                return
            }
            self.chatSecurity?.authorityErrorHandler(event: .localVideoPreview, authResult: self.permissionPreview.1, from: window, errorMessage: nil, forceToAlert: true)
            return
        }
        let _: EmptyResponse? = dispatcher.send(PreviewAssetActionMessage(
            imageView: imageView,
            source: .message(message),
            downloadFileScene: .favorite
        ))
    }

    override public var needAuthority: Bool {
        return true
    }
}
