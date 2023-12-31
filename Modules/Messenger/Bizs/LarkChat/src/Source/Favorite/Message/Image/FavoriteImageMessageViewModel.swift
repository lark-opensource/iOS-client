//
//  FavoriteImageMessageViewModel.swift
//  Lark
//
//  Created by lichen on 2018/6/7.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import LarkModel
import LarkContainer
import LarkCore
import EENavigator
import LarkMessageCore
import LarkMessengerInterface

final class FavoriteImageMessageViewModel: FavoriteMessageViewModel {

    override class var identifier: String {
        return String(describing: FavoriteImageMessageViewModel.self)
    }

    override var identifier: String {
        return FavoriteImageMessageViewModel.identifier
    }

    var messageContent: ImageContent? {
        guard self.dynamicAuthorityEnum.authorityAllowed else { return nil }
        return self.message.content as? ImageContent
    }

    lazy var permissionPreview: (Bool, ValidateResult?) = {
        return self.checkPermissionPreview()
    }()

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
            self.chatSecurity?.authorityErrorHandler(event: .localImagePreview, authResult: permissionPreview.1, from: window, errorMessage: nil, forceToAlert: true)
            return
        }
        dispatcher.send(PreviewAssetActionMessage(
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

final class NoPermissonPreviewSmallLayerView: UIView {
    var tapAction: ((_ gesture: UIGestureRecognizer) -> Void)?
    lazy var iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.ud.bgFloatOverlay
        imageView.image = Resources.no_preview_permission
        imageView.contentMode = .center
        return imageView
    }()
    init() {
        super.init(frame: .zero)
        self.backgroundColor = UIColor.ud.bgFloatOverlay
        self.addSubview(iconView)
        iconView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        self.lu.addTapGestureRecognizer(action: #selector(onTapped(gesture:)), target: self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func onTapped(gesture: UIGestureRecognizer) {
        if let tapAction = self.tapAction {
            tapAction(gesture)
        }
    }
}
