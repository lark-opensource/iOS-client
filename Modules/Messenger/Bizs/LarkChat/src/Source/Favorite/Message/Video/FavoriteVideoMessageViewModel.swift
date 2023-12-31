//
//  FavoriteVideoMessageViewModel.swift
//  LarkFavorite
//
//  Created by K3 on 2018/8/23.
//

import UIKit
import Foundation
import LarkModel
import LarkContainer
import LarkCore
import RustPB
import EENavigator
import LarkMessageCore
import LarkMessengerInterface

final class FavoriteVideoMessageViewModel: FavoriteMessageViewModel {

    override class var identifier: String {
        return String(describing: FavoriteVideoMessageViewModel.self)
    }

    override var identifier: String {
        return FavoriteVideoMessageViewModel.identifier
    }

    var messageContent: MediaContent? {
        guard self.dynamicAuthorityEnum.authorityAllowed else { return nil }
        return self.message.content as? MediaContent
    }

    lazy var permissionPreview: (Bool, ValidateResult?) = {
        return self.checkPermissionPreview()
    }()

    func showVideo(withDispatcher dispatcher: RequestDispatcher, imageView: UIImageView) {
        if !self.dynamicAuthorityEnum.authorityAllowed {
            self.chatSecurity?.alertForDynamicAuthority(event: .receive,
                                                       result: self.dynamicAuthorityEnum,
                                                       from: imageView.window)
            return
        }
        if !permissionPreview.0 {
            guard let window = imageView.window else {
                assertionFailure()
                return
            }
            self.chatSecurity?.authorityErrorHandler(event: .localVideoPreview, authResult: permissionPreview.1, from: window, errorMessage: nil, forceToAlert: true)
            return
        }
        let _: EmptyResponse? = dispatcher.send(PreviewAssetActionMessage(
            imageView: imageView,
            source: .message(message),
            downloadFileScene: .favorite,
            extra: [
                FileBrowseFromWhere.FileFavoriteKey: self.favorite.id
            ]
        ))
    }

    override public var needAuthority: Bool {
        return true
    }
}
