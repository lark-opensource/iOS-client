//
//  ArrangementInstanceModel.swift
//  Calendar
//
//  Created by zhouyuan on 2019/3/26.
//

import UIKit
import Foundation
import CalendarFoundation
import RustPB

struct ArrangementInstanceModel: DaysInstanceViewContent {
    var instancelayout: InstanceLayout?
    var cornerRadius: CGFloat?
    var index: Int = 0
    var uniqueId: String
    var instanceId: String
    var locationText: String?
    var typeIconTintColor: UIColor?
    var startMinute: Int32
    var endMinute: Int32
    var frame: CGRect?
    var titleStyle: LabelStyle?
    var subTitleStyle: LabelStyle?
    var zIndex: Int?
    var isEditable: Bool { return false }
    var isGoogleSource: Bool
    var isExchangeSource: Bool
    var isCrossDay: Bool
    var isNewEvent: Bool
    var userInfo: [String: Any]
    var isCoverPassEvent: Bool
    var maskOpacity: Float = 0
    var backgroundColor: UIColor
    var foregroundColor: UIColor
    var titleText: String {
        return getTitleFromModel(model: instance, calendar: calendar)
    }
    var strokeDashLineColor: UIColor?
    var indicatorColor: UIColor?
    var indicatorInfo: (color: UIColor, isStripe: Bool)?
    var hasStrikethrough: Bool = false
    var stripBackgroundColor: UIColor?
    var stripLineColor: UIColor?
    var dashedBorderColor: UIColor?
    var startDate: Date
    var endDate: Date
    var startDay: Int32
    var endDay: Int32
    var shouldHideSelf: Bool
    var isDragBorderToChangeTime: Bool = false
    var selfAttendeeStatus: Calendar_V1_CalendarEventAttendee.Status
    var meetingRoomCategory: Calendar_V1_CalendarEvent.Category = .defaultCategory

    private let instance: CalendarEventInstanceEntity
    private let calendar: CalendarModel?
    
    private let eventViewSetting: EventViewSetting = SettingService.shared().getSetting()

    init(instance: CalendarEventInstanceEntity,
         calendar: CalendarModel?) {

        self.instanceId = instance.id
        self.uniqueId = instance.getInstanceQuadrupleString()
        self.instance = instance
        self.calendar = calendar
        self.userInfo = ["instance": instance, "calendar": calendar as Any]
        self.isNewEvent = false
        self.startDate = instance.startDate
        self.endDate = instance.endDate
        self.startDay = instance.startDay
        self.endDay = instance.endDay
        self.startMinute = instance.startMinute
        self.endMinute = instance.endMinute
        self.locationText = InstanceBaseFunc.getSubTitleFromModel(model: instance)
        self.isCoverPassEvent = eventViewSetting.showCoverPassEvent
        self.isCrossDay = instance.isOverOneDay
        self.isGoogleSource = instance.isGoogleEvent()
        self.isExchangeSource = instance.isExchangeEvent()
        self.selfAttendeeStatus = instance.selfAttendeeStatus

        if (calendar?.isFreeBusyOnlyCalendar() ?? false) && instance.startTime == instance.endTime {
            self.shouldHideSelf = true
        } else {
            self.shouldHideSelf = false
        }

        if instance.displayType == .undecryptable {
            self.foregroundColor = UIColor.ud.textCaption
            self.backgroundColor = UIColor.ud.N200
        } else if !instance.isMeetingRoomViewInstance {
            cornerRadius = 4
            let skinColorHelper = SkinColorHelper(skinType: eventViewSetting.skinTypeIos, insInfo: .init(from: instance))
            self.maskOpacity = skinColorHelper.maskOpacity
            self.foregroundColor = skinColorHelper.eventTextColor

            indicatorInfo = skinColorHelper.indicatorInfo
            dashedBorderColor = skinColorHelper.dashedBorderColor

            let hasNoCornerIcon = !instance.isGoogleEvent() && !instance.isExchangeEvent() && !instance.isLocalEvent()
            self.typeIconTintColor = hasNoCornerIcon ? nil : skinColorHelper.typeIconTintColor

            // 配置底色条纹
            self.backgroundColor = skinColorHelper.backgroundColor

            if let stripeColors = skinColorHelper.stripeColor {
                self.stripLineColor = stripeColors.foreground
                self.stripBackgroundColor = stripeColors.background
            }
        } else {
            self.foregroundColor = UIColor.ud.N600
            if instance.isMeetingRoomViewInstance {
                self.backgroundColor = instance.isEditable ? UIColor.ud.functionInfoFillSolid02 : UIColor.ud.calLightBgNeutral
                if instance.isFakeInstance {
                    self.strokeDashLineColor = UIColor.ud.functionInfoContentPressed
                    self.foregroundColor = UIColor.ud.functionInfoContentPressed
                }
            } else {
                self.backgroundColor = UIColor.ud.calLightBgNeutral
            }
            if instance.isGoogleEvent() {
                self.typeIconTintColor = UIColor.ud.N600.withAlphaComponent(0.2)
            }
        }
    }

    func getTitleFromModel(model: CalendarEventInstanceEntity,
                           calendar: CalendarModel?) -> String {
        guard !model.isMeetingRoomViewInstance else {
            // 会议室视图的日程走单独的标题逻辑
            return model.displaySummary()
        }

        switch model.displayType {
        case .full:
            return model.displaySummary()
        case .limited:
            if let calendar = calendar {
                if calendar.type == .googleResource || calendar.type == .resources {
                    return BundleI18n.Calendar.Calendar_Meeting_Reserved(meetingRoom: calendar.displayName())
                } else if calendar.type == .other {
                    return calendar.displayName()
                } else {
                    return model.displaySummary()
                }
            } else {
                return model.displaySummary()
            }
        case .invisible:
            assertionFailureLog()
            return ""
        case .undecryptable:
            return I18n.Calendar_EventExpired_GreyText
        @unknown default:
            return ""
        }
    }
}
