//
//  ParticipantsViewController+ConfigViews.swift
//  Action
//
//  Created by huangshun on 2019/8/1.
//

import Foundation
import SnapKit
import UniverseDesignIcon

extension ParticipantsViewController {

    func setNavigationBar() {
        if useCustomNaviBar {
            // iOS 12 以上，phone 使用固定高度导航栏
            isNavigationBarHidden = true
            customNaviBar.line.isHidden = true
            view.addSubview(customNaviBar)
            customNaviBar.snp.makeConstraints { make in
                make.top.left.right.equalToSuperview()
                make.height.equalTo(56)
            }

            let color = preferredNavigationBarStyle.displayParams.buttonTintColor
            let highlighedColor = preferredNavigationBarStyle.displayParams.buttonHighlightTintColor
            customNaviCloseButton.setImage(UDIcon.getIconByKey(.closeOutlined, iconColor: color, size: CGSize(width: 20, height: 20)), for: .normal)
            customNaviCloseButton.setImage(UDIcon.getIconByKey(.closeOutlined, iconColor: highlighedColor, size: CGSize(width: 20, height: 20)), for: .highlighted)
            customNaviCloseButton.addTarget(self, action: #selector(doBack), for: .touchUpInside)

            customNaviSettingButton.setImage(UDIcon.getIconByKey(.adminSettingOutlined, iconColor: color, size: CGSize(width: 20, height: 20)), for: .normal)
            customNaviSettingButton.setImage(UDIcon.getIconByKey(.adminSettingOutlined, iconColor: highlighedColor, size: CGSize(width: 20, height: 20)), for: .highlighted)
            customNaviSettingButton.addTarget(self, action: #selector(didSet), for: .touchUpInside)
        } else {
            // iOS 12 以下，或 pad 使用系统导航栏
            navigationItem.setRightBarButton(settingButton, animated: false)
            setNavigationBarBgColor(UIColor.ud.bgFloat)
        }
        hiddenSetting(isHidden: !viewModel.meeting.setting.showsHostControl)
    }

    func bindSegmentedView() {
        updateSegmentTitles()
        viewModel.addListener(self)
    }

    private func updateSegmentTitles() {
        var count = viewModel.participantDataSource.flatMap { $0.realItems }.count - viewModel.feedbackCellModels.count // 剔除呼叫反馈
        var titles: [String]
        if viewModel.isWebinar {
            count -= viewModel.suggestionDataSource.count
            let attendeeCount = Int(viewModel.attendeeNum) + (viewModel.attendeeDataSource.first(where: { $0.itemType == .lobby })?.realItems.count ?? 0)
            titles = [segmentTitle(for: .inMeet, participantsCount: max(count, 0)),
                      segmentTitle(for: .attendee, participantsCount: attendeeCount)]
        } else {
            titles = [segmentTitle(for: .inMeet, participantsCount: count),
                          segmentTitle(for: .suggestion, participantsCount: viewModel.suggestionDataSource.count)]
        }
        if titles != segmentedDataSource.titles {
            segmentedDataSource.titles = titles
            // 分开reload是因为reload全部有Bug
            segmentedView.reloadItem(at: 0)
            segmentedView.reloadItem(at: 1)
        }
    }

    func segmentTitle(for type: ListType, participantsCount: Int) -> String {
        switch type {
        case .inMeet:
            if viewModel.isWebinar {
                return I18n.View_G_PanelistTab(participantsCount)
            } else if viewModel.meeting.data.isMainBreakoutRoom {
                return I18n.View_G_MainRoom(participantsCount)
            } else {
                return I18n.View_M_AllNumber(participantsCount)
            }
        case .suggestion: return I18n.View_M_SuggestionsNumberBraces(participantsCount)
        case .attendee: return I18n.View_G_AttendeeTab(participantsCount)
        }
    }

    private func updateBreakoutRoomLabel(with data: ParticipantsViewModel.BreakoutRoomData) {
        let isInBreakoutRoom = data.isInBreakoutRoom
        let topic = data.info?.topic ?? ""
        segmentedView.isHidden = isInBreakoutRoom
        timerbanner.isHidden = !isInBreakoutRoom
        timerbanner.askForHelpEnabled = data.askForHelpEnabled
        searchView.isNeedShare = !isInBreakoutRoom
        listContainerView.snp.remakeConstraints { (make) in
            if isInBreakoutRoom {
                make.top.equalTo(searchView.snp.bottom)
            } else {
                make.top.equalTo(segmentedView.snp.bottom)
            }
            make.left.right.bottom.equalToSuperview()
        }

        let newSegmentedTypes: [ListType]
        if isInBreakoutRoom {
            setSearchViewPlaceholder(I18n.View_G_SearchInRoom(topic))
            searchViewAtTopConstraint?.deactivate()
            searchViewBelowBannerConstraint?.activate()
            newSegmentedTypes = [.inMeet]
        } else {
            setSearchViewPlaceholder(I18n.View_G_SASearchOrCall)
            searchViewAtTopConstraint?.activate()
            searchViewBelowBannerConstraint?.deactivate()
            if viewModel.isWebinar {
                newSegmentedTypes = [.inMeet, .attendee]
            } else {
                newSegmentedTypes = [.inMeet, .suggestion]
            }
        }
        if newSegmentedTypes != segmentedTypes {
            segmentedTypes = newSegmentedTypes
            segmentedView.reloadData()
        }

        updateTitleLabel(topic, count: data.participantsCount, isInBreakoutRoom: isInBreakoutRoom, isWebinar: viewModel.isWebinar)
    }

    private func updateWebinarTitle() {
        guard viewModel.isWebinar else { return }
        let tab1Count = viewModel.participantDataSource.flatMap { $0.realItems }.count - viewModel.feedbackCellModels.count - viewModel.suggestionDataSource.count // 剔除呼叫反馈和建议参会
        let tab2Count = Int(viewModel.attendeeNum) + (viewModel.attendeeDataSource.first(where: { $0.itemType == .lobby })?.realItems.count ?? 0)
        updateTitleLabel("", count: tab1Count + tab2Count, isInBreakoutRoom: viewModel.meeting.setting.isInBreakoutRoom, isWebinar: true)
    }

    private func updateTitleLabel(_ title: String, count: Int, isInBreakoutRoom: Bool, isWebinar: Bool) {
        if isInBreakoutRoom {
            titleLabel.attributedText = NSAttributedString(string: title, config: .h3, lineBreakMode: .byTruncatingTail)
            countLabel.attributedText = NSAttributedString(string: " (\(count))", config: .h3, lineBreakMode: .byTruncatingTail)
            countLabel.isHidden = false
        } else if isWebinar {
            titleLabel.attributedText = NSAttributedString(string: I18n.View_M_Participants, config: .h3)
            countLabel.attributedText = NSAttributedString(string: " (\(count))", config: .h3, lineBreakMode: .byTruncatingTail)
            countLabel.isHidden = false
        } else {
            titleLabel.attributedText = NSAttributedString(string: I18n.View_M_Participants, config: .h3)
            countLabel.isHidden = true
        }
    }

    private func updateSearchHeader(state: ParticipantsListState) {
        switch state {
        case .none:
            participantSearchHeaderView.isHidden = true
        case .lock:
            participantSearchHeaderView.isHidden = false
            participantSearchHeaderView.titleLabel.text = I18n.View_MV_LockedOnlyHostCan_YellowNote
        case .overlay:
            participantSearchHeaderView.isHidden = false
            participantSearchHeaderView.titleLabel.text = state.toastText
        }
    }

    private func updateWebinarPaneListHandsupIcon(_ dataSource: [ParticipantsSectionModel]) {
        guard viewModel.isWebinar else { return }
        let showIcon: Bool = dataSource.first(where: { $0.itemType == .inMeet })?.realItems.contains(where: { base in
            if let inMeetModel = base as? InMeetParticipantCellModel, inMeetModel.showStatusHandsUp {
                return true
            }
            return false
        }) ?? false
        paneListHandsupIcon.isHidden = !showIcon
    }

    private func updateWebinarAttendeeHandsupIcon(_ dataSource: [ParticipantsSectionModel]) {
        guard viewModel.isWebinar else { return }
        let showIcon: Bool = dataSource.first(where: { $0.itemType == .inMeet })?.realItems.contains(where: { base in
            if let attendeeModel = base as? AttendeeParticipantCellModel, attendeeModel.showStatusHandsUp {
                return true
            }
            return false
        }) ?? false
        attendeesHandsupIcon.isHidden = !showIcon
    }
}

// MARK: - ParticipantsViewModelListener
extension ParticipantsViewController: ParticipantsViewModelListener {

    func suggestionDataSourceDidChange(_ dataSource: [SuggestionParticipantCellModel]) {
        updateSegmentTitles()
    }

    func participantDataSourceDidChange(_ dataSource: [ParticipantsSectionModel]) {
        updateSegmentTitles()
        updateWebinarPaneListHandsupIcon(dataSource)
        updateWebinarTitle()
    }

    func attendeeDataSourceDidChange(_ dataSource: [ParticipantsSectionModel]) {
        updateSegmentTitles()
        updateWebinarAttendeeHandsupIcon(dataSource)
        updateWebinarTitle()
    }

    func attendeeNumDidChange(_ num: Int64) {
        Util.runInMainThread {
            self.updateSegmentTitles()
            self.updateWebinarTitle()
        }
    }

    func searchDataSourceDidChange(_ dataSource: [SearchParticipantCellModel]) {
        Util.runInMainThread {
            self.searchResultView.tableView.reloadData()
        }
    }

    func breakoutRoomDataDidChange(_ data: ParticipantsViewModel.BreakoutRoomData) {
        Util.runInMainThread {
            self.updateBreakoutRoomLabel(with: data)
        }
    }

    func participantsListStateDidChange(_ state: ParticipantsListState) {
        Util.runInMainThread {
            self.updateSearchHeader(state: state)
        }
    }

    func settingFeatureEnabled(_ enabled: Bool) {
        Util.runInMainThread {
            self.hiddenSetting(isHidden: !enabled)
        }
    }

    func didUpgradeMeeting() {
        Util.runInMainThread {
            if self.searchView.textField.text?.isEmpty == false {
                self.searchView.retryCurrentSearch()
            }
        }
    }
}
