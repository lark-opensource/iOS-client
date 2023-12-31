//
//  RedPacketNaviBar.swift
//  LarkFinance
//
//  Created by SuPeng on 3/31/19.
//

import Foundation
import UIKit
import LarkUIKit
import ByteWebImage
import LarkBizAvatar
import LarkSDKInterface

enum RedPacketHeaderViewDismissType {
    case back
    case close
}

protocol RedPacketNaviBarDelegate: AnyObject {
    func naviBarDidClickBackOrCloseButton(_ naviBar: RedPacketNaviBar)
    func naviBarDidClickHistoryButton(_ naviBar: RedPacketNaviBar)
}

final class RedPacketNaviBar: UIView {
    weak var delegate: RedPacketNaviBarDelegate?
    let imageViewBottomMargin: CGFloat = 7

    lazy var blackMask = UIImageView(image: Resources.hongbao_result_mask)
    let imageView: ByteImageView = ByteImageView()
    let titleLabel = UILabel()
    let backButton = UIButton()
    let historyButton = UIButton()
    private let bottomShadow = UIImageView(image: Resources.hongbao_result_bottom_shadow)
    private var cover: HongbaoCover?
    private var isShowMask: Bool {
        self.cover?.hasID ?? false
    }
    private lazy var topAvatar = BizAvatar()
    private lazy var defaultThemeImage = Resources.hongbao_open_top
    private lazy var topAvatarBorder = UIImageView(image: Resources.hongbao_result_avatar_border)

    init(cover: HongbaoCover? = nil,
         isShowAvatr: Bool,
         currentUserId: String,
         currentAvatarKey: String) {
        self.cover = cover
        super.init(frame: .zero)
        self.isUserInteractionEnabled = true
        backgroundColor = .clear

        let titleColor = UIColor.ud.Y200.alwaysLight

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        addSubview(imageView)
        if let cover = cover, cover.hasID {
            var pass = ImagePassThrough()
            pass.key = cover.headCover.key
            pass.fsUnit = cover.headCover.fsUnit
            imageView.bt.setLarkImage(with: .default(key: cover.headCover.key),
                                      placeholder: defaultThemeImage,
                                      passThrough: pass)
        } else {
            imageView.bt.setLarkImage(with: .default(key: ""),
                                      placeholder: defaultThemeImage)
        }

        if isShowMask {
            addSubview(blackMask)
        }

        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = titleColor
        addSubview(titleLabel)

        backButton.setImage(Resources.red_packet_back, for: .normal)
        backButton.addTarget(self, action: #selector(closeOrBackButtonDidClick), for: .touchUpInside)
        addSubview(backButton)

        historyButton.setTitleColor(titleColor, for: .normal)
        historyButton.setTitle(BundleI18n.LarkFinance.Lark_Legacy_History, for: .normal)
        historyButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        historyButton.addTarget(self, action: #selector(historyButtonDidClick), for: .touchUpInside)
        addSubview(historyButton)
        addSubview(bottomShadow)

        addSubview(topAvatar)
        topAvatar.snp.makeConstraints { make in
            make.width.height.equalTo(48)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(18)
        }
        addSubview(topAvatarBorder)
        topAvatarBorder.snp.makeConstraints { make in
            make.width.height.equalTo(72)
            make.center.equalTo(topAvatar)
        }

        topAvatar.isHidden = !isShowAvatr
        topAvatarBorder.isHidden = !isShowAvatr
        if isShowAvatr {
            topAvatar.setAvatarByIdentifier(currentUserId, avatarKey: currentAvatarKey, avatarViewParams: .init(sizeType: .size(48)))
        } else {
            topAvatar.setAvatarByIdentifier("", avatarKey: "", avatarViewParams: .init(sizeType: .size(48)))
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height - imageViewBottomMargin)

        if isShowMask {
            blackMask.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: 132)
        }

        bottomShadow.frame.size = CGSize(width: bounds.width, height: 38)
        bottomShadow.frame.bottom = self.frame.bottom + 10

        backButton.frame.size = CGSize(width: 48, height: 48)
        backButton.frame.top = 44
        backButton.frame.left = 4

        titleLabel.sizeToFit()
        titleLabel.alpha = 0
        titleLabel.frame.left = backButton.frame.right + 10.5
        titleLabel.frame.centerY = backButton.frame.centerY

        historyButton.sizeToFit()
        historyButton.frame.right = bounds.right - 12
        historyButton.frame.centerY = backButton.frame.centerY
    }

    func set(dismissType: RedPacketHeaderViewDismissType, title: String?) {
        switch dismissType {
        case .back:
            backButton.setImage(Resources.red_packet_back, for: .normal)
        case .close:
            backButton.setImage(Resources.red_packet_result_close, for: .normal)
        }
        titleLabel.text = title
        setNeedsLayout()
    }

    func updateTitleLabel(alpha: CGFloat) {
        titleLabel.alpha = alpha
    }

    @objc
    private func historyButtonDidClick() {
        delegate?.naviBarDidClickHistoryButton(self)
    }

    @objc
    private func closeOrBackButtonDidClick() {
        delegate?.naviBarDidClickBackOrCloseButton(self)
    }
}

extension RedPacketNaviBar {
    /// 红包结果页面的导航栏占用 Status Bar 的高度
    static func redPacketStatusBarHeight() -> CGFloat {
        if Display.iPhoneXSeries {
            return 44
        } else {
            if #available(iOS 13.0, *), Display.pad {
                // iPadOS 13 及以上的红包页面使用不侵入状态栏的模态弹窗，不需要占位高度
                return 0
            } else {
                return 20
            }
        }

    }
}
