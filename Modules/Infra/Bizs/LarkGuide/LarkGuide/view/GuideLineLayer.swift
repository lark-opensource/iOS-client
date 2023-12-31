//
//  GuideLineLayer.swift
//  LarkUIKit
//
//  Created by lichen on 2017/8/13.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignColor

open class GuideLineLayer: UIView {
    public struct Animation {
        var enabled: Bool = true
        var duration: (CFTimeInterval, CFTimeInterval, CFTimeInterval) = (0.25, 0.25, 0.25)
    }

    public var animation = Animation()
    public var startPoint: CGPoint = CGPoint.zero
    public var maskClickBlock: ((GuideLineLayer) -> Void)?

    // guide view 的布局规则
    // 当 guide view 居中，startPoint 在 view 竖直范围内的时候，保持居中
    // 否则 guide view 布局为在 startPoint 竖直方向上，并且添加一定的偏移
    fileprivate var guideView: UIView
    public var guideViewSize: CGSize

    public var lineColor = UIColor.ud.primaryOnPrimaryFill
    public var pointColor = UIColor.ud.primaryOnPrimaryFill
    public var pointWidth: CGFloat = 4
    public var lineWidth: CGFloat = 1
    public var lineLength: CGFloat = 23
    public var startPointOffset: CGFloat = 0
    public var maskColor = UIColor.clear

    fileprivate var pointView: UIView = UIView()
    fileprivate var lineLayer: UIView = UIView()
    fileprivate var maskBtn: UIButton = UIButton(type: .custom)
    fileprivate var offset: CGFloat = 6

    private var canvasSize: CGSize = UIScreen.main.bounds.size

    public init(guideView: UIView, size: CGSize) {
        self.guideView = guideView
        self.guideViewSize = size
        super.init(frame: CGRect.zero)
        self.initSubViews()
    }

    public func update(guideView: UIView, size: CGSize) {
        self.guideView.removeFromSuperview()
        self.guideView = guideView
        self.addSubview(self.guideView)
        self.guideViewSize = size
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initSubViews() {
        self.addSubview(self.maskBtn)
        self.addSubview(self.lineLayer)
        self.addSubview(self.pointView)
        self.addSubview(self.guideView)

        self.maskBtn.addTarget(self, action: #selector(clickMask), for: .touchUpInside)
        self.maskBtn.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    public func show(in canvas: UIView, canvasSize: CGSize = UIScreen.main.bounds.size) {
        self.canvasSize = canvasSize
        self.removeFromSuperview()
        canvas.addSubview(self)
        self.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        self.maskBtn.backgroundColor = self.maskColor
        self.updateSubViews()
        self.showAnimationIfNeed()
    }

    private func showAnimationIfNeed() {
        if !self.animation.enabled {
            return
        }

        setupLineLayer()

        let animationDurations = self.animation.duration

        let animation1 = BaseAnimationItem { [weak self] cb in
            guard let `self` = self else { return }
            UIView.animate(withDuration: animationDurations.0, animations: {
                self.pointView.alpha = 1
            }) { (_) in
                cb()
            }
        }

        let animation2 = BaseAnimationItem { [weak self] cb in
            guard let `self` = self else { return }

            self.lineLayer.snp.remakeConstraints { (make) in
                make.centerX.equalTo(self.pointView.snp.centerX)
                make.height.equalTo(self.lineLength)
                make.width.equalTo(self.lineWidth)
                if self.startPoint.y > self.canvasSize.height / 2 {
                    make.bottom.equalTo(self.pointView.snp.centerY)
                } else {
                    make.top.equalTo(self.pointView.snp.centerY)
                }
            }
            UIView.animate(withDuration: animationDurations.1, animations: {
                self.layoutIfNeeded()
            }) { (_) in
                cb()
            }
        }

        let animation3 = BaseAnimationItem { [weak self] cb in
            guard let `self` = self else { return }
            UIView.animate(withDuration: animationDurations.2, animations: {
                self.guideView.alpha = 1
            }) { (_) in
                cb()
            }
        }

        AnimationQueue().add(animation1).add(animation2).add(animation3).start()
    }

    private func setupLineLayer() {
        self.pointView.alpha = 0
        self.guideView.alpha = 0
        self.lineLayer.snp.remakeConstraints { (make) in
            make.centerX.equalTo(self.pointView.snp.centerX)
            make.height.equalTo(0)
            make.width.equalTo(self.lineWidth)
            if self.startPoint.y > self.canvasSize.height / 2 {
                make.bottom.equalTo(self.pointView.snp.centerY)
            } else {
                make.top.equalTo(self.pointView.snp.centerY)
            }
        }
        self.layoutIfNeeded()
    }

    private func updateSubViews() {
        self.updatePointAndLine()
        self.updateGuideView()
    }

    private func updatePointAndLine() {
        self.pointView.layer.cornerRadius = self.pointWidth / 2
        self.pointView.layer.masksToBounds = true
        self.pointView.backgroundColor = self.pointColor
        self.pointView.snp.remakeConstraints { (make) in
            make.width.height.equalTo(self.pointWidth)
            make.centerX.equalTo(self.startPoint.x)
            if self.startPoint.y > self.canvasSize.height / 2 {
                make.centerY.equalTo(self.startPoint.y - self.startPointOffset)
            } else {
                make.centerY.equalTo(self.startPoint.y + self.startPointOffset)
            }
        }

        self.lineLayer.backgroundColor = self.lineColor
        self.lineLayer.snp.remakeConstraints { (make) in
            make.centerX.equalTo(self.pointView.snp.centerX)
            make.height.equalTo(self.lineLength)
            make.width.equalTo(self.lineWidth)
            if self.startPoint.y > self.canvasSize.height / 2 {
                make.bottom.equalTo(self.pointView.snp.centerY)
            } else {
                make.top.equalTo(self.pointView.snp.centerY)
            }
        }
    }

    private func updateGuideView() {
        self.guideView.snp.remakeConstraints { (make) in
            make.width.equalTo(self.guideViewSize.width)
            make.height.equalTo(self.guideViewSize.height)
            if self.startPoint.y > self.canvasSize.height / 2 {
                make.bottom.equalTo(self.pointView.snp.centerY).offset(-self.lineLength)
            } else {
                make.top.equalTo(self.pointView.snp.centerY).offset(self.lineLength)
            }
            make.centerX.equalToSuperview().priority(.low)
            make.left.lessThanOrEqualTo(self.pointView.snp.centerX).offset(-self.offset).priority(.high)
            make.right.greaterThanOrEqualTo(self.pointView.snp.centerX).offset(self.offset).priority(.high)
        }
    }

    @objc
    private func clickMask() {
        self.maskClickBlock?(self)
    }
}
