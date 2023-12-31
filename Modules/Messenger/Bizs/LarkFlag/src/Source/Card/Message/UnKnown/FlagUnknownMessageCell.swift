//
//  FlagUnknownMessageCell.swift
//  LarkFeed
//
//  Created by phoenix on 2022/5/10.
//

import UIKit
import Foundation

final class FlagUnknownMessageCell: FlagMessageCell {
    override class var identifier: String {
        return FlagUnknownMessageViewModel.identifier
    }

    let unknownMessageView = FlagUnknownMessageView(frame: .zero)

    override public func setupUI() {
        selectionStyle = .none
        setupBackgroundViews(highlightOn: true)
        self.backgroundColor = UIColor.ud.bgBody
        self.swipeView.backgroundColor = .clear
        self.swipeView.addSubview(self.unknownMessageView)
        self.swipeView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
            make.bottom.equalTo(unknownMessageView)
        }
        unknownMessageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    override public func updateCellContent() {
    }
}
