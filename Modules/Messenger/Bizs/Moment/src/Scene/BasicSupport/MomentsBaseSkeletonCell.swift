//
//  MomentsBaseSkeletonCell.swift
//  Moment
//
//  Created by liluobin on 2021/3/13.
//

import Foundation
import UIKit
import SkeletonView
import LarkUIKit

class MomentsBaseSkeletonCell: BaseTableViewCell, SkeletonCell {
    override var frame: CGRect {
        didSet {
            if Display.pad {
                super.frame = MomentsViewAdapterViewController.computeCellFrame(originFrame: frame)
            }
        }
    }

    private let gradient = SkeletonGradient(baseColor: UIColor.ud.N200.withAlphaComponent(0.5),
                                            secondaryColor: UIColor.ud.N200)
    static var identifier: String {
        return Self.lu.reuseIdentifier
    }
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.isSkeletonable = true
        self.selectionStyle = .none
        self.initSubView()
        self.layoutIfNeeded()
        self.showAnimatedGradientSkeleton(usingGradient: gradient)
        self.startSkeletonAnimation()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func initSubView() {

    }
}
