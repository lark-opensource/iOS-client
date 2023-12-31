//
//  SuggestionParticipantsViewController.swift
//  ByteView
//
//  Created by Tobb Huang on 2020/11/3.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkSegmentedView
import ByteViewUI
import UniverseDesignCheckBox
import UIKit
import ByteViewTracker
import ByteViewNetwork

class SuggestionParticipantsViewController: VMViewController<ParticipantsViewModel>, JXSegmentedListContainerViewListDelegate, UITableViewDataSource, UITableViewDelegate {

    /// Pad上展示的邀请action sheet
    private weak var showingInviteController: UIViewController?
    /// 已拒绝日程面板VM
    private weak var rejectVM: RejectParticipantsViewModel?
    /// 已拒绝日程面板VC
    private weak var rejectVC: RejectParticpantsViewController?

    lazy var emptyPlaceholder: UIView = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textPlaceholder
        label.text = I18n.View_MV_NoSuggestParticipant
        return label
    }()

    lazy var tableView: BaseTableView = {
        let tableView = BaseTableView(frame: CGRect.zero, style: .plain)
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.clear
        tableView.rowHeight = 64
        tableView.sectionHeaderHeight = 40
        tableView.sectionFooterHeight = 12
        tableView.register(cellType: SuggestionParticipantCell.self)
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()

    lazy var bottomView: SuggestionParticipantsBottomView = {
        let v = SuggestionParticipantsBottomView(hasRejectView: viewModel.showReject)
        v.multipleButton.addTarget(self, action: #selector(multipleButtonAction(_:)), for: .touchUpInside)
        v.inviteAllButton.addTarget(self, action: #selector(inviteAllButtonAction(_:)), for: .touchUpInside)
        v.scanButton.addTarget(self, action: #selector(scanButtonAction(_:)), for: .touchUpInside)
        v.cancelButton.addTarget(self, action: #selector(cancelButtonAction(_:)), for: .touchUpInside)
        v.inviteButton.addTarget(self, action: #selector(inviteButtonAction(_:)), for: .touchUpInside)
        v.selectLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapSelectAllLabel(_:))))
        v.selectIcon.tapCallBack = { [weak self] box in
            self?.tapSelectedAllIcon(box)
        }
        return v
    }()

    private weak var anchorToast: AnchorToastView?
    private weak var coverAnchorButton: UIButton?

    private weak var finishCoolingWorkItem: DispatchWorkItem?

    override func setupViews() {
        view.backgroundColor = UIColor.clear
        setupTableView()
        layoutEmptyPlaceholder()
        setupBottomView()
    }

    override func bindViewModel() {
        updateToolView()
        updateRejectView(initialCount: viewModel.calendarRejectDefaultCount)
        viewModel.addListener(self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.resolver.viewContext.post(.suggestedParticipantsAppear)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.resolver.viewContext.post(.suggestedParticipantsDisappear)
    }

    override func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        if Display.phone && newContext.layoutChangeReason.isOrientationChanged {
            tableView.snp.updateConstraints { maker in
                maker.top.equalToSuperview().offset(newContext.layoutType.isPhoneLandscape ? 4.0 : 8.0)
            }
        }
        self.updateBottomViewHeight(self.traitCollection)
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
        emptyPlaceholder.isHidden = !viewModel.suggestionDataSource.isEmpty
    }

    // MARK: tableView
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview().offset(currentLayoutContext.layoutType.isPhoneLandscape ? 4.0 : 8.0)
            maker.left.width.equalToSuperview()
        }

        updateBounces()
    }

    private func updateBounces() {
        tableView.bounces = tableView.contentOffset.y > tableView.contentInset.top
    }

    // MARK: bottomView
    private func setupBottomView() {
        view.addSubview(bottomView)
        bottomView.snp.makeConstraints {
            $0.top.equalTo(tableView.snp.bottom)
            $0.left.right.bottom.equalToSuperview()
            $0.height.equalTo(bottomView.minHeight + VCScene.safeAreaInsets.bottom)
        }
        updateBottomViewHeight(view.traitCollection)
    }

    private func updateBottomViewHeight(_ traitCollection: UITraitCollection) {
        let bottomBuffer: CGFloat = viewModel.showReject ? 0 : 8
        let height = (Display.pad && traitCollection.horizontalSizeClass == .regular) ?
        bottomView.minHeight + bottomBuffer : bottomView.minHeight + VCScene.safeAreaInsets.bottom
        bottomView.snp.updateConstraints {
            $0.height.equalTo(height)
        }
    }

    private func updateToolView() {
        if bottomView.toolStyle != SuggestionParticipantsBottomView.ToolStyle.multiple {
            bottomView.updateToolStyle(.normal(viewModel.multiInviteEnabled))
        }
    }

    private func updateRejectView(initialCount: Int64) {
        if viewModel.showReject {
            if !viewModel.calendarRejectParticpants.isEmpty {
                bottomView.updateCalendarRejectStyle(.reject(viewModel.calendarRejectParticpants.count))
            } else if initialCount == 0 {
                bottomView.updateCalendarRejectStyle(.none)
            } else {
                bottomView.updateCalendarRejectStyle(.notAvailable)
            }
        }
    }

    @objc private func multipleButtonAction(_ b: Any) {
        VCTracker.post(name: .vc_meeting_onthecall_click, params: [.click: "check_list",
                                                                   .suggestionNum: viewModel.suggestionDataSource.count])

        guard !viewModel.multiInviteLimited else {
            Toast.show(I18n.View_MV_HostCanSelect)
            return
        }
        bottomView.updateToolStyle(.multiple)
        viewModel.suggestionIsMultiple = true
        // 默认全选前X个
        viewModel.changeAllSuggestionSelected(true)
        if viewModel.overMaxInviteCount {
            showInviteMaxToast()
        }
        bottomView.updateMultipleTool(iconType: viewModel.suggestionSelectedType, inviteCount: viewModel.selectedSuggestions.count)
    }

    @objc private func inviteAllButtonAction(_ b: Any) {
        VCTracker.post(name: .vc_meeting_onthecall_click, params: [.click: "call_all",
                                                                   .suggestionNum: viewModel.suggestionDataSource.count])

        guard !viewModel.multiInviteLimited else {
            Toast.show(I18n.View_MV_HostCanCallAll)
            return
        }

        let overMax = viewModel.overMaxInviteCount
        var showToast = true
        viewModel.suggestionInviteAll { [weak self] r in
            if case let .failure(error) = r, error == .fail {
                showToast = false
                self?.finishCoolingWorkItem?.cancel()
                DispatchQueue.main.async {
                    self?.inviteBlocked(false)
                }
            }
        }
        coolingInvite { [weak self] in
            if overMax, showToast {
                self?.showInviteMaxToast()
            }
        }
    }

    @objc private func scanButtonAction(_ b: UIButton) {
        VCTracker.post(name: .vc_meeting_onthecall_click, params: [.click: "view_reject_list",
                                                                   .suggestionNum: viewModel.suggestionDataSource.count])

        let vm = RejectParticipantsViewModel(meeting: viewModel.meeting, participants: viewModel.calendarRejectParticpants, suggestionNum: { [weak self] in
            return self?.viewModel.suggestionDataSource.count ?? 0
        }) { [weak self] in
            return self?.viewModel.participantListState ?? .none
        }
        let vc = RejectParticpantsViewController(viewModel: vm)
        var bounds = b.bounds
        bounds.origin.y -= 4

        let popoverConfig = DynamicModalPopoverConfig(sourceView: b,
                                                      sourceRect: bounds,
                                                      backgroundColor: UIColor.clear,
                                                      permittedArrowDirections: .down)
        let regularConfig = DynamicModalConfig(presentationStyle: .popover, popoverConfig: popoverConfig, backgroundColor: .clear)
        viewModel.router.presentDynamicModal(vc, regularConfig: regularConfig, compactConfig: .init(presentationStyle: .pan))
        rejectVM = vm
        rejectVC = vc
    }

    @objc private func cancelButtonAction(_ b: Any) {
        VCTracker.post(name: .vc_meeting_onthecall_click, params: [.click: "check_list_cancel"])
        exitMultiSelectStyle()
    }

    @objc private func inviteButtonAction(_ b: Any) {
        guard !viewModel.multiInviteLimited else {
            Toast.show(I18n.View_MV_HostCanSelect)
            return
        }
        VCTracker.post(name: .vc_meeting_onthecall_click, params: [.click: "check_list_call",
                                                                   .suggestionNum: viewModel.suggestionDataSource.count,
                                                                   "check_list_call_num": viewModel.selectedSuggestions.count])
        bottomView.inviteButton.isEnabled = false
        viewModel.suggestionInviteSelected { [weak self] r in
            DispatchQueue.main.async {
                self?.bottomView.inviteButton.isEnabled = true
            }
            if case let .failure(error) = r, error == .fail {
                self?.finishCoolingWorkItem?.cancel()
                DispatchQueue.main.async {
                    self?.inviteBlocked(false)
                }
            }
        }
        exitMultiSelectStyle()
        coolingInvite {}
    }

    @objc private func tapSelectAllLabel(_ g: Any?) {
        tapSelectedAllIcon(bottomView.selectIcon)
    }

    private func coolingInvite(time: Int? = nil, finish: @escaping () -> Void) {
        inviteBlocked(true)
        let time = time ?? viewModel.suggestionConfig.callLoadingInterval
        let item = DispatchWorkItem { [weak self] in
            self?.inviteBlocked(false)
            finish()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(time), execute: item)
        finishCoolingWorkItem = item
    }

    private func inviteBlocked(_ b: Bool) {
        viewModel.inviteCooling = b
        bottomView.updateInviteAllEnabled(b ? false : viewModel.multiInviteEnabled)
        bottomView.updateInviteAllButton(loading: b)
    }

    private func tapSelectedAllIcon(_ icon: UDCheckBox) {
        guard !viewModel.multiInviteLimited else {
            Toast.show(I18n.View_MV_HostCanCallAll)
            return
        }
        if icon.boxType == .multiple {
            // 反选
            let selectAll = !icon.isSelected
            VCTracker.post(name: .vc_meeting_onthecall_click, params: [.click: "check_list_select_all", "is_check": selectAll])
            viewModel.changeAllSuggestionSelected(selectAll)
            bottomView.updateMultipleTool(iconType: viewModel.suggestionSelectedType, inviteCount: viewModel.selectedSuggestions.count)
            if selectAll {
                if viewModel.overMaxInviteCount {
                    showInviteMaxToast()
                }
            }
        } else if icon.boxType == .mixed {
            // 全选
            VCTracker.post(name: .vc_meeting_onthecall_click, params: [.click: "check_list_select_all", "is_check": true])
            viewModel.changeAllSuggestionSelected(true)
            bottomView.updateMultipleTool(iconType: viewModel.suggestionSelectedType, inviteCount: viewModel.selectedSuggestions.count)
            if viewModel.overMaxInviteCount {
                showInviteMaxToast()
            }
        }
    }

    private func exitMultiSelectStyle() {
        // 清理选中数据
        viewModel.suggestionIsMultiple = false
        // 清理选中效果
        bottomView.updateMultipleTool(iconType: .none, inviteCount: 0)
        // 切回非多选态
        bottomView.updateToolStyle(.normal(viewModel.multiInviteEnabled))
    }

    private func tapCell(checkBox: UDCheckBox, model: SuggestionParticipantCellModel) {
        guard model.isEnabled else {
            Toast.show(I18n.View_G_UpToNumOneCall(viewModel.max_invite))
            return
        }
        let newSelected = !checkBox.isSelected
        checkBox.isSelected = newSelected
        model.updateSelected(newSelected)
        viewModel.updateSuggestionEnabledIfNeeded()
        let type = viewModel.suggestionSelectedType
        bottomView.updateMultipleTool(iconType: type, inviteCount: viewModel.selectedSuggestions.count)
        if type == .all {
            showInviteMaxToast()
        }
    }

    // MARK: 更新 Pad 上展示的邀请 action sheet 位置
    private func updateShowingInviteController() {
        guard let vc = showingInviteController, VCScene.rootTraitCollection?.horizontalSizeClass == .regular else { return }

        if let pid = viewModel.lastPIDForShowingInvite,
           let index = viewModel.suggestionDataSource.firstIndex(where: { $0.uniqueId == pid }),
           let cell = tableView.cellForRow(at: IndexPath(item: index, section: 0)) as? SuggestionParticipantCell,
           let model = viewModel.suggestionDataSource[safeAccess: index] {
            vc.dismiss(animated: false)
            viewModel.showInviteActionSheet(model, sender: cell.callButton, needTrack: false,
                                            useCache: true, animated: false) { [weak self] (vc, _) in
                self?.showingInviteController = vc
            }
        } else {
            vc.dismiss(animated: true)
        }
    }

    /// 单次呼叫上限提示
    private func showInviteMaxToast() {
        if let toast = anchorToast, toast.superview == view {
            view.bringSubviewToFront(toast)
        } else {
            let toast = AnchorToastView(frame: view.bounds)
            toast.sureAction = { [weak self] in
                self?.dismissInviteMaxToast()
            }
            view.addSubview(toast)
            toast.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }
            anchorToast = toast
        }
        anchorToast?.setStyle(I18n.View_G_UpToNumOneCall(viewModel.max_invite), on: .top, of: getBottomInviteView(), distance: 4, defaultEnoughInset: 4)
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) { [weak self] in
            self?.dismissInviteMaxToast()
        }
    }

    private func dismissInviteMaxToast() {
        anchorToast?.removeFromSuperview()
        anchorToast = nil
    }

    private func getBottomInviteView() -> UIView {
        switch bottomView.toolStyle {
        case .normal:
            return bottomView.inviteAllButton
        case .multiple:
            return bottomView.inviteButton
        }
    }

    func exitMultiSelectStyleIfNeeded() {
        guard bottomView.toolStyle == .multiple else { return }
        exitMultiSelectStyle()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.suggestionDataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withType: SuggestionParticipantCell.self, for: indexPath)
        return cell
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cellModel = viewModel.suggestionDataSource[safeAccess: indexPath.row],
        let cell = cell as? SuggestionParticipantCell else { return }
        cell.configure(with: cellModel)
        cell.checkBox.tapCallBack = { [weak self] box in
            self?.tapCell(checkBox: box, model: cellModel)
        }
        cell.tapCallButton = { [weak self, weak cell] in
            guard let self = self, let cell = cell else { return }
            if cellModel.enableInvitePSTN {
                self.viewModel.suggestionMoreCall(with: cellModel, sender: cell.callButton) { [weak self] (vc, _) in
                    self?.showingInviteController = vc
                }
            } else {
                self.viewModel.suggestionCall(with: cellModel)
            }
        }
        cell.tapShowRefuseReply = { [weak self, weak cell] in
            guard let self = self, let cell = cell, !self.viewModel.suggestionIsMultiple else { return }
            cell.showFullRefuseReplyToast(self.view)
        }
        cell.tapAvatarAction = { [weak self] in
            // 多选态时，不可跳转Profile
            guard let self = self, !self.viewModel.suggestionIsMultiple else { return }
            self.viewModel.jumpToUserProfile(participantId: cellModel.participant.participantId, isLarkGuest: cellModel.participant.isLarkGuest)
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? SuggestionParticipantCell,
              let cellModel = viewModel.suggestionDataSource[safeAccess: indexPath.row] else { return }
        tapCell(checkBox: cell.checkBox, model: cellModel)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateBounces()
    }
}

// MARK: - ParticipantsViewModelListener
extension SuggestionParticipantsViewController: ParticipantsViewModelListener {

    func suggestionDataSourceDidChange(_ dataSource: [SuggestionParticipantCellModel]) {
        tableView.reloadData()
        updateToolView()
        updateEmptyPlaceholder()
        updateShowingInviteController()
    }

    func calendarRejectParticipantsDidChange(_ participants: [Participant], initialCount: Int64) {
        guard viewModel.showReject else { return }
        Util.runInMainThread {
            self.updateRejectView(initialCount: initialCount)
            if participants.isEmpty {
                self.rejectVC?.dismiss(animated: true)
            }
        }
        rejectVM?.updateParticipants(participants)
    }

    func settingFeatureEnabled(_ enabled: Bool) {
        if !enabled, bottomView.toolStyle == .multiple {
            Util.runInMainThread {
                self.exitMultiSelectStyle()
            }
        }
    }
}

// MARK: - JXSegmentedListContainerViewListDelegate
extension SuggestionParticipantsViewController {
    func listView() -> UIView {
        return view
    }
}

// MARK: - Layout
extension SuggestionParticipantsViewController {

    var tableViewTopOffset: CGFloat { currentLayoutContext.layoutType.isPhoneLandscape ? 4.0 : 8.0 }
}
