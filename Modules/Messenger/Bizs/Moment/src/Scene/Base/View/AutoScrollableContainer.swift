//
//  AutoScrollableContainer.swift
//  Moment
//
//  Created by ByteDance on 2023/1/31.
//

import UIKit
import Foundation

//当childView的height大于self的height，允许上下滑动；
//当childView的width大于self的width，childView被截断，不能左右滑动；
class AutoScrollableContainer: UIScrollView {
    override var bounds: CGRect {
        didSet {
            self.updateScrollEnable()
        }
    }
    var contentHeight: CGFloat { //contentSize的height
        didSet {
            self.updateScrollEnable()
        }
    }
    override var contentSize: CGSize {
        didSet {
            if contentSize.width > self.bounds.width {
                self.updateScrollEnable()
            }
        }
    }

    let childViewHeight: CGFloat
    let childView: UIView
    init(contentHeight: CGFloat, childView: UIView, childViewHeight: CGFloat) {
        self.contentHeight = contentHeight
        self.childView = childView
        self.childViewHeight = childViewHeight
        super.init(frame: .zero)
        addSubview(childView)
        childView.snp.makeConstraints { make in
            make.left.top.width.equalToSuperview()
            make.height.equalTo(childViewHeight)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

    }

    private func updateScrollEnable() {
        self.isScrollEnabled = bounds.height < contentHeight
        self.contentSize = .init(width: bounds.width, height: max(bounds.height, contentHeight))
    }
}
