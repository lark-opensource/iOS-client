//
//  FlagFolderMessageCell.swift
//  LarkFeed
//
//  Created by phoenix on 2022/5/10.
//

import Foundation
import LarkUIKit

final class FlagFolderMessageCell: FlagMessageCell {

    private let folderView = FlagFolderView()

    override class var identifier: String {
        return FlagFolderMessageViewModel.identifier
    }

    var folderViewModel: FlagFolderMessageViewModel? {
        self.viewModel.dataDependency
        return viewModel as? FlagFolderMessageViewModel
    }

    override public func setupUI() {
        super.setupUI()
        contentWraper.addSubview(folderView)
        folderView.snp.makeConstraints { (make) in
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
            make.left.bottom.right.equalToSuperview()
        }
        folderView.tapBlock = { [weak self] (_, window) in
            guard let `self` = self else { return }
            self.folderViewModel?.folderViewTapped(withDispatcher: self.dispatcher, in: window)
        }
    }

    override public func updateCellContent() {
        super.updateCellContent()
        if let folderViewModel = folderViewModel {
            folderView.set(icon: folderViewModel.icon,
                           name: folderViewModel.name,
                           size: folderViewModel.size,
                           hasPermissionPreview: folderViewModel.permissionPreview.0,
                           dynamicAuthorityEnum: folderViewModel.dynamicAuthorityEnum)
        }
    }
}
