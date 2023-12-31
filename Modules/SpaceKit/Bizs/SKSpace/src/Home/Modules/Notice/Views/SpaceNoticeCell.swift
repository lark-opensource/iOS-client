//
//  SpaceNoticeCell.swift
//  SKECM
//
//  Created by Weston Wu on 2020/11/25.
//

import UIKit
import SnapKit
import SKCommon
import SKUIKit

class SpaceNoticeCell: UICollectionViewCell {

    private var noticeContentView: UIView?

    override func prepareForReuse() {
        super.prepareForReuse()
        noticeContentView?.removeFromSuperview()
        noticeContentView = nil
    }

    func update(noticeContentView: UIView) {
        self.noticeContentView = noticeContentView
        contentView.addSubview(noticeContentView)
        noticeContentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
