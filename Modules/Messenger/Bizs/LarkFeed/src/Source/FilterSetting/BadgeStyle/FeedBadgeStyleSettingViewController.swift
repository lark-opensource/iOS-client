//
//  FeedBadgeStyleSettingViewController.swift
//  Lark
//
//  Created by 姚启灏 on 2018/7/2.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit
import RxSwift
import LarkContainer
import LarkModel
import LKCommonsLogging
import UniverseDesignToast
import SnapKit
import LarkSDKInterface
import RustPB
import LarkBadge
import LarkFeatureGating

/// 免打扰会话的提醒样式
final class FeedBadgeStyleSettingViewController: BaseUIViewController {
    private lazy var grayNumConfigView: FeedBadgeStyleConfigureView = {
        let configView = FeedBadgeStyleConfigureView()
        configView.noticeImageView.image = Resources.gray_num_badge_back
        configView.radioTitleLabel.text = BundleI18n.LarkFeed.Lark_NewSettings_NewMessageNotificationGreyNumber
        configView.noticeTitleLabel.text = BundleI18n.LarkFeed.Lark_Settings_Badgestylepicturetitle
        configView.noticeDetailLabel.text = BundleI18n.LarkFeed.Lark_Settings_Badgestylepicturepreviewg
        let tapGes = UITapGestureRecognizer(target: self, action: #selector(didSelectBadgeStyle))
        configView.addGestureRecognizer(tapGes)
        return configView
    }()

    private lazy var redDotConfigView: FeedBadgeStyleConfigureView = {
        let configView = FeedBadgeStyleConfigureView()
        configView.noticeImageView.image = Resources.red_dot_badge_back
        configView.radioTitleLabel.text = BundleI18n.LarkFeed.Lark_NewSettings_NewMessageNotificationRedDot
        configView.noticeTitleLabel.text = BundleI18n.LarkFeed.Lark_Settings_Badgestylepicturetitle
        configView.noticeDetailLabel.text = BundleI18n.LarkFeed.Lark_Settings_Badgestylepicturepreview
        let tapGes = UITapGestureRecognizer(target: self, action: #selector(didSelectBadgeStyle))
        configView.addGestureRecognizer(tapGes)
        return configView
    }()

    private lazy var showMuteBadgeView: MuteShowConfigureView = {
        let configView = MuteShowConfigureView()
        configView.titleLabel.text = BundleI18n.LarkFeed.Lark_NewSettings_ShowMuteNotification
        configView.imageView.image = Resources.feed_tab_icon
        configView.tabLabel.text = BundleI18n.LarkFeed.Lark_Chat_TranslateMessage
        let tapGes = UITapGestureRecognizer(target: self, action: #selector(didSelectMuteStyle))
        configView.addGestureRecognizer(tapGes)
        return configView
    }()

    private lazy var hidenMuteBadgeView: MuteShowConfigureView = {
        let configView = MuteShowConfigureView()
        configView.titleLabel.text = BundleI18n.LarkFeed.Lark_NewSettings_HideMuteNotification
        configView.imageView.image = Resources.feed_tab_icon
        configView.tabLabel.text = BundleI18n.LarkFeed.Lark_Chat_TranslateMessage
        let tapGes = UITapGestureRecognizer(target: self, action: #selector(didSelectMuteStyle))
        configView.addGestureRecognizer(tapGes)
        return configView
    }()

    private lazy var firstSectionLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.LarkFeed.Lark_NewSettings_BadgeForUnreadMessages
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()

    private lazy var secondSectionLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.LarkFeed.Lark_NewSettings_NavigationBarForUnreadMessage
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()

    private func sectionContentView() -> UIView {
        let contentView = UIView()
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = UIColor.ud.bgFloat
        return contentView
    }

    private lazy var section1ContentView = sectionContentView()
    private lazy var section2ContentView = sectionContentView()

    private let disposeBag = DisposeBag()
    private var currentBadgeStyle: RustPB.Settings_V1_BadgeStyle
    // 是否显示主导航免打扰badge
    private var showTabMuteBadge: Bool
    private let configurationAPI: ConfigurationAPI

    init(badgeStyle: RustPB.Settings_V1_BadgeStyle,
         showTabMuteBadge: Bool,
         configurationAPI: ConfigurationAPI) {
        self.currentBadgeStyle = badgeStyle
        self.showTabMuteBadge = showTabMuteBadge
        self.configurationAPI = configurationAPI
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgFloatBase
        self.title = BundleI18n.LarkFeed.Lark_NewSettings_MutedChatsNewMessageNotification
        // 添加视图
        setupFeedAvatarBadgeView()
        setupShowMuteBadgeView()
        // 刷新选中态
        updateBadgeStyle()
        updateSelectedMuteBagde()
    }

    private func updateBadgeStyle() {
        switch currentBadgeStyle {
        case .weakRemind:
            grayNumConfigView.radioImageView.image = Resources.left_method_select_icon
            redDotConfigView.radioImageView.image = Resources.left_method_normal_icon
        case .strongRemind:
            grayNumConfigView.radioImageView.image = Resources.left_method_normal_icon
            redDotConfigView.radioImageView.image = Resources.left_method_select_icon
        @unknown default:
            assert(false, "new value")
            break
        }
        updateMuteBagdeStyle()
    }

    @objc
    private func didSelectBadgeStyle(_ ges: UIGestureRecognizer) {
        var badgeStyle: RustPB.Settings_V1_BadgeStyle?
        if ges.view == grayNumConfigView {
            badgeStyle = .weakRemind
        } else if ges.view == redDotConfigView {
            badgeStyle = .strongRemind
        }
        guard let style = badgeStyle, currentBadgeStyle != style else {
            return
        }
        self.currentBadgeStyle = style
        self.updateBadgeStyle()
        configurationAPI.setBadgeStyle(style).observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] (_) in
            if let window = self?.view.window {
                UDToast.showSuccess(with: BundleI18n.LarkFeed.Lark_Settings_BadgeStyleChangeSuccess, on: window)
            }
        }, onError: { [weak self] error in
            if let window = self?.view.window {
                UDToast.showFailure(with: BundleI18n.LarkFeed.Lark_Settings_BadgeStyleChangeFail, on: window, error: error)
            }
        }).disposed(by: disposeBag)
    }

    // 会话标记视图
    private func setupFeedAvatarBadgeView() {
        view.addSubview(firstSectionLabel)
        firstSectionLabel.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(16.0)
        }

        view.addSubview(section1ContentView)
        section1ContentView.snp.makeConstraints {
            $0.top.equalTo(firstSectionLabel.snp.bottom).offset(4)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
        }

        section1ContentView.addSubview(grayNumConfigView)
        section1ContentView.addSubview(redDotConfigView)
        grayNumConfigView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(98)
            make.top.equalToSuperview().offset(16)
        }

        redDotConfigView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(98)
            make.top.equalTo(grayNumConfigView.snp.bottom).offset(24)
            make.bottom.equalToSuperview().offset(-16)
        }
    }

    // 导航栏标记视图
    private func setupShowMuteBadgeView() {

        view.addSubview(secondSectionLabel)
        secondSectionLabel.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(firstSectionLabel)
            make.top.equalTo(section1ContentView.snp.bottom).offset(20)
        }

        view.addSubview(section2ContentView)
        section2ContentView.snp.makeConstraints {
            $0.top.equalTo(secondSectionLabel.snp.bottom).offset(4)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
        }

        section2ContentView.addSubview(showMuteBadgeView)
        section2ContentView.addSubview(hidenMuteBadgeView)
        showMuteBadgeView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(82)
            make.top.equalToSuperview().offset(16)
        }
        hidenMuteBadgeView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(82)
            make.top.equalTo(showMuteBadgeView.snp.bottom).offset(24)
            make.bottom.equalToSuperview().offset(-16)
        }
    }

    // 更新选中item
    private func updateSelectedMuteBagde() {
        if showTabMuteBadge {
            showMuteBadgeView.selectedImageView.image = Resources.left_method_select_icon
            hidenMuteBadgeView.selectedImageView.image = Resources.left_method_normal_icon
        } else {
            showMuteBadgeView.selectedImageView.image = Resources.left_method_normal_icon
            hidenMuteBadgeView.selectedImageView.image = Resources.left_method_select_icon
        }
    }

    // 更新免打扰的badgeStyle
    private func updateMuteBagdeStyle() {
        switch currentBadgeStyle {
        case .weakRemind:
            showMuteBadgeView.badgeView.type = .label(.number(3))
            showMuteBadgeView.badgeView.style = .weak
        case .strongRemind:
            showMuteBadgeView.badgeView.type = .dot(.lark)
            showMuteBadgeView.badgeView.style = .strong
        @unknown default:
            assert(false, "new value")
            break
        }
    }

    @objc
    private func didSelectMuteStyle(_ ges: UIGestureRecognizer) {
        var showTabMuteBadge: Bool?
        if ges.view == showMuteBadgeView {
            showTabMuteBadge = true
        } else if ges.view == hidenMuteBadgeView {
            showTabMuteBadge = false
        }
        guard let _showTabMuteBadge = showTabMuteBadge, self.showTabMuteBadge != _showTabMuteBadge else {
            return
        }
        self.showTabMuteBadge = _showTabMuteBadge
        updateSelectedMuteBagde()
        FeedTracker.Setting.ShowMuteRemind(status: _showTabMuteBadge)
        configurationAPI.setShowTabMuteBadge(_showTabMuteBadge).observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] (_) in
            if let window = self?.view.window {
                UDToast.showSuccess(with: BundleI18n.LarkFeed.Lark_Settings_BadgeStyleChangeSuccess, on: window)
            }
        }, onError: { [weak self] error in
            if let window = self?.view.window {
                UDToast.showFailure(with: BundleI18n.LarkFeed.Lark_Settings_BadgeStyleChangeFail, on: window, error: error)
            }
        }).disposed(by: disposeBag)
    }
}
