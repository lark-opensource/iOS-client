//
//  File.swift
//  LarkWorkplace
//  Widget 导航
//  Created by 李论 on 2020/5/24.
//

import Foundation
import UIKit
import LarkBadge
import UniverseDesignIcon
import LKCommonsLogging

final class WidgetNavBar: UIView {
    static let logger = Logger.log(WidgetNavBar.self)

    /// title Click
    var titleClick: (() -> Void)?
    /// expand Click
    var expandClick: ((UIButton) -> Void)?

    private var iconUrl: String?
    /// 展开收起热区尺寸
    private let expandIconHotSize: CGFloat = 22.0
    /// icon图标
    lazy var iconImgView = { () -> WPMaskImageView in
        let icon = WPMaskImageView()
        icon.backgroundColor = UIColor.ud.fillTag.alwaysLight
        icon.clipsToBounds = true
        icon.sqRadius = WPUIConst.AvatarRadius.xs5
        icon.sqBorder = WPUIConst.BorderW.pt1
        return icon
    }()
    /// 主标题
    lazy var mainTitleLabel = { () -> UILabel in
        let label = UILabel()
        // state 文字   字体应当使用 UD Token 初始化
        // swiftlint:disable init_font_with_token
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        // swiftlint:enable init_font_with_token
        label.textColor = UIColor.ud.textTitle.alwaysLight
        return label
    }()
    /// 标题栏热区容器
    lazy var titleContainerView: UIView = {
        let container = UIView()
        container.layer.cornerRadius = 4
        container.addGestureRecognizer(makeTapGesture())
        return container
    }()
    /// badge
    lazy var badgeView: BadgeView = {
        let view = BadgeView(with: .label(.number(0)))
        view.isHidden = true
        #if DEBUG
        view.isHidden = false
        #endif
        return view
    }()
    private func makeTapGesture() -> UITapGestureRecognizer {
        let tap = UITapGestureRecognizer(target: self, action: #selector(clickWidgetHeader(tap:)))
        tap.numberOfTapsRequired = 1
        tap.numberOfTouchesRequired = 1
        return tap
    }
    /// 展开按钮的热区
    lazy var expandBtnHotView: UIButton = {
        let btn = UIButton(type: .custom)
        btn.addTarget(self, action: #selector(clickExpandBtn(button:)), for: .touchUpInside)
        btn.isHidden = true
        btn.layer.cornerRadius = 4
        return btn
    }()
    /// 展开按钮的图标
    lazy var expandIconView: UIImageView = {
        let view = UIImageView()
        view.bdp_size = CGSize(width: avatarSideXS, height: avatarSideXS)
        view.image = UDIcon.downOutlined.ud.withTintColor(UIColor.ud.iconN3)
        return view
    }()

    /// 初始化
    init(iconUrl: String?, mainTitle: String?, frame: CGRect) {
        super.init(frame: frame)
        self.updateIcon(iconUrl: iconUrl)
        self.updateTitle(mainTitle: mainTitle)
        /// 配置导航栏
        setupView()
        /// 更新导航约束
        setNeedsUpdateConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 设置导航栏的View 布局
    func setupView() {
        self.addSubview(titleContainerView)
        titleContainerView.addSubview(iconImgView)
        titleContainerView.addSubview(mainTitleLabel)
        self.addSubview(expandBtnHotView)
        self.addSubview(badgeView)
        expandBtnHotView.addSubview(expandIconView)
        titleContainerView.addInteraction(type: .hover)
        expandBtnHotView.addInteraction(type: .hover)
    }

    /// 当约束更新时，自动适配约束
    override func updateConstraints() {
        titleContainerView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(13)
            make.right.lessThanOrEqualToSuperview().offset(-76)
            make.top.equalToSuperview().offset(11)
            make.bottom.equalToSuperview().offset(-4)
        }
        iconImgView.snp.remakeConstraints { (make) in
            make.size.equalTo(WPUIConst.AvatarSize.xs20)
            make.top.equalToSuperview().offset(5)
            make.left.equalToSuperview().offset(5)
        }
        mainTitleLabel.snp.remakeConstraints { (make) in
            make.centerY.equalTo(iconImgView)
            make.left.equalTo(iconImgView.snp.right).offset(8)
            make.right.lessThanOrEqualToSuperview().offset(-5)
        }
        expandBtnHotView.snp.makeConstraints { (make) in
            make.width.height.equalTo(expandIconHotSize)
            make.right.equalToSuperview().offset(-12)
            make.top.equalToSuperview().offset(14)
        }
        expandIconView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        badgeView.snp.makeConstraints { (make) in
            make.left.equalTo(titleContainerView.snp.right).offset(4)
            make.centerY.equalTo(iconImgView)
            make.right.lessThanOrEqualToSuperview().offset(-16)
        }
        super.updateConstraints()
    }

    /// 更新app icon
    func updateIcon(iconUrl: String?) {
        if let url = iconUrl, !url.isEmpty {
            self.iconUrl = url
            iconImgView.bt.setLarkImage(with: .avatar(
                key: url,
                entityID: "",
                params: .init(sizeType: .size(avatarSideXS))
            ))
        } else {
            Self.logger.warn("widget nar bar fresh icon failed because new iconKey is empty")
        }
    }

    /// 更新标题    fix: 需要确认空异常的策略，暂时-空异常不更新
    func updateTitle(mainTitle: String?) {
        if let mainT = mainTitle {
            mainTitleLabel.text = mainT
        } else {
            Self.logger.warn("widget nar bar fresh mainTitle failed because new text is empty")
        }
    }
    /// 设置是否展开
    func setExpand(expand: Bool) {
        WidgetView.log.info("update widget navbar expandState: \(expand)")
        let upOutlinedIcon = UDIcon.upOutlined.ud.withTintColor(UIColor.ud.iconN3)
        let downOutlinedIcon = UDIcon.downOutlined.ud.withTintColor(UIColor.ud.iconN3)
        let icon = expand ? upOutlinedIcon : downOutlinedIcon
        expandIconView.image = icon
    }
    /// 设置是否展开
    func setCanExpand(enable: Bool) {
        expandBtnHotView.isHidden = !enable
    }
    @objc
    func clickWidgetHeader(tap: UITapGestureRecognizer) {
        Self.logger.info("widget's header clicked for \(String(describing: iconUrl))")
        titleClick?()
    }
    @objc
    func clickExpandBtn(button: UIButton) {
        Self.logger.info("expand clicked for \(String(describing: mainTitleLabel.text))")
        expandClick?(button)
    }
    /// 设置Badge数字
    func setBadgeNum(num: Int?) {
        if let displayNum = num {
            badgeView.updateNumber(to: displayNum)
            badgeView.isHidden = false
        } else {
            badgeView.isHidden = true
        }
    }
}
