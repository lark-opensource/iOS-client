//
//  EventEdit+ViewMessageComponents.swift
//  Calendar
//
//  Created by 张威 on 2021/5/14.
//

import UIKit
import Foundation

/// EventEdit ViewMessage Components

// MARK: - Common ViewMessage Components

extension EventEdit {

    enum ActionType {
        case confirm
        case cancel
        case unknown
    }

    struct ActionItem {
        var title: String
        var titleColor: UIColor = UIColor.ud.textTitle
        var actionType: ActionType = .unknown
        var handler: () -> Void
    }

    struct PayloadActionItem<Payload> {
        var title: String
        var titleColor: UIColor = UIColor.ud.textTitle
        var handler: (_ payload: Payload) -> Void
    }

    struct Alert {
        var title: String?
        var titleAlignment: NSTextAlignment = .center
        var content: String?
        var contentAlignment: NSTextAlignment = .center
        var actions: [ActionItem] = []
        var checkBoxTitleList: [String] = []
        var checkBoxType: NotiOptionCheckBoxType = .unknown
    }

    struct ActionSheet {
        var title: String?
        var message: String?
        var actions: [ActionItem] = []
        var cancelAction: ActionItem?
    }

}

// MARK: - Special ViewMessage Components

extension EventEdit {
    enum NotiOptionCheckBoxType {
        case unknown
        case all
        case group
        case doc
    }

    // 会议室审批弹窗
    struct MeetingRoomApprovalAlert {
        var title: String
        var itemTitles: [(title: String, trigger: Int64?)]
        var confirmHandler: (_ message: String) -> Void
        var cancelHandler: () -> Void
    }

    // 通知弹窗
    struct NotiOptionAlert {
        // swiftlint:disable nesting
        typealias CheckBoxSelected = Bool?
        // swiftlint:enable nesting
        var title: String
        var subtitle: String?
        var checkBoxTitle: String?
        var checkBoxTitleList: [String] = []
        var checkBoxType: NotiOptionCheckBoxType = .unknown
        var actions: [PayloadActionItem<CheckBoxSelected>] = []
    }

    // share checking
    struct CheckBoxAlert {
        var title: String
        var subTitle: String?
        var content: String?
        var checkBoxTitle: String?
        var defaultSelectType: SelectConfirmType?
        var allConfirmTypes: [SelectConfirmType] = []
        var confirmHandler: ((_ isChecked: Bool, _ type: SelectConfirmType?) -> Void)?
        var cancelHandler: (() -> Void)?
    }
}
