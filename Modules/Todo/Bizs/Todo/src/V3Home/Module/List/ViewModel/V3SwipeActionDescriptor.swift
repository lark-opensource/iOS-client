//
//  V3SwipeActionDescriptor.swift
//  Todo
//
//  Created by wangwanxin on 2022/8/23.
//

import Foundation
import UniverseDesignIcon
import UIKit
import UniverseDesignFont

enum V3SwipeActionDescriptor {
    case delete, quit, share, complete, uncomplete, dueTime

    var belongLeft: Bool {
        return [.complete, .uncomplete, .dueTime].contains(self)
    }

    var belongRight: Bool {
        return [.delete, .quit, .share].contains(self)
    }

    var title: String {
        switch self {
        case .delete: return I18N.Todo_common_Delete
        case .quit: return I18N.Todo_LeaveTask_Button
        case .share: return I18N.Todo_Common_Share
        case .complete: return I18N.Todo_New_Complete_SwipeButton
        case .uncomplete: return I18N.Todo_New_ReopenATask_Button
        case .dueTime: return I18N.Todo_New_Deadline_SwipeButton
        }
    }

    var image: UIImage {
        let size = CGSize(width: 20, height: 20)
        switch self {
        case .delete: return UDIcon.deleteTrashOutlined.ud.resized(to: size)
        case .quit: return UDIcon.logoutOutlined.ud.resized(to: size)
        case .share: return UDIcon.shareOutlined.ud.resized(to: size)
        case .complete: return UDIcon.doneOutlined.ud.resized(to: size)
        case .uncomplete: return UDIcon.undoOutlined.ud.resized(to: size)
        case .dueTime: return UDIcon.calendarDateOutlined.ud.resized(to: size)
        }
    }

    var backgroundColor: UIColor {
        switch self {
        case .delete, .quit: return UIColor.ud.R400
        case .complete, .uncomplete: return UIColor.ud.colorfulTurquoise
        case .dueTime: return UIColor.ud.functionWarningContentLoading
        case .share: return UIColor.ud.primaryContentDefault
        }
    }

    var font: UIFont {
        return UDFont.systemFont(ofSize: 14)
    }

    var successToast: String {
        switch self {
        case .delete:
            return I18N.Todo_common_DeletedSuccessfully
        case .quit:
            return I18N.Todo_LeaveTask_Left_Toast
        default: return ""
        }
    }

    var oapiFailureToast: String {
        switch self {
        case .quit:
            return I18N.Todo_Tasks_APICantExit
        default:
            return I18N.Todo_common_SthWentWrongTryLater
        }
    }
}
