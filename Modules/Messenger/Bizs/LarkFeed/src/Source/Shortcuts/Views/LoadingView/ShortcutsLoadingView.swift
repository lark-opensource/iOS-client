//
//  ShortcutsLoadingView.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/6/15
//

import UIKit
import Foundation
import SnapKit
import LarkUIExtension

final class ShortcutsLoadingView: UIView {
    private var leftDot: UIView
    private var centerDot: UIView
    private var rightDot: UIView
    static let centerDotRadiu: CGFloat = 3.5
    static let otherDotRadiu: CGFloat = 2.5

    var percentage: CGFloat = 0 {
        didSet {
            updateSubviews()
        }
    }

    override init(frame: CGRect) {
        leftDot = Self.creatDotView(Self.otherDotRadiu)
        centerDot = Self.creatDotView(Self.centerDotRadiu)
        rightDot = Self.creatDotView(Self.otherDotRadiu)
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.bgBody
        self.addSubview(leftDot)
        self.addSubview(centerDot)
        self.addSubview(rightDot)
        self.clipsToBounds = true

        centerDot.snp.makeConstraints { (make) in
            make.centerX.top.equalToSuperview()
            make.height.equalTo(Self.centerDotRadiu * 2)
            make.width.equalTo(Self.centerDotRadiu * 2)
        }
        leftDot.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.centerDot)
            make.centerY.equalTo(self.centerDot)
            make.height.equalTo(Self.otherDotRadiu * 2)
            make.width.equalTo(Self.otherDotRadiu * 2)
        }
        rightDot.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.centerDot)
            make.centerY.equalTo(self.centerDot)
            make.height.equalTo(Self.otherDotRadiu * 2)
            make.width.equalTo(Self.otherDotRadiu * 2)
        }
        updateSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateSubviews() {
        let maxOffSetX: CGFloat = 8

        var radioX: CGFloat = 0
        var scale: CGFloat = 0

        if percentage <= 0.5 {
            scale = percentage * 2
        } else if percentage <= 1 {
            scale = 1
            radioX = (percentage - 0.5) * 2
        } else {
            scale = 1
            radioX = 1
        }

        leftDot.snp.updateConstraints { (make) in
            make.centerX.equalTo(self.centerDot).offset(-maxOffSetX * radioX)
        }
        rightDot.snp.updateConstraints { (make) in
            make.centerX.equalTo(self.centerDot).offset(maxOffSetX * radioX)
        }

        let trans = CGAffineTransform(scaleX: scale, y: scale)
        centerDot.transform = trans
        leftDot.transform = trans
        rightDot.transform = trans
    }

    class func creatDotView(_ radius: CGFloat) -> UIView {
        let dot = UIView(frame: CGRect(x: 0, y: 0, width: radius * 2.0, height: radius * 2.0))
        dot.layer.cornerRadius = radius
        dot.layer.masksToBounds = true
        dot.backgroundColor = UIColor.ud.iconN3
        return dot
    }
}
