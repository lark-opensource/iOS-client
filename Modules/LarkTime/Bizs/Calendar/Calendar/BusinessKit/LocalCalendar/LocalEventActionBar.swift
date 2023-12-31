//
//  LocalEventActionBar.swift
//  Calendar
//
//  Created by jiayi zou on 2018/9/28.
//  Copyright © 2018 EE. All rights reserved.
//

import UIKit
import EventKit
import EventKitUI
import CalendarFoundation
final class LocalEventActionBar: UIView, EKEventViewDelegate {
    var actionDidComplete: (() -> Void)?
    private var ekevent: EKEvent
    private var sysActionBar = UIView()
    private var vc: UIViewController
    private var ekVC: EKEventViewController?

    /// 暂时无法确定谷歌逻辑，先暂定第一次进入时有RSVP,刷新后却没有, 则需dismissVC
    private var firstEnter = true
    var dismissVC: (() -> Void)?
    init(event: EKEvent, vc: UIViewController ) {
        ekevent = event
        self.vc = vc
        super.init(frame: CGRect.zero)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func commonInit() {
        let status = resetActionBar()
        self.backgroundColor = UIColor.ud.bgBody
        if status {
            self.layer.shadowRadius = 2.0
            self.layer.ud.setShadowColor(UIColor.black, bindTo: self)
            self.layer.shadowOpacity = 0.03
            self.layer.shadowOffset = CGSize(width: 0, height: -2)
        }
    }

    @discardableResult
    private func resetActionBar() -> Bool {
        var result = false
        if ekVC == nil {
            // first time
            result = generateSysActionBar()
        } else {
            // use new VC to replace old one
            ekVC?.removeFromParent()
            sysActionBar.removeFromSuperview()
            result = generateSysActionBar()
        }
        self.addSubview(sysActionBar)
        sysActionBar.snp.remakeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(2)
        }
        return result
    }

    private func generateSysActionBar() -> Bool {
        let eventVC = EKEventViewController()
        eventVC.event = ekevent
        eventVC.delegate = self
        eventVC.allowsCalendarPreview = false
        eventVC.viewWillAppear(false)
        eventVC.navigationController?.setToolbarHidden(true, animated: false)
        eventVC.navigationController?.setNavigationBarHidden(true, animated: false)
        vc.addChild(eventVC)
        ekVC = eventVC
        guard let customView = eventVC.toolbarItems?[0].customView else {
            assertionFailureLog()
            return false
        }
        if customView.subviews[0].subviews.count != 3 {
            //delete button
            if firstEnter == false {
                dismissVC?()
            }
            sysActionBar = UIView()
            return false
        } else {
            firstEnter = false
        }
        customView.removeConstraints(customView.constraints)
        sysActionBar = customView
        return true
    }

    public func eventViewController(_ controller: EKEventViewController, didCompleteWith action: EKEventViewAction) {
        if action == .responded {
            CalendarTracer.shareInstance.calReplyEvent(actionSource: .eventDetail,
                                                       calEventResp: .unknown,
                                                       cardMessageType: .none,
                                                       meetingRoomCount: 0,
                                                       thirdPartyAttendeeCount: ekevent.attendees?.count ?? 0,
                                                       groupCount: 0,
                                                       userCount: 0,
                                                       eventType: .localEvent,
                                                       viewType: .none,
                                                       eventId: ekevent.eventIdentifier,
                                                       chatId: "",
                                                       isCrossTenant: false)
            resetActionBar()
            actionDidComplete?()
        }
    }
}
