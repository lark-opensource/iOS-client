//
//  FlagImageMessageViewModel.swift
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
import LarkMessageCore
import UniverseDesignIcon

final class FlagImageMessageViewModel: FlagMessageCellViewModel {

    override class var identifier: String {
        return String(describing: FlagImageMessageViewModel.self)
    }

    override var identifier: String {
        return FlagImageMessageViewModel.identifier
    }

    var messageContent: ImageContent? {
        guard self.dynamicAuthorityEnum.authorityAllowed else { return nil }
        return self.message.content as? ImageContent
    }

    func showImage(withDispatcher dispatcher: RequestDispatcher, imageView: UIImageView) {
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
            self.chatSecurity?.authorityErrorHandler(event: .localImagePreview, authResult: self.permissionPreview.1, from: window, errorMessage: nil, forceToAlert: true)
            return
        }
        dispatcher.send(PreviewAssetActionMessage(
            imageView: imageView,
            source: .message(message)
        ))
        dump(PreviewAssetActionMessage(
            imageView: imageView,
            source: .message(message)
        ))
    }

    override public var needAuthority: Bool {
        return true
    }
}
