//
//  FlagFileMessageCell.swift
//  LarkFeed
//
//  Created by phoenix on 2022/5/10.
//

import Foundation
import UIKit
import LarkUIKit

final class FlagFileMessageCell: FlagMessageCell {

    private let fileView = FlagFileView()

    override class var identifier: String {
        return FlagFileMessageViewModel.identifier
    }

    var fileViewModel: FlagFileMessageViewModel? {
        return viewModel as? FlagFileMessageViewModel
    }

    override public func setupUI() {
        super.setupUI()
        contentWraper.addSubview(fileView)
        fileView.snp.makeConstraints { (make) in
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
            make.left.right.bottom.equalToSuperview()
        }
        fileView.tapBlock = { [weak self] (_, window) in
            guard let `self` = self else { return }
            self.fileViewModel?.fileViewTapped(withDispatcher: self.dispatcher, in: window)
        }
    }

    override public func updateCellContent() {
        super.updateCellContent()
        if let fileViewModel = fileViewModel {
            fileView.set(icon: fileViewModel.icon,
                         name: fileViewModel.name,
                         size: fileViewModel.size,
                         hasPermissionPreview: fileViewModel.permissionPreview.0,
                         dynamicAuthorityEnum: fileViewModel.dynamicAuthorityEnum)
        }
    }
}
