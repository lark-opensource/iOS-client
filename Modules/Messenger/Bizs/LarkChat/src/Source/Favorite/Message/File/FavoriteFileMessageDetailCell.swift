//
//  FavoriteFileMessageDetailCell.swift
//  LarkFavorite
//
//  Created by liuwanlin on 2018/6/14.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation

final class FavoriteFileMessageDetailCell: FavoriteMessageDetailCell {

    private let fileView = FavoriteFileView()

    override class var identifier: String {
        return FavoriteFileMessageViewModel.identifier
    }

    var fileViewModel: FavoriteFileMessageViewModel? {
        return viewModel as? FavoriteFileMessageViewModel
    }

    override public func setupUI() {
        super.setupUI()
        container.addSubview(fileView)
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
