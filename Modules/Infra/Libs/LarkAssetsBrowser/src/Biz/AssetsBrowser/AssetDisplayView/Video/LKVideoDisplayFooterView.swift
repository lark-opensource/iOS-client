//
//  LKVideoDisplayFooterView.swift
//  LarkUIKit
//
//  Created by Yuguo on 2018/8/16.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit

protocol LKVideoDisplayFooterViewDelegate: AnyObject {
    func menuButtonDidClicked(_ sender: UIView)
    func assetsButtonDidClicked()
}

final class LKVideoDisplayFooterView: UIView {
    let moreButton = UIButton(type: .custom)
    private lazy var lookUpAssetButton = UIButton(type: .custom)
    private let buttonStack = UIStackView()

    private var timer: Timer?

    let startTimeLabel = UILabel.lu.labelWith(fontSize: 10, textColor: UIColor.white, text: "00:00")
    let endTimeLabel = UILabel.lu.labelWith(fontSize: 10, textColor: UIColor.white, text: "00:00")

    let slider = LKVideoSlider()

    weak var delegate: LKVideoDisplayFooterViewDelegate?

    init(showMoreButton: Bool, showAssetButton: Bool) {
        super.init(frame: .zero)

        let backView = GradientView()
        backView.backgroundColor = UIColor.clear
        backView.colors = [UIColor.black.withAlphaComponent(0.5), UIColor.black.withAlphaComponent(0)]
        backView.locations = [1.0, 0.0]
        backView.direction = .vertical
        self.addSubview(backView)
        backView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        startTimeLabel.textAlignment = .left
        startTimeLabel.font = startTimeLabel.font.withSize(14)
        self.addSubview(startTimeLabel)
        startTimeLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().inset(20)
            make.width.greaterThanOrEqualTo(27)
        }

        self.addSubview(buttonStack)
        buttonStack.alignment = .trailing
        buttonStack.spacing = 12
        if showAssetButton {
            buttonStack.addArrangedSubview(lookUpAssetButton)
            lookUpAssetButton.backgroundColor = UIColor.ud.N600.withAlphaComponent(0.6)
            lookUpAssetButton.layer.cornerRadius = 8
            lookUpAssetButton.setImage(Resources.asset_photo_lookup, for: .normal)
            lookUpAssetButton.snp.makeConstraints { (make) in
                make.size.equalTo(32)
            }
            lookUpAssetButton.addTarget(self, action: #selector(assetsButtonDidClicked), for: .touchUpInside)
        }
        if showMoreButton {
            buttonStack.addArrangedSubview(moreButton)
            moreButton.layer.cornerRadius = 8
            moreButton.backgroundColor = UIColor.ud.N600.withAlphaComponent(0.6)
            moreButton.setImage(Resources.asset_more, for: .normal)
            moreButton.snp.makeConstraints { (make) in
                make.size.equalTo(32)
            }
            moreButton.addTarget(self, action: #selector(menuButtonDidClicked(_:)), for: .touchUpInside)
        }
        buttonStack.snp.makeConstraints { (make) in
            make.centerY.equalTo(startTimeLabel)
            make.right.equalToSuperview().inset(20)
        }

        endTimeLabel.textAlignment = .right
        endTimeLabel.font = endTimeLabel.font.withSize(14)
        self.addSubview(endTimeLabel)
        endTimeLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(startTimeLabel)
            if buttonStack.arrangedSubviews.isEmpty {
                make.right.equalTo(-16)
            } else {
                make.right.equalTo(buttonStack.snp.left).offset(-16)
            }
            make.width.greaterThanOrEqualTo(27)
        }

        self.addSubview(slider)
        self.slider.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.left.equalTo(startTimeLabel.snp.right).offset(8)
            make.right.equalTo(endTimeLabel.snp.left).offset(-8)
        }

        let tap = UITapGestureRecognizer()
        self.addGestureRecognizer(tap)

        let pan = UIPanGestureRecognizer()
        self.addGestureRecognizer(pan)

        let longPress = UILongPressGestureRecognizer()
        self.addGestureRecognizer(longPress)

        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.bounds
        gradientLayer.colors = [UIColor.ud.N1000.withAlphaComponent(1),
                                UIColor.ud.N1000.withAlphaComponent(0.12),
                                UIColor.ud.N1000.withAlphaComponent(0)]
        self.layer.addSublayer(gradientLayer)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func remakeConstraintsBy(safeAreaInsets: UIEdgeInsets) {
        startTimeLabel.snp.remakeConstraints { (make) in
            make.centerY.equalToSuperview().offset(-safeAreaInsets.bottom / 2)
            make.left.equalTo(16)
        }

        slider.snp.remakeConstraints { (make) in
            make.left.equalTo(startTimeLabel.snp.right).offset(8)
            make.right.equalTo(endTimeLabel.snp.left).offset(-8)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview().offset(-safeAreaInsets.bottom)
        }
    }

    func setStartTimeLabel(time: String) {
        self.startTimeLabel.text = time
    }

    func setEndTimeLabel(time: String) {
        self.endTimeLabel.text = time
    }

    @objc
    private func menuButtonDidClicked(_ sender: UIView) {
        delegate?.menuButtonDidClicked(sender)
    }

    @objc
    private func assetsButtonDidClicked() {
        delegate?.assetsButtonDidClicked()
    }

    func setProgressHidden(_ hidden: Bool) {
        self.startTimeLabel.isHidden = hidden
        self.endTimeLabel.isHidden = hidden
        self.slider.isHidden = hidden
    }

    func scheduledTimer() {
        self.timer = Timer.scheduledTimer(timeInterval: 3,
                                          target: self,
                                          selector: #selector(timerHandler),
                                          userInfo: nil,
                                          repeats: false)
    }

    func invalidateTimer() {
        guard self.timer != nil else { return }
        self.timer?.invalidate()
        self.timer = nil
        self.setProgressHidden(false)
    }

    @objc
    private func timerHandler() {
        self.setProgressHidden(true)
    }
}
