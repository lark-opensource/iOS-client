//
//  FavoriteMergeForwardMessageCell.swift
//  Lark
//
//  Created by lichen on 2018/6/7.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import LarkModel
import LarkUIKit
import LarkCore
import LarkContainer

final class FavoriteMergeForwardMessageCell: FavoriteMessageCell {

    override class var identifier: String {
        return FavoriteMergeForwardMessageViewModel.identifier
    }

    var mergeForwardView: MergeForwardView = .init(tapHandler: nil)

    override public func setupUI() {
        super.setupUI()

        // mergeForwardView
        let mergeForwardView = MergeForwardView(tapHandler: nil)
        mergeForwardView.isUserInteractionEnabled = false
        self.contentWraper.addSubview(mergeForwardView)
        mergeForwardView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        self.mergeForwardView = mergeForwardView
    }

    override public func updateCellContent() {
        super.updateCellContent()

        guard let mergeForwardVM = self.viewModel as? FavoriteMergeForwardMessageViewModel else {
            return
        }
        self.mergeForwardView.set(
            contentMaxWidth: self.bubbleContentMaxWidth,
            title: mergeForwardVM.title,
            attributeText: mergeForwardVM.contentText
        )
    }
}
