//
//  WorkplacePreviewController+SetupViews.swift
//  LarkWorkplace
//
//  Created by Meng on 2022/10/12.
//

import Foundation
import SnapKit
import LarkUIKit
import UniverseDesignFont
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignNotice
import LarkNavigation
import LarkContainer
import LarkSplitViewController
import AnimatedTabBar

extension WorkplacePreviewController {
    func setupViews() {
        addCloseItem()
        view.addSubview(stateView)
        view.addSubview(contentView)
        view.addSubview(noticeView)
        contentView.addSubview(naviBar)

        titleString = BundleI18n.LarkWorkplace.OpenPlatform_WpPreview_Ttl
        view.backgroundColor = UIColor.ud.bgBody
        noticeView.delegate = self
        naviBar.shouldShowGroup.onNext(false)
        naviBar.isNeedShowBadge = false
        naviBar.avatarShouldNoticeNewVersion.onNext(false)
        naviBar.dataSource = self
        naviBar.delegate = self

        stateView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        noticeView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin)
            make.leading.trailing.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            contentSuperTopConstraint = make.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin).constraint
            contentTopConstraint = make.top.equalTo(noticeView.snp.bottom).constraint
            if Display.pad {
                contentWidthConstraint = make.width.equalTo(320.0).priority(.medium).constraint
                contentSuperWidthConstraint = make.width.equalToSuperview().priority(.high).constraint
                make.centerX.equalToSuperview()
            } else {
                make.leading.trailing.equalToSuperview()
            }
            make.bottom.equalToSuperview()
        }
        naviBar.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
        }

        if let splitVC = larkSplitViewController {
            switch splitVC.splitMode {
            case .twoOverSecondary, .twoDisplaceSecondary, .twoBesideSecondary, .oneOverSecondary, .oneBesideSecondary:
                contentSuperWidthConstraint?.deactivate()
            default:
                contentSuperWidthConstraint?.activate()
            }
        }
        if let tabbarController = RootNavigationController.shared.viewControllers.first as? AnimatedTabBarController,
           let navbar = self.naviBar as? LarkNaviBar {
            navbar.showAvatarView = tabbarController.tabbarStyle != .edge
        }

        contentSuperTopConstraint?.deactivate()
    }

    func buildNoticeView() -> UDNotice {
        let attributedTitle = NSAttributedString(
            string: BundleI18n.LarkWorkplace.OpenPlatform_WpPreview_InterimLinkBanner,
            attributes: [.foregroundColor: UIColor.ud.textTitle, .font: UDFont.body2]
        )
        var config = UDNoticeUIConfig(
            backgroundColor: UIColor.ud.functionInfoFillSolid02,
            attributedText: attributedTitle
        )
        config.leadingIcon = UDIcon.infoColorful
        config.trailingButtonIcon = UDIcon.closeOutlined
        return UDNotice(config: config)
    }

    func buildStateView() -> WPPageStateView {
        let stateView = WPPageStateView(frame: .zero)
        stateView.state = .hidden
        return stateView
    }

    func buildNaviBar() -> LarkNaviBar {
        return LarkNaviBar(navigationService: navigationService, userResolver: self.userResolver, sideBarMenu: nil)
    }
}
