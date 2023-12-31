//
//  ParticipantsViewController+Actions.swift
//  Action
//
//  Created by huangshun on 2019/8/1.
//

import Foundation
import SnapKit
import UIKit
import ByteViewNetwork
import ByteViewTracker

extension ParticipantsViewController {

    func bindMaskViewHidden() {

        searchView.editingDidBegin = { [weak self] _ in
            self?.updateSearchResultMaskView(isHidden: false)
        }

        searchView.tapCancelButton = { [weak self] in
            self?.updateSearchResultMaskView(isHidden: true)
        }

        searchView.editingDidEnd = { [weak self] isEmpty in
            self?.updateSearchResultMaskView(isHidden: isEmpty)
        }
    }

    func bindSearchView() {

        searchResultView.isHidden = true

        searchView.textDidChange = { [weak self] text in
            self?.searchResultView.isHidden = text.isEmpty
            self?.startSearchDebounce(text)
        }

        searchView.tapClearButton = { [weak self] isEditing in
            self?.searchResultView.isHidden = true
            self?.updateSearchResultMaskView(isHidden: !isEditing)
        }
    }

    func updateManipulatorActionSheet(isIPadLayout: Bool) {
        guard Display.pad else { return }
        guard let actionSheet = viewModel.manipulatorActionSheet else { return }
        let shouldHideTitle = isIPadLayout && (actionSheet.modalPresentation == .popover)
        actionSheet.shouldHideTitle = shouldHideTitle
        actionSheet.remakeConstraints(usePadStyle: isIPadLayout)
    }

    func bindBreakoutRoom() {
        viewModel.breakoutRoom?.timer.addObserver(self)
    }

    private func updateSearchResultMaskView(isHidden: Bool) {
        searchResultMaskView.isHidden = isHidden
    }

    func startSearch(text: String) {
        searchResultView.update(.loading)
        viewModel.searchAction(with: text, complet: { [weak self] hasResult in
            Util.runInMainThread {
                self?.searchResultView.update(hasResult ? .result(false) : .noResult)
            }
        })
    }
}

extension ParticipantsViewController: BreakoutRoomTimerObsesrver {

    func breakoutRoomTimeDuration(_ time: TimeInterval) {
        guard !self.viewModel.meeting.data.isBreakoutRoomAutoFinishEnabled else { return }
        Util.runInMainThread { self.timerbanner.update(for: .joined(time)) }
    }

    func breakoutRoomRemainingTime(_ time: TimeInterval?) {
        guard let time = time, time > 0 else { return }
        Util.runInMainThread { self.timerbanner.update(for: .countdown(time)) }
    }

    func breakoutRoomEndTimeDuration(_ time: TimeInterval, closeReason: BreakoutRoomInfo.CloseReason) {
        Util.runInMainThread {
            let desc = I18n.View_G_YouWillLeaveRoomAutomatically(Int(time))
            self.timerbanner.update(for: .leaving(time, desc))
        }
    }
}
