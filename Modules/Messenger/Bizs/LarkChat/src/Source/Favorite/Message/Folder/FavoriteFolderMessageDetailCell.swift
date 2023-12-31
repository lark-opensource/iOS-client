//
//  FavoriteFolderMessageDetailCell.swift
//  LarkChat
//
//  Created by 赵家琛 on 2021/4/21.
//

import Foundation

final class FavoriteFolderMessageDetailCell: FavoriteMessageDetailCell {

    private let folderView = FavoriteFolderView()

    override class var identifier: String {
        return FavoriteFolderMessageViewModel.identifier
    }

    var folderViewModel: FavoriteFolderMessageViewModel? {
        return viewModel as? FavoriteFolderMessageViewModel
    }

    override public func setupUI() {
        super.setupUI()
        container.addSubview(folderView)
        folderView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        folderView.tapBlock = { [weak self] (_, window) in
            guard let `self` = self else { return }
            self.folderViewModel?.folderViewTapped(withDispatcher: self.dispatcher, in: window)
        }
    }

    override public func updateCellContent() {
        super.updateCellContent()
        if let folderViewModel = folderViewModel {
            folderView.set(userResolver: folderViewModel.userResolver,
                           icon: folderViewModel.icon,
                           name: folderViewModel.name,
                           size: folderViewModel.size,
                           hasPermissionPreview: folderViewModel.permissionPreview.0,
                           dynamicAuthorityEnum: folderViewModel.dynamicAuthorityEnum)
        }
    }
}
