//
//  EmptyStatusView.swift
//  Calendar
//
//  Created by heng zhu on 2019/1/14.
//  Copyright © 2019 EE. All rights reserved.
//

import Foundation
import CalendarFoundation
import UIKit
import SnapKit
import UniverseDesignTheme
import UniverseDesignEmpty

final class EmptyStatusView: UIView {

    enum Status {
        /// 无最近联系人
        case noContacts
        /// 没有匹配的联系人
        case noMatchedContacts
        /// 没有会议室
        case noMeetingRoom
        /// 没有匹配的会议室
        case noMatchedMeetingRoom
        /// 没有日历
        case noCalendar
        /// 没有匹配的日历
        case noMatchedCalendar
        /// 暂无可退订日历
        case noUnsubscribeCalendar
        /// 没有搜索结果
        case noSearchResult
    }

    private let noResultView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()

    private let titleLable: UILabel = {
        let label = UILabel()
        label.font = UIFont.cd.regularFont(ofSize: 14)
        label.textColor = UIColor.ud.textCaption
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()

    private let imageNoMatch = UDEmptyType.searchFailed.defaultImage()
    private let imageNoResult = UDEmptyType.noSchedule.defaultImage()
    private let imageNoContacts = UDEmptyType.noContent.defaultImage()

    override init(frame: CGRect) {
        super.init(frame: frame)
        hide()

        addSubview(noResultView)
        noResultView.snp.makeConstraints { (make) in
            make.top.centerX.equalToSuperview()
            make.size.equalTo(CGSize(width: 100, height: 100))
        }

        addSubview(titleLable)
        titleLable.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(30)
            make.top.equalTo(noResultView.snp.bottom).offset(12)
            make.bottom.equalToSuperview().inset(12)
        }
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        var view: UIView = self
        while let temp = view.superview {
            view = temp
        }
        view.endEditing(true)
        return super.hitTest(point, with: event)
    }

    func showStatus(with status: Status) {
        isHidden = false
        switch status {
        case .noContacts: // 无最近联系人
            titleLable.text = BundleI18n.Calendar.Calendar_SubscribeCalendar_NoRecentContacts
            noResultView.image = imageNoContacts
        case .noMatchedContacts: // 没有匹配的联系人
            titleLable.text = BundleI18n.Calendar.Calendar_SubscribeCalendar_NoMatchingContacts
            noResultView.image = imageNoMatch
        case .noMeetingRoom: // 请联系管理员匹配会议室
            titleLable.text = BundleI18n.Calendar.Calendar_SubscribeCalendar_ContactAdminToSetUpRooms
            noResultView.image = imageNoResult
        case .noMatchedMeetingRoom: // 没有匹配的会议室
            titleLable.text = BundleI18n.Calendar.Calendar_SubscribeCalendar_NoMatchingRooms
            noResultView.image = imageNoMatch
        case .noCalendar: // 请搜索并订阅日历
            titleLable.text = BundleI18n.Calendar.Calendar_SubscribeCalendar_SearchPublicCalendarsToSubscribe
            noResultView.image = imageNoContacts
        case .noMatchedCalendar: // 没有匹配的日历
            titleLable.text = BundleI18n.Calendar.Calendar_SubscribeCalendar_NoMatchingPublicCalendars
            noResultView.image = imageNoMatch
        case .noUnsubscribeCalendar: // 暂无可退订日历
            titleLable.text = BundleI18n.Calendar.Calendar_SubscribeCalendar_NoUnsubscribeForNow
            noResultView.image = imageNoMatch
        case .noSearchResult: // 无搜索结果
            titleLable.text = BundleI18n.Calendar.Calendar_EventSearch_NoResult
            noResultView.image = imageNoMatch
        }
    }

    func hide() {
        isHidden = true
    }

}
