//
//  ParticipantsViewController+Layout.swift
//  Action
//
//  Created by huangshun on 2019/8/1.
//

import Foundation
import SnapKit
import UIKit
import ByteViewUI

extension ParticipantsViewController {
    enum Layout {
        static func searchViewHeight(canInvited: Bool) -> CGFloat {
            guard canInvited else {
                return 0
            }
            return 36.0
        }

        static func searchViewMarginTop(canInvited: Bool) -> CGFloat {
            guard canInvited else {
                return 0
            }
            return 8
        }

        static var marginLeft: CGFloat = 16.0

        static var marginRight: CGFloat = 16.0
        static func isRegular() -> Bool { VCScene.rootTraitCollection?.horizontalSizeClass == .regular }
    }

    var searchResultMaskViewTopOffset: CGFloat {
        if currentLayoutContext.layoutType.isPhoneLandscape {
            return 4.0
        }
        return 8.0
    }

    func segmentedViewTopOffset(canInvited: Bool) -> CGFloat {
        guard canInvited else {
            return 0
        }
        if currentLayoutContext.layoutType.isPhoneLandscape {
            return 4.0
        }
        return 8
    }

    func layoutSegmentedView() {
        // 用于添加offset && 遮挡segmentedView上方的阴影
        view.addSubview(placeHolderView)
        placeHolderView.snp.makeConstraints { (maker) in
            maker.height.equalTo(segmentedViewTopOffset(canInvited: viewModel.canInvite) + (Layout.isRegular() ? 2 : 0))
            maker.left.right.equalToSuperview()
            maker.top.equalTo(searchView.snp.bottom)
        }

        view.insertSubview(segmentedView, belowSubview: placeHolderView)
        segmentedView.snp.makeConstraints { (make) in
            make.top.equalTo(placeHolderView.snp.bottom)
            make.left.right.equalTo(placeHolderView)
            make.height.equalTo(viewModel.canInvite ? 40 : 0)
        }

        if viewModel.isWebinar {
            segmentedView.addSubview(paneListHandsupIcon)
            paneListHandsupIcon.snp.makeConstraints { make in
                make.left.equalTo(segmentedView.safeAreaLayoutGuide).offset(Layout.marginRight)
                make.centerY.equalToSuperview()
                make.size.equalTo(CGSize(width: 16, height: 16))
            }
            segmentedView.addSubview(attendeesHandsupIcon)
            attendeesHandsupIcon.snp.makeConstraints { make in
                make.left.equalTo(segmentedView.snp.centerX).offset(Layout.marginLeft)
                make.centerY.equalToSuperview()
                make.size.equalTo(CGSize(width: 16, height: 16))
            }
        }

        view.addSubview(listContainerView)
        listContainerView.snp.makeConstraints { (make) in
            make.bottom.left.right.equalToSuperview()
            make.top.equalTo(segmentedView.snp.bottom)
        }

        if viewModel.isWebinar {
            segmentedTypes = [.inMeet, .attendee]
        } else if !viewModel.canInvite {
            segmentedTypes = [.inMeet]
        } else {
            segmentedTypes = [.inMeet, .suggestion]
        }

        // 默认页
        if autoScrollToLobby == .attendee, let index = segmentedTypes.firstIndex(where: { $0 == .attendee }) {
            segmentedView.defaultSelectedIndex = index
            listContainerView.defaultSelectedIndex = index
        }
        // 非 webinar 点击拒绝回复 toast 跳转到建议参会人
        let canShowSuggest = viewModel.canInvite && !viewModel.isWebinar
        if canShowSuggest, autoScrollToLobby == .suggest, let index = segmentedTypes.firstIndex(where: { $0 == .suggestion }) {
            segmentedView.defaultSelectedIndex = index
            listContainerView.defaultSelectedIndex = index
        }
    }

    func layoutTopArea() {
        let titleContainer = UIStackView()
        titleContainer.axis = .horizontal

        titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleContainer.addArrangedSubview(titleLabel)
        titleContainer.addArrangedSubview(countLabel)

        if useCustomNaviBar {
            customNaviTitleContainer.addSubview(titleContainer)
            titleContainer.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.left.greaterThanOrEqualToSuperview()
                make.right.lessThanOrEqualToSuperview()
            }
        } else {
            titleView.addSubview(titleContainer)
            titleContainer.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            navigationItem.titleView = titleView
        }

        titleLabel.attributedText = NSAttributedString(string: I18n.View_M_Participants, config: .h3)
        countLabel.isHidden = true

        timerbanner.isHidden = true
        timerbanner.askForHelpHandler = { [weak self] in
            if let meeting = self?.viewModel.meeting {
                BreakoutRoomAction.askHostForHelp(source: .listTop, meeting: meeting)
            }
        }
        view.addSubview(timerbanner)
        timerbanner.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(useCustomNaviBar ? customNaviBar.snp.bottom : view.safeAreaLayoutGuide)
                .offset(Layout.searchViewMarginTop(canInvited: false))
        }

        view.addSubview(searchView)
        searchView.setContentCompressionResistancePriority(
            UILayoutPriority.required,
            for: NSLayoutConstraint.Axis.vertical
        )

        searchView.snp.makeConstraints { (make) in
            searchViewAtTopConstraint = make.top.equalTo(useCustomNaviBar ? customNaviBar.snp.bottom : view)
                .offset(Layout.searchViewMarginTop(canInvited: viewModel.canInvite) - (Layout.isRegular() ? 0 : 8)).constraint
            searchViewBelowBannerConstraint = make.top.equalTo(timerbanner.snp.bottom).offset(8).constraint

            make.height.equalTo(viewModel.canInvite ? 36 : 0)
            make.left.equalTo(view.safeAreaLayoutGuide).inset(Layout.marginLeft)
            make.right.equalTo(view.safeAreaLayoutGuide).inset(Layout.marginRight)
        }
        searchViewAtTopConstraint?.activate()
        searchViewBelowBannerConstraint?.deactivate()
    }

    func layoutSearchView() {

        view.addSubview(searchResultMaskView)
        searchResultMaskView.snp.makeConstraints { (make) in
            make.bottom.left.right.equalToSuperview()
            make.top.equalTo(searchView.snp.bottom).offset(searchResultMaskViewTopOffset)
        }

        resultBackgroundView.addSubview(searchResultView)
        searchResultView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        searchResultView.tableView.snp.remakeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        participantSearchHeaderView.snp.makeConstraints { (make) in
            make.height.equalTo(40)
        }
    }

    func setSearchViewPlaceholder(_ string: String) {
        let holderAttribute: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.ud.textPlaceholder,
            .font: UIFont.systemFont(ofSize: 16, weight: .regular)
        ]
        searchView.textField.attributedPlaceholder = NSAttributedString(string: string, attributes: holderAttribute)
    }
}
