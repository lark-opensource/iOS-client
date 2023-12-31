//
//  NoticeSkeletonViewCell.swift
//  Moment
//
//  Created by bytedance on 2021/2/26.
//

import Foundation
import UIKit

final class NoticeMessageSkeletonViewCell: MomentsBaseSkeletonCell {
    override func initSubView() {
        // 这里tableview使用了预估高度 所以需要约束撑开
        let bgView = UIView()
        bgView.backgroundColor = UIColor.ud.bgBody
        self.contentView.addSubview(bgView)
        bgView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
            make.height.equalTo(99)
        }
        self.addCirleView(size: 48, top: 16, left: 16)
        self.addBar(left: 72, topOffset: 16, right: 24 + 54 + 10, height: 17)
        self.addBar(left: 72, topOffset: 41, right: 56 + 54 + 16, height: 17)
        self.addBar(left: 72, topOffset: 66, width: 61, height: 17)
        self.addBar(right: 16, topOffset: 16, width: 54, height: 54)
    }
}
