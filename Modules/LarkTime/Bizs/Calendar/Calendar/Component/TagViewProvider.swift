//
//  TagViewProvider.swift
//  Calendar
//
//  Created by harry zou on 2018/12/26.
//  Copyright © 2018 EE. All rights reserved.
//

import UIKit
import LarkTag
import CalendarFoundation
import UniverseDesignColor
import UniverseDesignTag
import RustPB

final class TagViewProvider {
    class func label(text: String, color: UIColor) -> UIView {
        switch (text, color) {
        case (BundleI18n.Calendar.Calendar_Detail_Organizer, _):
            return organizer
        case (BundleI18n.Calendar.Calendar_Detail_Creator, _):
            return creator
        case (BundleI18n.Calendar.Calendar_Detail_External, _):
            return externalNormal
        case (BundleI18n.Calendar.Calendar_Detail_NotAttend, _):
            return notAttend
        case (I18n.Calendar_Takeover_ReservedBy, _):
            return booker()
        default:
            return TagWrapperView.titleTagView(for: Tag(title: text,
                                                        image: nil,
                                                        style: .blue,
                                                        type: .customTitleTag))
        }
    }

    class var organizer: UIView {
        return TagWrapperView.titleTagView(for: .calendarOrganizer)
    }

    class var creator: UIView {
        return TagWrapperView.titleTagView(for: .calendarCreator)
    }

    /// 红色外部
    class var externalNormal: UIView {
        return TagWrapperView.titleTagView(for: .external)
    }

    class var notAttend: UIView {
        return TagWrapperView.titleTagView(for: .calendarNotAttend)
    }

    class var optionalAttend: UIView {
        return TagWrapperView.titleTagView(for: .calendarOptionalAttend)
    }

    class func inactivate() -> UIView {
        return TagWrapperView.titleTagView(
            for: Tag(title: BundleI18n.Calendar.Calendar_Common_Inactivate,
                             image: nil,
                             style: .orange,
                             type: .customTitleTag)
        )
    }

    class func seizeable() -> UIView {
        return TagWrapperView.titleTagView(
            for: Tag(title: BundleI18n.Calendar.Calendar_Takeover_CanTakeover,
                             image: nil,
                             style: .blue,
                             type: .customTitleTag)
        )
    }

    class func booker() -> UIView {
        return TagWrapperView.titleTagView(
            for: Tag(title: BundleI18n.Calendar.Calendar_Takeover_ReservedBy,
                             image: nil,
                             style: .blue,
                             type: .customTitleTag)
        )
    }

    class var needApproval: UIView {
        return TagWrapperView.titleTagView(for: Tag(title: BundleI18n.Calendar.Calendar_Approval_Tag,
                                                    image: nil,
                                                    style: .red,
                                                    type: .customTitleTag))
    }

    class var resignedTagView: UIView {
        let style = Style(textColor: UIColor.ud.N600, backColor: UIColor.ud.N200)

        return TagWrapperView.titleTagView(for: Tag(title: BundleI18n.Calendar.Calendar_Detail_ResignedTag,
                                                    image: nil,
                                                    style: style,
                                                    type: .customTitleTag))
    }

    class var calendarOwnerTagView: UDTag {
        let style = Style(textColor: UDColor.B600, backColor: UDColor.B100)

        return TagWrapperView.titleTagView(for: Tag(title: I18n.Calendar_Share_Owner,
                                                    image: nil,
                                                    style: style,
                                                    type: .customTitleTag))
    }

    class var transparencyExternalTagView: UIView {
        return transparencyTagView(text: BundleI18n.Calendar.Calendar_Detail_External)
    }

    class func transparencyTagView(text: String) -> UIView {
        let style = Style(textColor: UDColor.primaryOnPrimaryFill, backColor: UDColor.primaryOnPrimaryFill.withAlphaComponent(0.2))

        return TagWrapperView.titleTagView(for: Tag(title: text,
                                                    image: nil,
                                                    style: style,
                                                    type: .customTitleTag))
    }

    // 邮件联系人的几种情况
    static func emailTag(with tag: String) -> UDTag {
        TagWrapperView.titleTagView(for: Tag(title: tag,
                                             image: nil,
                                             style: .blue,
                                             type: .customTitleTag))
    }
}
