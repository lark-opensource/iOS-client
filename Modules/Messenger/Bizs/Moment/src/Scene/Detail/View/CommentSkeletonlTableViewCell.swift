//
//  CommentSkeletonlTableViewCell.swift
//  Moment
//
//  Created by zc09v on 2021/1/27.
//

import Foundation
import UIKit

final class CommentSkeletonlTableViewCell: MomentsBaseSkeletonCell {
    override func initSubView() {
        addCirleView(size: 24, top: 8, left: 16)
        addBar(left: 48, topOffset: 8, width: 54, height: 12)
        addBar(left: 48, topOffset: 28, right: 16, height: 17)
        addBar(left: 48, topOffset: 53, right: 169, height: 17)
        addCirleView(size: 16, top: 95, right: 17)
    }
}
