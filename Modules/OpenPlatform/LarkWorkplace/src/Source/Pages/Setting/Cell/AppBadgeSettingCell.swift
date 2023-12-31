//
//  AppBadgeSettingCell.swift
//  LarkWorkplace
//
//  Created by houjihu on 2020/12/20.
//

import Foundation
import LarkUIKit
import UIKit
import SnapKit
import LarkLocalizations
import LKCommonsLogging
import LKCommonsTracker

/// 「应用角标设置」列表中显示的应用角标设置cell
final class AppBadgeSettingCell: UICollectionViewCell {
    /// 负责「应用角标设置」页cell相关的log输出
    static let logger = Logger.log(AppBadgeSettingCell.self)
    /// cell 配置
    enum Config {
        /// cell height
        static let cellHeight = 52
        /// reuse ID
        static let reuseID: String = "AppBadgeSettingCellReuseID"
    }

    /// 屏幕左右间距
    let screenMargin: CGFloat = 16.0
    /// 一般view的间距（排序页Cell的视图通用设计）
    let commonMargin: CGFloat = 12.0
    /// 内容容器
    private lazy var container: UIView = {
        return UIView()
    }()
    /// Cell的图标
    private lazy var logoView: WPMaskImageView = {
        let logoView = WPMaskImageView()
        logoView.backgroundColor = UIColor.clear
        logoView.clipsToBounds = true
        logoView.sqBorder = WPUIConst.BorderW.pt1
        logoView.sqRadius = WPUIConst.AvatarRadius.small
        return logoView
    }()
    /// Cell的标题
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14.0)
        label.textColor = UIColor.ud.textTitle
        label.backgroundColor = .clear
        label.textAlignment = .left
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    /// Cell的开关
    private lazy var badgeStatusSwitch: UISwitch = {
        let sw = UISwitch()
        sw.onTintColor = UIColor.ud.primaryContentDefault
        sw.tintColor = UIColor.ud.N300
        sw.addTarget(self, action: #selector(notificationChanged(sender:)), for: .valueChanged)
        return sw
    }()
    /// 分割线-bottom
    private lazy var bottomDividerLine: UIView = {
        let deviderLine = UIView()
        deviderLine.backgroundColor = UIColor.ud.lineDividerDefault
        return deviderLine
    }()
//    /// 分割线-top
//    private lazy var topDividerLine: UIView = {
//        let deviderLine = UIView()
//        deviderLine.backgroundColor = UIColor.ud.lineDividerDefault
//        return deviderLine
//    }()
    /// 标识应用相关单元格位置
    private var position: AppCollectionCellPosition = .middle
    /// data
    private var itemInfo: AppBadgeSettingItem?
    /// view model
    private var viewModel: AppBadgeSettingViewModel?
    /// index path in collection
    private var indexPath: IndexPath?
    /// 屏幕底部显示请求错误相关提示
    private var showRequestFailPromptBlock: (() -> Void)?

    // MARK: cell 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // 设置圆角
        let maskPath: UIBezierPath?
        if position == .top {
            maskPath = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 10, height: 10))
        } else if position == .bottom {
            maskPath = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: [.bottomLeft, .bottomRight], cornerRadii: CGSize(width: 10, height: 10))
        } else if position == .topAndBottom {
            maskPath = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: [.topLeft, .topRight, .bottomLeft, .bottomRight], cornerRadii: CGSize(width: 10, height: 10))
        } else {
            // 中间的话不需要设置圆角
            maskPath = nil
        }
        if let mask = maskPath {
            let shape = CAShapeLayer()
            shape.path = mask.cgPath
            self.layer.mask = shape
        }
    }

    // MARK: setup views & constraints
    func setupViews() {
        backgroundColor = UIColor.clear
        contentView.backgroundColor = UIColor.ud.bgBody
        contentView.addSubview(bottomDividerLine)
        contentView.addSubview(container)
        container.addSubview(logoView)
        container.addSubview(badgeStatusSwitch)
        container.addSubview(titleLabel)

//        contentView.addSubview(topDividerLine)
//        // topDividerLine默认不可见
//        topDividerLine.isHidden = true
        bottomDividerLine.snp.makeConstraints { make in
            make.height.equalTo(0.5)
            make.bottom.right.equalToSuperview()
            make.left.equalTo(titleLabel)
        }
//        topDividerLine.snp.makeConstraints { make in
//            make.height.equalTo(0.5)
//            make.top.left.right.equalToSuperview()
//        }

        container.snp.makeConstraints { make in
            make.height.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(screenMargin)
            make.right.equalToSuperview().offset(-screenMargin)
        }

        logoView.snp.makeConstraints { make in
            make.size.equalTo(WPUIConst.AvatarSize.small)
            make.centerY.left.equalToSuperview()
        }

        badgeStatusSwitch.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(logoView.snp.right).offset(commonMargin)
            make.right.equalTo(badgeStatusSwitch.snp.left).offset(-8)
        }
    }

    @objc
    /// 调用更新badge提醒状态的接口
    private func notificationChanged(sender: UISwitch) {
        let shouldShow = sender.isOn
        guard let itemInfo = itemInfo else {
            Self.logger.error("itemInfo is nil")
            return
        }
        guard let viewModel = viewModel else {
            Self.logger.error("viewModel is nil")
            return
        }
        /** 请求修改数据失败后，还原原来的状态
        guard let indexPath = indexPath else {
            Self.logger.error("indexPath is nil")
            return
        }
         */

        /// 产品埋点 for 「用户对 badge 进行开关操作」
        var trackParams = [AnyHashable: Any]()
        trackParams["app_id"] = itemInfo.clientID
        trackParams["appname"] = appName(for: itemInfo)
        trackParams["action"] = shouldShow ? "open" : "close"
        trackParams["source"] = "appcenter_setting"
        Tracker.post(TeaEvent("app_setting_set_Badge", params: trackParams))

        viewModel.updateStatus(
            shouldShow: shouldShow,
            appBadgeSettingItem: itemInfo,
            callback: { [weak self] success in
                Self.logger.info("updateStatus success(\(success)")
                guard let `self` = self else {
                    return
                }
                if !success, let showRequestFailPromptBlock = self.showRequestFailPromptBlock {
                    showRequestFailPromptBlock()
                }
                /** 请求修改数据失败后，还原原来的状态
                // 判断cell是否还位于原来的位置
                if indexPath != self.indexPath {
                    return
                }
                // 请求修改数据失败后，还原原来的状态
                if !success {
                    sender.isOn = !shouldShow
                }
                 */
            }
        )
    }

    /// 复用视图刷新（依赖于section，不能直接通过itemInfo判断类型）
    func refresh(
        itemInfo: AppBadgeSettingItem,
        viewModel: AppBadgeSettingViewModel,
        indexPath: IndexPath,
        position: AppCollectionCellPosition = .middle,
        showRequestFailPromptBlock: @escaping (() -> Void)
    ) {
        self.viewModel = viewModel
        self.indexPath = indexPath
        self.position = position
        self.itemInfo = itemInfo
        self.showRequestFailPromptBlock = showRequestFailPromptBlock
        logoView.bt.setLarkImage(with: .avatar(
            key: itemInfo.avatarKey,
            entityID: "",
            params: .init(sizeType: .size(WPUIConst.AvatarSize.small))
        ))
        titleLabel.text = appName(for: itemInfo)
        badgeStatusSwitch.isOn = itemInfo.needShow
        refreshDividlineShowStatus(by: position)
    }

    /// 根据国际化环境，获取显示的应用名称
    func appName(for itemInfo: AppBadgeSettingItem) -> String {
        var name: String
        /// 国际化语言(适配后台逻辑，国际化Key统一使用小写)
        let localLanguage = LanguageManager.currentLanguage.rawValue.lowercased()
        if let localContent = itemInfo.i18nName?[localLanguage], !localContent.isEmpty {
            name = localContent
        } else {    // 默认内容
            name = itemInfo.name
        }
        return name
    }

    /// 仿照UITableView.separatorColor来显示下划线
    func refreshDividlineShowStatus(by position: AppCollectionCellPosition) {
//        bottomDividerLine.snp.remakeConstraints { make in
//            make.height.equalTo(0.5)
//            make.bottom.right.equalToSuperview()
//            var margin: CGFloat = screenMargin
//            if position == .bottom || position == .topAndBottom {
//                margin = 0.0
//            }
//            make.left.equalToSuperview().offset(margin)
//        }
//        topDividerLine.isHidden = !(position == .top || position == .topAndBottom)
        switch position {
        case .top:
            layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            bottomDividerLine.isHidden = false
        case .middle:
            layer.maskedCorners = []
            bottomDividerLine.isHidden = false
        case .bottom:
            layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            bottomDividerLine.isHidden = true
        case .topAndBottom:
            bottomDividerLine.isHidden = true
            layer.maskedCorners = [
                .layerMinXMinYCorner,
                .layerMaxXMinYCorner,
                .layerMinXMaxYCorner,
                .layerMaxXMaxYCorner
            ]
        }
    }
}
