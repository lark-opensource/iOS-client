//
//  BadgeContainer.swift
//  UGBadge
//
//  Created by liuxianyu on 2021/11/26.
//

import UIKit
import Foundation

final class BadgeContainer: UIView {
    private var lastBadgeView: UIView?
    private var contentSize: CGSize = .zero
    weak var delegate: LarkBadgeDelegate?
    var badgeData: BadgeInfo?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        return contentSize
    }

    override func layoutSubviews() {
        if self.frame.width != contentSize.width, let badgeData = badgeData {
            _ = onUpdateData(badgeData: badgeData)
        }
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if let superview = self.superview {
            // 被加到父视图时候进行曝光埋点
            delegate?.onBadgeShow()
        }
    }

    func onUpdateData(badgeData: BadgeInfo) -> Bool {
        self.badgeData = badgeData
        let badgeWidth = self.frame.width
        guard badgeWidth > 0,
              let (badgeView, badgeHeight) = LarkBadgeViewFactory
                .createBadgeView(badgeData: LarkBadgeData(badgeInfo: badgeData),
                                  badgeWidth: self.frame.width) else {
            return false
        }
        badgeView.delegate = delegate
        if let lastBadgeView = lastBadgeView { lastBadgeView.removeFromSuperview() }
        lastBadgeView = badgeView
        self.addSubview(badgeView)
        badgeView.frame = CGRect(x: 0, y: 0, width: badgeWidth, height: badgeHeight)
        contentSize = CGSize(width: badgeWidth, height: badgeHeight)
        self.invalidateIntrinsicContentSize()
        return true
    }

    func onHide() {
        lastBadgeView?.removeFromSuperview()
        lastBadgeView = nil
        badgeData = nil
        contentSize = CGSize(width: self.frame.width, height: 0)
        self.invalidateIntrinsicContentSize()
    }
}
