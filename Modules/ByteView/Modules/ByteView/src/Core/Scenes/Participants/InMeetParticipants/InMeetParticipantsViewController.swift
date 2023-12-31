//
//  InMeetParticipantsViewController.swift
//  ByteView
//
//  Created by Tobb Huang on 2020/11/3.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkSegmentedView
import ByteViewUI
import ByteViewTracker
import UIKit

class InMeetParticipantsViewController: VMViewController<ParticipantsViewModel>, UITableViewDataSource, UITableViewDelegate {

    let tableViewSectionFooterHeight: CGFloat = 8
    var tableViewTopOffset: CGFloat {
        if currentLayoutContext.layoutType.isPhoneLandscape {
            return 4.0
        }
        return 8.0
    }

    var buttonHeight: CGFloat {
        if currentLayoutContext.layoutType.isPhoneLandscape {
            return 44.0
        }
        return 48.0
    }

    /// 是否滚动至等候室列表
    var autoScrollToLobby = false

    lazy var tableView: BaseTableView = {
        let tableView = BaseTableView(frame: CGRect.zero, style: .plain)
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.clear
        tableView.rowHeight = 66
        tableView.sectionFooterHeight = 12
        tableView.register(cellType: InMeetParticipantCell.self)
        tableView.register(cellType: LobbyParticipantCell.self)
        tableView.register(cellType: InvitedParticipantCell.self)
        if viewModel.isWebinar {
            tableView.register(cellType: SuggestionParticipantCell.self)
        }
        tableView.register(viewType: ParticipantSectionHeaderView.self)
        tableView.register(viewType: ParticipantSectionTipHeaderView.self)
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()

    lazy var muteAllView: MuteAllView = {
        let view = MuteAllView()
        return view
    }()

    weak var muteAllViewMorePopover: AlignPopoverViewController?

    /// Pad上展示的邀请action sheet
    private weak var showingInviteController: UIViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.clear
        updateBounces()
    }

    override func bindViewModel() {
        super.bindViewModel()
        setupTableView()
        setupMuteAllView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let scrollView = view.superview as? UIScrollView {
            scrollView.delaysContentTouches = false
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }

    // MARK: tableView
    private func setupTableView() {

        view.addSubview(tableView)
        tableView.snp.makeConstraints { (maker) in
            maker.right.left.equalToSuperview()
            maker.top.equalToSuperview().offset(tableViewTopOffset)
        }
        tableView.sectionFooterHeight = tableViewSectionFooterHeight
        viewModel.addListener(self)
    }

    // MARK: MuteAll view
    private func setupMuteAllView() {
        view.addSubview(muteAllView)
        muteAllView.snp.makeConstraints { (make) in
            make.top.equalTo(tableView.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(muteAllViewHeight(isRegular: VCScene.isRegular))
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        muteAllView.tapMuteAllButton = { [weak self] in
            guard let self = self else { return }
            MeetingTracksV2.trackClickMuteAllButton(isMinimized: false, isMore: false, meeting: self.viewModel.meeting)
            self.viewModel.muteAll()
        }

        muteAllView.tapUnMuteAllButton = { [weak self] in
            guard let self = self else { return }
            MeetingTracksV2.trackClickUnmuteAllButton(isMinimized: false, isMore: false, meeting: self.viewModel.meeting)
            self.viewModel.unMuteAll()
        }

        muteAllView.tapMoreButton = { [weak self] in
            guard let self = self else { return }
            self.muteAllViewMorePopover = self.viewModel.tapMuteAllViewMoreButton(sourceView: self.muteAllView.more)
            self.muteAllViewMorePopover?.fullScreenDetector = self.viewModel.resolver.viewContext.fullScreenDetector
        }

        muteAllView.tapReclaimHostButton = { [weak self] in
            self?.viewModel.reclaimHost()
        }

        let style = muteAllViewStyle(role: viewModel.meetingRole)
        updateMuteViewStyle(style: style)
    }

    private func updateUnMuteAllIfNeeded() {
        muteAllView.unmuteAllMicrophone.alpha = viewModel.canUnMuteAll ? 1.0 : 0.3
    }

    private func updateMuteViewStyle(style: MuteAllView.Style?) {
        guard muteAllView.superview != nil else { return }
        if let style = style {
            muteAllView.isHidden = false
            muteAllView.style = style
            muteAllView.snp.remakeConstraints { make in
                make.top.equalTo(tableView.snp.bottom)
                make.left.right.equalToSuperview()
                make.height.equalTo(muteAllViewHeight(isRegular: VCScene.isRegular))
                make.bottom.equalTo(view.safeAreaLayoutGuide)
            }
        } else {
            muteAllView.isHidden = true
            muteAllView.snp.remakeConstraints { make in
                make.top.equalTo(tableView.snp.bottom)
                make.left.right.bottom.equalToSuperview()
                make.height.equalTo(0)
            }
        }
        muteAllView.layoutIfNeeded()
    }

    private func muteAllViewStyle(role: ParticipantMeetingRole?) -> MuteAllView.Style? {
        switch (role, viewModel.meeting.setting.isHostControlEnabled, viewModel.meeting.setting.hasOwnerAuthority) {
        case (.host, true, _), (.coHost, true, false):
            return .normal
        case (.coHost, true, true):
            return .more
        case (.coHost, false, true), (.participant, _, true):
            return .reclaimHost
        default:
            return nil
        }
    }

    override func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        if Display.pad {
            let style = muteAllViewStyle(role: viewModel.meetingRole)
            updateMuteViewStyle(style: style)
        } else if newContext.layoutChangeReason.isOrientationChanged {
            tableView.snp.updateConstraints { maker in
                maker.top.equalToSuperview().offset(tableViewTopOffset)
            }
            if !muteAllView.isHidden {
                muteAllView.snp.updateConstraints { make in
                    make.height.equalTo(muteAllViewHeight(isRegular: VCScene.isRegular))
                }
                muteAllView.updateLayoutWhenOrientationDidChange()
            }
        }
    }

    private func autoScrollIfNeeded() {
        guard autoScrollToLobby else { return }
        autoScrollToLobby = false
        DispatchQueue.main.async {
            if let lobbySection = self.viewModel.participantDataSource.firstIndex(where: { $0.itemType == .lobby && !$0.realItems.isEmpty }) {
                self.tableView.scrollToRow(at: IndexPath(row: 0, section: lobbySection), at: .top, animated: true)
            }
        }
     }

    func muteAllViewHeight(isRegular: Bool) -> CGFloat {
        if isRegular {
            return 72.0
        } else {
            return buttonHeight + MuteAllView.Layout.buttonTopOffset * 2
        }
    }

    private func updateBounces() {
        tableView.bounces = tableView.contentOffset.y > tableView.contentInset.top
    }

    // MARK: 更新 Pad 上展示的邀请 action sheet 位置
    private func updateShowingInviteController() {
        guard let vc = showingInviteController, VCScene.rootTraitCollection?.horizontalSizeClass == .regular else { return }

        if let pid = viewModel.lastPIDForShowingInvite,
           let section = viewModel.participantDataSource.firstIndex(where: { $0.itemType == .suggest }),
           let index = viewModel.werbinarSuggestSectionModel?.realItems.firstIndex(where: {
               if let suggestModel = $0 as? SuggestionParticipantCellModel, suggestModel.uniqueId == pid {
                   return true
               }
               return false
           }),
            let cell = tableView.cellForRow(at: IndexPath(item: index, section: section)) as? SuggestionParticipantCell,
           let model = viewModel.werbinarSuggestSectionModel?.realItems[safeAccess: index] as? SuggestionParticipantCellModel {
            vc.dismiss(animated: false)
            viewModel.showInviteActionSheet(model, sender: cell.callButton, needTrack: false,
                                            useCache: true, animated: false) { [weak self] (vc, _) in
                self?.showingInviteController = vc
            }
        } else {
            vc.dismiss(animated: true)
        }
    }

    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.participantDataSource.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.participantDataSource[section].items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let dataSource = viewModel.participantDataSource
        // fix crash: https://t.wtturl.cn/hDpedkC/
        if dataSource.count <= indexPath.section || dataSource[indexPath.section].items.count <= indexPath.row {
            Logger.ui.error("invalid participants dataSource: out of range")
            return UITableViewCell()
        }
        let item = dataSource[indexPath.section].items[indexPath.row]
        if item is InMeetParticipantCellModel {
            // 会中
            let cell = tableView.dequeueReusableCell(withType: InMeetParticipantCell.self, for: indexPath)
            return cell
        } else if item is InvitedParticipantCellModel {
            // 被呼叫者
            let cell = tableView.dequeueReusableCell(withType: InvitedParticipantCell.self, for: indexPath)
            return cell
        } else if item is LobbyParticipantCellModel {
            // 等候者
            let cell = tableView.dequeueReusableCell(withType: LobbyParticipantCell.self, for: indexPath)
            return cell
        } else if item is SuggestionParticipantCellModel {
            // Webinar 建议参会
            let cell = tableView.dequeueReusableCell(withType: SuggestionParticipantCell.self, for: indexPath)
            return cell
        } else {
            Logger.ui.error("invalid participants dataSource: \(item)")
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let item = viewModel.participantDataSource[safeAccess: indexPath.section]?.items[safeAccess: indexPath.row] else { return }
        if let model = item as? InMeetParticipantCellModel, let cell = cell as? InMeetParticipantCell {
            // 会中
            cell.configure(with: model)
            cell.tapAvatarAction = { [weak self] in
                self?.viewModel.jumpToUserProfile(participantId: model.participant.participantId, isLarkGuest: model.participant.isLarkGuest)
            }
        } else if let model = item as? InvitedParticipantCellModel, let cell = cell as? InvitedParticipantCell {
            // 被呼叫者
            cell.configure(with: model)
            cell.tapCancelButton = { [weak self] in
                self?.viewModel.cancelInvited(with: model)
            }
            cell.tapConvertPSTNButton = { [weak self] in
                self?.viewModel.convertToInvitePSTN(with: model)
            }
            cell.tapAvatarAction = { [weak self] in
                self?.viewModel.jumpToUserProfile(participantId: model.participant.participantId, isLarkGuest: model.participant.isLarkGuest)
            }
        } else if let model = item as? LobbyParticipantCellModel, let cell = cell as? LobbyParticipantCell {
            // 等候者
            cell.configure(with: model)
            cell.tapAdmitButton = { [weak self] in
                self?.viewModel.admitLobby(with: model.lobbyParticipant)
            }
            cell.tapRemoveButton = { [weak self] in
                self?.viewModel.removeFromLobby(model)
            }
            cell.tapAvatarAction = { [weak self] in
                self?.viewModel.jumpToUserProfile(participantId: model.lobbyParticipant.participantId, isLarkGuest: model.lobbyParticipant.isLarkGuest)
            }
        } else if let model = item as? SuggestionParticipantCellModel, let cell = cell as? SuggestionParticipantCell {
            // Webinar 建议参会
            cell.configure(with: model)
            cell.tapCallButton = { [weak self, weak cell] in
                guard let self = self, let cell = cell else { return }
                if model.enableInvitePSTN {
                    self.viewModel.suggestionMoreCall(with: model, sender: cell.callButton) { [weak self] (vc, _) in
                        self?.showingInviteController = vc
                    }
                } else {
                    self.viewModel.suggestionCall(with: model)
                }
            }
            cell.tapAvatarAction = { [weak self] in
                self?.viewModel.jumpToUserProfile(participantId: model.participant.participantId, isLarkGuest: model.participant.isLarkGuest)
            }
        }
    }

    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let cell = tableView.cellForRow(at: indexPath) as? InMeetParticipantCell,
              let item = viewModel.participantDataSource[safeAccess: indexPath.section]?.items[safeAccess: indexPath.row],
              let inMeetCellModel = item as? InMeetParticipantCellModel else { return }
        guard let displayName = inMeetCellModel.displayName, let originalName = inMeetCellModel.originalName else {
            // 信息未拉取到
            Self.logger.info("userInfo is nil")
            return
        }
        viewModel.tapInMeetingParticipantCell(sourceView: cell,
                                              participant: inMeetCellModel.participant,
                                              displayName: displayName,
                                              originalName: originalName,
                                              source: .allList)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let isBreakoutRoom = viewModel.participantDataSource[safeAccess: section]?.itemType.state == .waiting && viewModel.meeting.data.isInBreakoutRoom
        let showHandsUpStatus = viewModel.participantDataSource[safeAccess: section]?.itemType == .inMeet && viewModel.reactionHandsUpCount > 0
        if viewModel.participantDataSource.count > 1 {
            if isBreakoutRoom {
                return 68
            } else if showHandsUpStatus {
                return 80
            } else {
                return 40
            }
        } else {
            return showHandsUpStatus ? 48 : 0
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let handsUpCount = viewModel.reactionHandsUpCount
        if viewModel.participantDataSource.count == 1 {
            if handsUpCount > 0 {
                guard let headerView = tableView.dequeueReusableHeaderFooterView(withType: ParticipantSectionTipHeaderView.self) else { return nil }
                headerView.showButton = viewModel.meeting.setting.hasCohostAuthority
                headerView.tapDownAllHands = { [weak self] in
                    guard let self = self, let sectionModel = self.viewModel.participantDataSource[safeAccess: section], sectionModel.itemType == .inMeet else { return }
                    self.viewModel.downAllHands()
                    MeetingTracksV2.trackStatusReactionHandsUpCount(handsUpCount, isWebinar: self.viewModel.isWebinar)
                }
                headerView.tipLabel.text = viewModel.isWebinar ? I18n.View_G_NumPanelistHand(handsUpCount) : I18n.View_G_NumberRaisedHand(handsUpCount)
                return headerView
            }
            return nil
        } else {
            guard let headerView = tableView.dequeueReusableHeaderFooterView(withType: ParticipantSectionHeaderView.self) else { return nil }
            guard section < viewModel.participantDataSource.count else {
                return headerView
            }

            headerView.headerViewFontSize(viewModel.participantDataSource, viewForHeaderInSection: section)
            headerView.showButton = viewModel.meeting.setting.hasCohostAuthority
            headerView.tapActionButton = { [weak self, weak headerView] in
                guard let self = self, let sectionModel = self.viewModel.participantDataSource[safeAccess: section] else { return }
                if sectionModel.itemType == .lobby {
                    self.viewModel.admitAllForLobby()
                } else if sectionModel.itemType == .invite {
                    self.viewModel.cancelAllInvited()
                } else if sectionModel.itemType == .suggest {
                    sectionModel.actionEnabled = false
                    headerView?.actionButtonEnabled(false)
                    headerView?.updateButtonLoading(true)
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(self.viewModel.suggestionConfig.callLoadingInterval)) {
                        sectionModel.actionEnabled = true
                        headerView?.actionButtonEnabled(true)
                        headerView?.updateButtonLoading(false)
                    }
                    let max = self.viewModel.max_invite
                    let overMax = self.viewModel.overMaxInviteCount
                    self.viewModel.suggestionInviteAll { r in
                        if case let .failure(error) = r, error == .fail {
                            DispatchQueue.main.async {
                                sectionModel.actionEnabled = true
                                headerView?.actionButtonEnabled(true)
                                headerView?.updateButtonLoading(false)
                            }
                        } else if overMax {
                            DispatchQueue.main.async {
                                Toast.show(I18n.View_G_UpToNumOneCall(max))
                            }
                        }
                    }
                }
            }
            headerView.tapDownAllHands = { [weak self] in
                guard let self = self, let sectionModel = self.viewModel.participantDataSource[safeAccess: section], sectionModel.itemType == .inMeet else { return }
                self.viewModel.downAllHands()
                MeetingTracksV2.trackStatusReactionHandsUpCount(handsUpCount, isWebinar: self.viewModel.isWebinar)
            }
            headerView.tipLabel.text = viewModel.isWebinar ? I18n.View_G_NumPanelistHand(handsUpCount) : I18n.View_G_NumberRaisedHand(handsUpCount)

            let isBreakoutRoom = viewModel.meeting.data.isInBreakoutRoom
            let isWaitingBreakoutRoom = viewModel.participantDataSource[safeAccess: section]?.itemType.state == .waiting && isBreakoutRoom
            let isHandsUp = self.viewModel.participantDataSource[safeAccess: section]?.itemType == .inMeet && handsUpCount > 0
            headerView.setAttachedView(isBreakoutRoom: isWaitingBreakoutRoom, isHandsUp: isHandsUp)

            headerView.gestureRecognizers?.forEach { headerView.removeGestureRecognizer($0) }
            let tapRecognizer = ParticipantSectionHeaderTapGesture(target: self, action: #selector(handleCollaspe))
            tapRecognizer.participantState = viewModel.participantDataSource[safeAccess: section]?.itemType.state ?? .idle
            tapRecognizer.numberOfTouchesRequired = 1
            tapRecognizer.numberOfTapsRequired = 1
            headerView.addGestureRecognizer(tapRecognizer)
            return headerView
        }
    }

    @objc func handleCollaspe(_ sender: ParticipantSectionHeaderTapGesture) {
        var collapsesType = viewModel.collapsedTypes
        if collapsesType.contains(sender.participantState) {
            collapsesType.remove(sender.participantState)
        } else {
            collapsesType.insert(sender.participantState)
        }
        viewModel.updateCollapsedTypes(collapsesType)
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section < tableView.numberOfSections - 1 {
            return tableViewSectionFooterHeight
        } else {
            return 0
        }
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView()
        footerView.backgroundColor = UIColor.ud.bgFloat
        return footerView
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // 滚动停止，放开数据源锁
        viewModel.participantReloadTrigger.unlock()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            // 停止拖动且没有惯性，放开数据源锁
            viewModel.participantReloadTrigger.unlock()
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // 用户开始滑动，锁住数据源不刷新
        viewModel.participantReloadTrigger.lock()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateBounces()
    }
}

// MARK: - ParticipantsViewModelListener
extension InMeetParticipantsViewController: ParticipantsViewModelListener {

    func participantDataSourceDidChange(_ dataSource: [ParticipantsSectionModel]) {
        Logger.ui.debug("participant list reload with count: \(dataSource.count)")
        tableView.reloadData()
        autoScrollIfNeeded()
        updateUnMuteAllIfNeeded()
        updateShowingInviteController()
    }

    func muteAllAuthorityChange() {
        let style = muteAllViewStyle(role: viewModel.meetingRole)
        Util.runInMainThread {
            self.updateMuteViewStyle(style: style)
            // selfRole变化后尝试关闭正在展示的more popover
            self.muteAllViewMorePopover?.dismiss(animated: false)
        }
    }
}

// MARK: - JXSegmentedListContainerViewListDelegate
extension InMeetParticipantsViewController: JXSegmentedListContainerViewListDelegate {
    func listView() -> UIView {
        return view
    }
}
