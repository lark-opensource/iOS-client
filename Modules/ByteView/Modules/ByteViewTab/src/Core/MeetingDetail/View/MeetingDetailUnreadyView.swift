//
//  MeetingDetailUnreadyView.swift
//  ByteView
//
//  Created by liurundong.henry on 2021/4/11.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewNetwork
import ByteViewUI

enum MeetingDetailUnreadyViewStatus: Int, Hashable {
    case unavailable // = 0
    case ready // = 1
    case waiting // = 2
    case succeeded // = 3
    case failed // = 4
}

class MeetingDetailUnreadyView: UIView {
    lazy var LRInset: CGFloat = {
        return Util.rootTraitCollection?.horizontalSizeClass == .regular ? 28 : 16
    }()

    var operationOnFailedFromWaiting: (() -> Void)?
    var loadingButtonTapClosure: (() -> Void)?

    var viewStatus: MeetingDetailUnreadyViewStatus = .unavailable

    lazy var loadingButton: LoadingButton = {
        let button = LoadingButton(displayType: .tab)
        button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)
        button.setTitle(I18n.View_G_Export, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14.0)
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.setTitleColor(UIColor.ud.primaryContentLoading, for: .loading)
        button.setBackgroundColor(UIColor.clear, for: .normal)
        button.setBackgroundColor(UIColor.ud.udtokenBtnTextBgPriHover, for: .highlighted)
        button.layer.cornerRadius = 6.0
        button.layer.masksToBounds = true
        button.titleLabel?.setContentCompressionResistancePriority(.required, for: .vertical)
        button.titleLabel?.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .vertical)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        return button
    }()

    init() {
        super.init(frame: .zero)
        setupViews()
        configLoadingButtonTap()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        addSubview(loadingButton)
        loadingButton.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview()
            maker.top.bottom.equalToSuperview().inset(6.0)
            maker.right.lessThanOrEqualToSuperview().inset(LRInset)
            maker.height.equalTo(24.0)
        }
    }

    private func configLoadingButtonTap() {
        loadingButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                self?.configStatus(.waiting)
                self?.loadingButtonTapClosure?()
            })
            .disposed(by: rx.disposeBag)
    }

    func configStatus(_ newStatus: MeetingDetailUnreadyViewStatus) {
        guard self.viewStatus != newStatus else {
            return
        }
        loadingButton.snp.remakeConstraints { (maker) in
            maker.left.equalToSuperview()
            maker.top.bottom.equalToSuperview().inset(6.0)
            maker.right.lessThanOrEqualToSuperview()
            maker.height.equalTo(24.0)
        }
        switch newStatus {
        case .ready:
            loadingButton.isLoading = false
        case .waiting:
            loadingButton.isLoading = true
        case .failed:
            loadingButton.isLoading = false
            if case .waiting = self.viewStatus {
                // Toast
                self.operationOnFailedFromWaiting?()
            } else {
                break
            }
        case .succeeded:
            break
        default:
            break
        }
        self.viewStatus = newStatus
    }
}

extension TabStatisticsInfo.Status {
    func getMeetingDetailUnreadyViewStatus() -> MeetingDetailUnreadyViewStatus {
        switch self {
        case .unavailable:
            return .unavailable
        case .ready:
            return .ready
        case .waiting:
            return .waiting
        case .succeeded:
            return .succeeded
        case .failed:
            return .failed
        }
    }
}

extension TabDetailChatHistoryV2.Status {
    func getMeetingDetailUnreadyViewStatus() -> MeetingDetailUnreadyViewStatus {
        switch self {
        case .unavailable:
            return .unavailable
        case .ready:
            return .ready
        case .waiting:
            return .waiting
        case .succeeded:
            return .succeeded
        case .failed:
            return .failed
        }
    }
}

extension TabVoteStatisticsInfo.Status {
    func getMeetingDetailUnreadyViewStatus() -> MeetingDetailUnreadyViewStatus {
        switch self {
        case .unavailable:
            return .unavailable
        case .ready:
            return .ready
        case .waiting:
            return .waiting
        case .succeeded:
            return .succeeded
        case .failed:
            return .failed
        }
    }
}
