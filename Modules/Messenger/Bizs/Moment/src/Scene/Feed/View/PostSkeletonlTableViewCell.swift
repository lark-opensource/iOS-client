//
//  PostSkeletonlTableViewCell.swift
//  Moment
//
//  Created by zc09v on 2021/1/27.
//

import Foundation
import UIKit

final class PostSkeletonlTableViewCell: MomentsBaseSkeletonCell {
    override func initSubView() {
        contentView.backgroundColor = .clear
        self.addCirleView(size: 40, top: 16.5, left: 16)
        self.addBar(left: 64, topOffset: 24, width: 91, height: 17)
        self.addBar(left: 64, topOffset: 45, width: 54, height: 12)
        self.addBar(left: 64, topOffset: 68.5, right: 16, height: 17)
        self.addBar(left: 64, topOffset: 93.5, right: 108, height: 17)
        self.addCirleView(size: 20, top: 162, left: 75)
        self.addCirleView(size: 20, top: 162, left: 127)
        self.addCirleView(size: 20, top: 162, left: 179)
        self.addCirleView(size: 20, top: 162, right: 18)
    }
}
