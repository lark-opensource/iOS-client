//
//  MeetingDetailUnReadyCellComponent.swift
//  ByteViewTab
//
//  Created by fakegourmet on 2022/11/22.
//

import Foundation
import ByteViewNetwork

class MeetingDetailUnReadyCellComponent: MeetingDetailCellComponent {

    lazy var unreadyView: MeetingDetailUnreadyView = {
        let unreadyView = MeetingDetailUnreadyView()
        unreadyView.setContentCompressionResistancePriority(.required, for: .vertical)
        unreadyView.setContentCompressionResistancePriority(.required, for: .horizontal)
        unreadyView.operationOnFailedFromWaiting = { [weak self] in
            self?.waitingDidFailed()
        }
        unreadyView.loadingButtonTapClosure = { [weak self] in
            self?.didTapLoadingButton()
        }
        return unreadyView
    }()

    override func setupViews() {
        super.setupViews()
        addUnreadyView()
    }

    private func addUnreadyView() {
        addSubview(unreadyView)
        unreadyView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom)
            $0.left.right.equalToSuperview().inset(LRInset - 4)
            $0.bottom.equalToSuperview()
        }
        unreadyView.isHidden = false
    }

    private func removeUnreadyView() {
        unreadyView.isHidden = true
        unreadyView.removeFromSuperview()
    }

    override func updateLayout() {
        super.updateLayout()
        if unreadyView.superview != nil && !unreadyView.isHidden {
            unreadyView.snp.updateConstraints {
                $0.left.right.equalToSuperview().inset(LRInset - 4)
            }
        }
    }

    func updateStatus(status: MeetingDetailUnreadyViewStatus) {
        switch status {
        case .ready, .failed, .waiting:
            addUnreadyView()
            removeTableView()
        case .succeeded:
            removeUnreadyView()
            addTableView()
            tableView.reloadData()
        default:
            break
        }
        unreadyView.configStatus(status)
    }

    func waitingDidFailed() {}

    func didTapLoadingButton() {}
}
