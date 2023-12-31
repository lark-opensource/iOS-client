//
//  ReplyView.swift
//  Calendar
//
//  Created by zhouyuan on 2018/11/9.
//  Copyright © 2018 EE. All rights reserved.
//

import UIKit
import Foundation
import CalendarFoundation
import EventKit
import SnapKit
import LarkUIKit

protocol ReplyViewDelegate: AnyObject {
    func replyView(_ replyView: ReplyView,
                   actionBarDidTap status: CalendarEventAttendeeEntity.Status)
    func sysActionBarDidTap(_ replyView: ReplyView)
    func replyViewJoinBtnTaped(_ replyView: ReplyView)
    func replyViewReplyTaped(_ replyView: ReplyView)
}

typealias ReplyStatus = CalendarEventAttendeeEntity.Status

protocol ReplyViewContent {
    var ekEvent: EKEvent? { get }
    var showJoinButton: Bool { get }
    var canJoinEvent: Bool { get }
    var isReplyed: Bool { get }
    var showReplyEntrance: Bool { get }
    var rsvpStatusString: String? { get }
    var status: ReplyStatus? { get }
}

final class ReplyView: UIView {

    let actionBar: ReplyActionBar
    private var sysActionBar: LocalEventActionBar?
    /// 特殊，系统日历的回复按钮需要用
    weak var vc: UIViewController?

    weak var delegate: ReplyViewDelegate?

    init(content: ReplyViewContent, isPackUpStyle: Bool = false) {

        self.actionBar = ReplyActionBar(isPackUpStyle: isPackUpStyle,
                                        showReplyEntrance: content.showReplyEntrance)

        super.init(frame: .zero)
        backgroundColor = UIColor.ud.bgBody
        if let ekEvent = content.ekEvent {
            setupSysActionBar(ekEvent: ekEvent)
        } else {
            setupActionBar(actionBar: self.actionBar,
                           showJoinButton: content.showJoinButton,
                           canJoinEvent: content.canJoinEvent,
                           isReplyed: content.isReplyed,
                           rsvpStatusString: content.rsvpStatusString,
                           status: content.status)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupActionBar(actionBar: ReplyActionBar,
                                showJoinButton: Bool,
                                canJoinEvent: Bool,
                                isReplyed: Bool,
                                rsvpStatusString: String?,
                                status: ReplyStatus?) {

        self.addSubview(actionBar.getActionBar())
        actionBar.delegate = self
        actionBar.getActionBar().snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        if isReplyed {
            actionBar.showReplyRsvp(rsvpStatusString: rsvpStatusString)
        } else if showJoinButton {
            if canJoinEvent {
                actionBar.showJoinButton()
            } else {
                actionBar.showCantJoinLabel()
            }
        } else {
            if let status = status {
                self.setStatus(status, animated: false)
            }
        }
    }

    private func setupSysActionBar(ekEvent: EKEvent) {
        guard let vc = self.vc else { return }
        let localEventActionBar = LocalEventActionBar(event: ekEvent, vc: vc)
        localEventActionBar.actionDidComplete = { [weak self] in
            guard let `self` = self else { return }
            self.delegate?.sysActionBarDidTap(self)
        }
        self.addSubview(localEventActionBar)
        localEventActionBar.snp.remakeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        self.sysActionBar = localEventActionBar
    }

    func setStatus(_ status: ReplyStatus, animated: Bool = true) {
        switch status {
        case .accept:
            self.actionBar.setAccepted(animated: animated)
        case .tentative:
            self.actionBar.setTentatived(animated: animated)
        case .decline:
            self.actionBar.setDeclined(animated: animated)
        case .removed:
            self.actionBar.hide()
        case .needsAction:
            self.actionBar.setNeedAction()
        @unknown default:
            break
        }
    }
}

extension ReplyView: ActionBarDelegate {
    func actionBarDidTapReply() {
        self.delegate?.replyViewReplyTaped(self)
    }

    func actionBarDidTapAccept() {
        self.delegate?.replyView(self, actionBarDidTap: .accept)
    }

    func actionBarDidTapDecline() {
        self.delegate?.replyView(self, actionBarDidTap: .decline)
    }

    func actionBarDidTapTentative() {
        self.delegate?.replyView(self, actionBarDidTap: .tentative)
    }

    func actionBarDidTapJoin() {
        self.delegate?.replyViewJoinBtnTaped(self)
    }
}
