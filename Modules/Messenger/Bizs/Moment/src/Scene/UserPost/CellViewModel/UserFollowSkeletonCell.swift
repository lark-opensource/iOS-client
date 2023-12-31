//
//  UserFollowSkeletonCell.swift
//  Moment
//
//  Created by liluobin on 2021/3/13.
//

import Foundation
import UIKit

final class UserFollowSkeletonCell: MomentsBaseSkeletonCell {

    private lazy var separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    override func initSubView() {
        self.addCirleView(size: 48, top: 10, left: 16)
        self.addBar(left: 76, topOffset: 26, width: 90, height: 17)
        self.addBar(right: 16, topOffset: 20, width: 70, height: 28)
        contentView.addSubview(separatorView)
        separatorView.snp.makeConstraints { (make) in
            make.right.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(76)
            make.height.equalTo(1 / UIScreen.main.scale)
        }
    }
}
