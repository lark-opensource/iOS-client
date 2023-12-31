//
//  NoticeReactionSkeletonViewCell.swift
//  Moment
//
//  Created by liluobin on 2021/2/28.
//

import Foundation
import UIKit

final class NoticeReactionSkeletonViewCell: MomentsBaseSkeletonCell {
    override func initSubView() {
        // 这里tableview使用了预估高度 所以需要约束撑开
        let bgView = UIView()
        bgView.backgroundColor = UIColor.ud.bgBody
        self.contentView.addSubview(bgView)
        bgView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
            make.height.equalTo(86)
        }
        self.addCirleView(size: 48, top: 19, left: 16)
        self.addBar(left: 72, topOffset: 22, right: 54 + 16 + 18, height: 17)
        self.addBar(left: 72, topOffset: 47, width: 61, height: 17)
        self.addBar(right: 16, topOffset: 16, width: 54, height: 54)
    }

}
