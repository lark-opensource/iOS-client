//
//  ThreadNewOnboardingView.swift
//  ThreadNewOnboardingView
//
//  Created by 袁平 on 2021/9/15.
//

import Foundation
import UIKit
import UniverseDesignIcon

// https://www.figma.com/file/jvrCQCZdQ67nWJzTDm6nLi/IM?node-id=719%3A17302
final class ThreadNewOnboardingView: UIView {
    static var font: UIFont { UIFont.ud.body0 }
    static var minFont: UIFont { UIFont.ud.body2 }
    static let labelVerticalOffset: CGFloat = 10
    static let imageBottomOffset: CGFloat = 26

    private lazy var promptLabel: UILabel = {
        let promptLabel = UILabel()
        promptLabel.textColor = UIColor.ud.textTitle
        promptLabel.font = Self.font
        promptLabel.numberOfLines = 1
        promptLabel.adjustsFontSizeToFitWidth = true
        promptLabel.minimumScaleFactor = Self.minFont.pointSize / Self.font.pointSize
        promptLabel.text = BundleI18n.LarkThread.Lark_Moment_CreateTopicOnboardMobile
        return promptLabel
    }()

    private lazy var closeView: UIImageView = {
        let closeView = UIImageView(image: UDIcon.closeOutlined.ud.withTintColor(UIColor.ud.iconN2))
        closeView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(close))
        closeView.addGestureRecognizer(tap)
        return closeView
    }()

    private lazy var onboardingImage: UIImageView = UIImageView(image: Resources.empty_onboarding)
    var closeHandler: (() -> Void)?

    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        var closeFrame = closeView.frame
        // closeView热区扩大到44 x 44
        closeFrame = closeFrame.inset(by: UIEdgeInsets(top: -14, left: -14, bottom: -14, right: -14))
        if closeFrame.contains(point) {
            return closeView
        }
        return super.hitTest(point, with: event)
    }

    private func setupViews() {
        clipsToBounds = false
        addSubview(promptLabel)
        promptLabel.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-110)
            make.centerY.equalToSuperview()
        }

        addSubview(onboardingImage)
        onboardingImage.snp.makeConstraints { (make) in
            make.width.height.equalTo(120)
            make.bottom.equalToSuperview().offset(Self.imageBottomOffset)
            make.trailing.equalToSuperview().offset(12)
        }

        addSubview(closeView)
        closeView.snp.makeConstraints { (make) in
            make.width.height.equalTo(16)
            make.top.equalTo(onboardingImage).offset(26)
            make.leading.equalTo(onboardingImage.snp.trailing)
        }
    }

    @objc
    func close() {
        closeHandler?()
    }
}
