//
//  AttendeeParticipantsViewController.swift
//  ByteView
//
//  Created by wulv on 2022/9/26.
//

import Foundation
import LarkSegmentedView
import ByteViewUI

final class AttendeeParticipantsViewController: VMViewController<ParticipantsViewModel>, UITableViewDataSource, UITableViewDelegate {

    /// 是否滚动至等候室列表
    var autoScrollToLobby = false

    lazy var tableView: BaseTableView = {
        let tableView = BaseTableView(frame: CGRect.zero, style: .plain)
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.clear
        tableView.rowHeight = 64
        tableView.register(cellType: AttendeeParticipantCell.self)
        tableView.register(cellType: InvitedParticipantCell.self)
        tableView.register(cellType: LobbyParticipantCell.self)
        tableView.register(viewType: ParticipantSectionHeaderView.self)
        tableView.register(viewType: ParticipantSectionTipHeaderView.self)
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()

    lazy var emptyPlaceholder: UIView = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textPlaceholder
        label.text = I18n.View_G_NoAttendeeYet
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.clear
        updateBounces()
    }

    override func bindViewModel() {
        super.bindViewModel()
        setupTableView()
        layoutEmptyPlaceholder()
        viewModel.addListener(self)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }

    // MARK: 占位图
    private func layoutEmptyPlaceholder() {
        view.addSubview(emptyPlaceholder)
        emptyPlaceholder.snp.makeConstraints { (maker) in
            maker.center.equalTo(tableView)
        }
    }

    private func updateEmptyPlaceholder() {
        emptyPlaceholder.isHidden = !viewModel.attendeeDataSource.isEmpty
    }

    // MARK: tableView
    private func setupTableView() {

        view.addSubview(tableView)
        tableView.snp.makeConstraints { (maker) in
            maker.right.left.equalToSuperview()
            maker.top.equalToSuperview().offset(currentLayoutContext.layoutType.isPhoneLandscape ? 4.0 : 8.0)
            maker.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        tableView.sectionFooterHeight = Layout.tableViewSectionFooterHeight
        viewModel.addListener(self)
    }

    override func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        if Display.phone && newContext.layoutChangeReason.isOrientationChanged {
            tableView.snp.updateConstraints { maker in
                maker.top.equalToSuperview().offset(currentLayoutContext.layoutType.isPhoneLandscape ? 4.0 : 8.0)
            }
        }
    }

    private func updateBounces() {
        tableView.bounces = tableView.contentOffset.y > tableView.contentInset.top
    }

    private func autoScrollIfNeeded() {
        guard autoScrollToLobby else { return }
        autoScrollToLobby = false
        DispatchQueue.main.async {
            if let lobbySection = self.viewModel.attendeeDataSource.firstIndex(where: { $0.itemType == .lobby && !$0.realItems.isEmpty }) {
                self.tableView.scrollToRow(at: IndexPath(row: 0, section: lobbySection), at: .top, animated: true)
            }
        }
     }

    @objc private func handleAttendeeCollaspe(_ sender: ParticipantSectionHeaderTapGesture) {
        var collapsesType = viewModel.attendeeCollapsedTypes
        if collapsesType.contains(sender.participantState) {
            collapsesType.remove(sender.participantState)
        } else {
            collapsesType.insert(sender.participantState)
        }
        viewModel.updateAttendeeCollapsedTypes(collapsesType)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.attendeeDataSource.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.attendeeDataSource[section].items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let dataSource = viewModel.attendeeDataSource
        if dataSource.count <= indexPath.section || dataSource[indexPath.section].items.count <= indexPath.row {
            Logger.ui.error("invalid attendee dataSource: out of range")
            return UITableViewCell()
        }
        let item = dataSource[indexPath.section].items[indexPath.row]
        if item is AttendeeParticipantCellModel {
            // 会中
            let cell = tableView.dequeueReusableCell(withType: AttendeeParticipantCell.self, for: indexPath)
            return cell
        } else if item is InvitedParticipantCellModel {
            // 被呼叫者
            let cell = tableView.dequeueReusableCell(withType: InvitedParticipantCell.self, for: indexPath)
            return cell
        } else if item is LobbyParticipantCellModel {
            // 等候者
            let cell = tableView.dequeueReusableCell(withType: LobbyParticipantCell.self, for: indexPath)
            return cell
        } else {
            Logger.ui.error("invalid attendee dataSource: \(item)")
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let item = viewModel.attendeeDataSource[safeAccess: indexPath.section]?.items[safeAccess: indexPath.row] else { return }
        if let model = item as? AttendeeParticipantCellModel, let cell = cell as? AttendeeParticipantCell {
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
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let cell = tableView.cellForRow(at: indexPath) as? AttendeeParticipantCell,
              let item = viewModel.attendeeDataSource[safeAccess: indexPath.section]?.items[safeAccess: indexPath.row],
              let attendeeCellModel = item as? AttendeeParticipantCellModel else { return }
        guard let displayName = attendeeCellModel.displayName, let originalName = attendeeCellModel.originalName else {
            // 信息未拉取到
            Self.logger.info("userInfo is nil")
            return
        }
        viewModel.tapInMeetingParticipantCell(sourceView: cell,
                                              participant: attendeeCellModel.participant,
                                              displayName: displayName,
                                              originalName: originalName,
                                              source: .attendeeList)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let showHandsUpStatus = viewModel.attendeeDataSource[safeAccess: section]?.itemType == .inMeet && viewModel.reactionHandsUpAttendeeCount > 0
        if viewModel.attendeeDataSource.count > 1 || viewModel.attendeeDataSource.first?.itemType != .inMeet {
            if showHandsUpStatus {
                return 80
            } else {
                return 40
            }
        } else {
            return showHandsUpStatus ? 48 : 0
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let handsUpCount = viewModel.reactionHandsUpAttendeeCount
        if viewModel.attendeeDataSource.count == 1, viewModel.attendeeDataSource.first?.itemType == .inMeet {
            if handsUpCount > 0 {
                guard let headerView = tableView.dequeueReusableHeaderFooterView(withType: ParticipantSectionTipHeaderView.self) else { return nil }
                headerView.showButton = viewModel.meeting.setting.hasCohostAuthority
                headerView.tapDownAllHands = { [weak self] in
                    guard let self = self, let sectionModel = self.viewModel.attendeeDataSource[safeAccess: section], sectionModel.itemType == .inMeet else { return }
                    self.viewModel.downAllHands(forAttendee: true)
                    MeetingTracksV2.trackAttendeeStatusReactionHandsUpCount(handsUpCount)
                }
                headerView.tipLabel.text = I18n.View_G_NumAttendeeHand(handsUpCount)
                return headerView
            } else {
                return nil
            }
        } else {
            guard let headerView = tableView.dequeueReusableHeaderFooterView(withType: ParticipantSectionHeaderView.self) else { return nil }
            guard section < viewModel.attendeeDataSource.count else {
                return headerView
            }

            headerView.headerViewFontSize(viewModel.attendeeDataSource, viewForHeaderInSection: section)
            headerView.showButton = viewModel.meeting.setting.hasCohostAuthority
            headerView.tapActionButton = { [weak self] in
                guard let self = self,
                      let sectionModel = self.viewModel.attendeeDataSource[safeAccess: section] else { return }
                if sectionModel.itemType == .lobby {
                    self.viewModel.admitAllForLobby(forAttendee: true)
                } else if sectionModel.itemType == .invite {
                    self.viewModel.cancelAllInvited(forAttendee: true)
                }
            }
            headerView.tapDownAllHands = { [weak self] in
                guard let self = self, let sectionModel = self.viewModel.attendeeDataSource[safeAccess: section], sectionModel.itemType == .inMeet else { return }
                self.viewModel.downAllHands(forAttendee: true)
                MeetingTracksV2.trackAttendeeStatusReactionHandsUpCount(handsUpCount)
            }
            headerView.tipLabel.text = I18n.View_G_NumAttendeeHand(handsUpCount)

            let isHandsUp = viewModel.attendeeDataSource[safeAccess: section]?.itemType == .inMeet && handsUpCount > 0
            headerView.setAttachedView(isBreakoutRoom: false, isHandsUp: isHandsUp)

            headerView.gestureRecognizers?.forEach { headerView.removeGestureRecognizer($0) }
            let tapRecognizer = ParticipantSectionHeaderTapGesture(target: self, action: #selector(handleAttendeeCollaspe))
            tapRecognizer.participantState = viewModel.attendeeDataSource[safeAccess: section]?.itemType.state ?? .idle
            tapRecognizer.numberOfTouchesRequired = 1
            tapRecognizer.numberOfTapsRequired = 1
            headerView.addGestureRecognizer(tapRecognizer)
            return headerView
        }
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section < tableView.numberOfSections - 1 {
            return Layout.tableViewSectionFooterHeight
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
        viewModel.attendeeReloadTrigger.unlock()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            // 停止拖动且没有惯性，放开数据源锁
            viewModel.attendeeReloadTrigger.unlock()
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // 用户开始滑动，锁住数据源不刷新
        viewModel.attendeeReloadTrigger.lock()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateBounces()
    }
}

// MARK: - ParticipantsViewModelListener
extension AttendeeParticipantsViewController: ParticipantsViewModelListener {
    func attendeeDataSourceDidChange(_ dataSource: [ParticipantsSectionModel]) {
        Logger.ui.debug("attendee list reload with count: \(dataSource.count)")
        tableView.reloadData()
        updateEmptyPlaceholder()
        autoScrollIfNeeded()
    }
}

// MARK: - JXSegmentedListContainerViewListDelegate
extension AttendeeParticipantsViewController: JXSegmentedListContainerViewListDelegate {
    func listView() -> UIView {
        return view
    }
}

// MARK: - Layout
extension AttendeeParticipantsViewController {
    enum Layout {
        static let tableViewSectionFooterHeight: CGFloat = 8
    }
}
