//
//  SeizeFailedView.swift
//  Calendar
//
//  Created by harry zou on 2019/4/18.
//

import UIKit
import Foundation
import CalendarFoundation
import UniverseDesignTheme
import UniverseDesignEmpty

final class SeizeFailedView: UIView {
    enum ErrorType {
        /// 扫描二维码失败
        case scanQRCodeFailed
        /// 无可抢占时间
        case noAvailableTime
        /// 抢占功能关闭
        case seizeFeatureClosed
        /// 禁用会议室
        case bannedMeetingRoom
        /// 付费企业未续费
        case notSubscribe
        /// 全天日程
        case allDayEvent
        /// 外部人员
        case illegalUser
    }

    let imageView = UIImageView()
    let title: UILabel = {
        let label = UILabel()
        label.font = UIFont.ud.title3(.fixed)
        label.textAlignment = .center
        label.textColor = UIColor.ud.textTitle
        label.numberOfLines = 0
        return label
    }()

    init(type: ErrorType) {
        super.init(frame: .zero)
        addSubview(title)
        addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.centerX.top.equalToSuperview()
            make.width.height.equalTo(100)
        }
        title.snp.makeConstraints { (make) in
            make.centerX.bottom.equalToSuperview()
            make.left.right.equalToSuperview().inset(15)
            make.top.equalTo(imageView.snp.bottom).offset(10)
        }
        setImageAndTitle(type: type)
    }

    func setImageAndTitle(type: ErrorType) {
        imageView.image = seizeErrorImage
        switch type {
        case .scanQRCodeFailed:
            title.text = BundleI18n.Calendar.Calendar_Takeover_Failed
        case .noAvailableTime:
            title.text = BundleI18n.Calendar.Calendar_Takeover_NoTakeover
        case .bannedMeetingRoom:
            title.text = BundleI18n.Calendar.Calendar_Takeover_Inactive
        case .seizeFeatureClosed:
            title.text = BundleI18n.Calendar.Calendar_Takeover_StopTakeover
        case .notSubscribe:
            title.text = BundleI18n.Calendar.Calendar_Takeover_NeedPay
        case .allDayEvent:
            title.text = BundleI18n.Calendar.Calendar_Takeover_Allday
        case .illegalUser:
            title.text = BundleI18n.Calendar.Calendar_Takeover_NoExternal
        }
    }

    private var seizeErrorImage: UIImage {
        UDEmptyType.loadingFailure.defaultImage()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
