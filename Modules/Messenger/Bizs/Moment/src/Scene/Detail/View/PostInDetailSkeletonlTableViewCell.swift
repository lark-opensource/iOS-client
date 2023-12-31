//
//  PostInDetailSkeletonlTableViewCell.swift
//  Moment
//
//  Created by zc09v on 2021/1/27.
//

import Foundation
import UIKit
final class PostInDetailSkeletonlTableViewCell: MomentsBaseSkeletonCell {
    override func initSubView() {
        addCirleView(size: 40, top: 16, left: 16)
        addBar(left: 64, topOffset: 24, width: 91, height: 17)
        addBar(left: 64, topOffset: 45, width: 54, height: 12)
        addBar(right: 16, topOffset: 19, width: 64, height: 28)
        addBar(left: 16, topOffset: 76, right: 16, height: 17)
        addBar(left: 16, topOffset: 101, width: 195, height: 17)
        addCirleView(size: 20, top: 262, left: 16)
        addCirleView(size: 20, top: 262, left: 68)
        addCirleView(size: 20, top: 262, left: 120)
        addCirleView(size: 20, top: 262, right: 18)
    }
}
