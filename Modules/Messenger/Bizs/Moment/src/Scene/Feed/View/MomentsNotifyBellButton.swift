//
//  MomentsNotifyBellButton.swift
//  Moment
//
//  Created by bytedance on 2021/8/30.
//

import Foundation
import UIKit
import UniverseDesignBadge
import LarkNavigation

final class MomentsNotifyBellButton: UIButton, LarkNaviBarButtonDelegate {
    func larkNaviBarSetButtonTintColor(_ tintColor: UIColor, for state: UIControl.State) {
        if state == .normal {
            imageCover.tintColor = tintColor
            imageColumn.tintColor = tintColor
        }
    }
    //🔔上面的遮罩
    private lazy var imageCover: UIImageView = {
        let view = UIImageView(frame: CGRect(x: 2, y: 1.5, width: 20, height: 17))
        view.image = Resources.bellCoverOutlined.withRenderingMode(.alwaysTemplate)
        return view
    }()
    //🔔芯，即下面的杠
    private lazy var imageColumn: UIImageView = {
        let view = UIImageView()
        view.image = Resources.bellColumnOutlined.withRenderingMode(.alwaysTemplate)
        return view
    }()

    init() {
        super.init(frame: .zero)
        setupSubview()
        badge = addBadge(.number, anchor: .topRight, anchorType: .rectangle)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupBadge(messageCount: Int, reactionCount: Int) -> UDBadge? {
        guard let badge = badge else {
            return nil
        }
        badge.config.number = messageCount + reactionCount
        badge.isHidden = badge.config.number <= 0
        badge.config.maxNumber = MomentTab.maxBadgeCount
        badge.config.style = .characterBGRed
        badge.config.contentStyle = .custom(UIColor.ud.primaryOnPrimaryFill)
        return badge
    }

    private func setupSubview() {
        addSubview(imageCover)
        imageCover.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(2)
            make.right.equalToSuperview().offset(-2)
            make.top.equalToSuperview().offset(1.5)
        }
        addSubview(imageColumn)
        imageColumn.snp.makeConstraints { make in
            make.top.equalTo(imageCover.snp.bottom).offset(1.5)
            make.centerX.equalToSuperview()
            make.height.equalTo(2)
            make.width.equalTo(6)
        }
    }

    private var timeWhenAnimationBegin: Double?
    private var animationDelay = 0.0

    //开始摇铃铛动画
    func startAnimation(delay: Double) {
        if timeWhenAnimationBegin == nil {
            animationDelay = delay
            let displayLink = CADisplayLink(target: self, selector: #selector(shakeBell(_:)))
            displayLink.add(to: .current, forMode: .common)
        }
    }

    @objc
    private func shakeBell(_ sender: CADisplayLink) {
        guard let startTime = timeWhenAnimationBegin else {
            timeWhenAnimationBegin = sender.timestamp
            return
        }
        let time = sender.timestamp - startTime - animationDelay
        if time < 0 {
            return
        }
        let rCover = sin(time * 16) * 50 / 180 * Double.pi / exp(time * 4)
        if time > 3 {
            imageCover.transform = CGAffineTransform(rotationAngle: 0)
            imageColumn.transform = CGAffineTransform(rotationAngle: 0)
            sender.invalidate()
            return
        }
        imageCover.transform = getTransfrom(center: CGPoint(x: 0, y: -10), rotate: CGFloat(rCover))
        let delay = 0.02
        var rColumn = 0.0
        if time > delay {
            let delay_t = time - delay
            if time > 1 {
                let amp = time * 14
                rColumn = sin(delay_t * 8) * amp / 180 * Double.pi / exp(delay_t * 1.7)
            } else {
                let amp = 10.0
                rColumn = sin(delay_t * 14) * amp / 180 * Double.pi / exp(delay_t)
            }
        }
        imageColumn.transform = getTransfrom(center: CGPoint(x: 0, y: -21), rotate: CGFloat(rColumn))
    }

    func getTransfrom(center: CGPoint, rotate: CGFloat) -> CGAffineTransform {
        /**
         原坐标 (x, y)，新坐标(x', y')
         x' = ax + cy + tx
         y' = bx + dy + ty
         绕center旋转rotate，做线性变换
         */
        return CGAffineTransform(a: cos(rotate),
                                 b: sin(rotate),
                                 c: -sin(rotate),
                                 d: cos(rotate),
                                 tx: center.x - center.x * cos(rotate) + center.y * sin(rotate),
                                 ty: center.y - center.x * sin(rotate) - center.y * cos(rotate))
    }
}
