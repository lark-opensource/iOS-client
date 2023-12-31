//
//  FavoriteFileMessageCell.swift
//  Lark
//
//  Created by lichen on 2018/6/7.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit

final class FavoriteFileMessageCell: FavoriteMessageCell {

    private let fileView = FavoriteFileView()

    override class var identifier: String {
        return FavoriteFileMessageViewModel.identifier
    }

    var fileViewModel: FavoriteFileMessageViewModel? {
        return viewModel as? FavoriteFileMessageViewModel
    }

    override public func setupUI() {
        super.setupUI()
        contentWraper.addSubview(fileView)
        fileView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        fileView.tapBlock = { [weak self] (_, window) in
            guard let `self` = self else { return }
            self.fileViewModel?.fileViewTapped(withDispatcher: self.dispatcher, in: window)
        }
    }

    override public func updateCellContent() {
        super.updateCellContent()
        if let fileViewModel = fileViewModel {
            fileView.set(resolver: fileViewModel.userResolver,
                         icon: fileViewModel.icon,
                         name: fileViewModel.name,
                         size: fileViewModel.size,
                         hasPermissionPreview: fileViewModel.permissionPreview.0,
                         dynamicAuthorityEnum: fileViewModel.dynamicAuthorityEnum)
        }
    }
}
