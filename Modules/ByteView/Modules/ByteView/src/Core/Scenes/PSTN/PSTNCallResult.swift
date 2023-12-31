//
//  PSTNCallResult.swift
//  ByteView
//
//  Created by yangyao on 2020/4/14.
//

import Foundation
import ByteViewNetwork

enum PSTNStatus {
    enum PSTNOfflineReason {
        case unknown
        case cancel
        case busy
        case refuse
        case timeout
    }
    case initial
    case calling
    case connected
    case ringing
    case offline(PSTNOfflineReason)
}

extension Participant {
    var pstnStatus: PSTNStatus {
        switch status {
        case .calling:
            return .calling
        case .onTheCall:
            return .connected
        case .ringing:
            return .ringing
        case .idle:
            switch offlineReason {
            case .cancel:
                return .offline(.cancel)
            case .busy:
                return .offline(.busy)
            case .refuse:
                return .offline(.refuse)
            case .ringTimeout:
                return .offline(.timeout)
            case .joinLobby:
                return .connected
            default:
                return .offline(.unknown)
            }
        default:
            return .initial
        }
    }
}

extension PSTNStatus {
    var isRinging: Bool {
        switch self {
        // 这里是被叫方的状态
        case .calling, .ringing:
            return true
        default:
            return false
        }
    }

    var textColor: UIColor {
        if isRinging {
            return UIColor.ud.textTitle.withAlphaComponent(0.3)
        } else {
            return UIColor.ud.textTitle
        }
    }

    var placeHolderColor: UIColor {
        if isRinging {
            return UIColor.ud.textPlaceholder.withAlphaComponent(0.3)
        } else {
            return UIColor.ud.textPlaceholder
        }
    }

    var buttonBackgroundColor: UIColor {
        if isRinging {
            return UIColor.ud.colorfulRed
         } else {
             return UIColor.ud.primaryContentDefault
         }
    }

    var buttonText: String {
        if isRinging {
             return I18n.View_G_CancelCall
         } else {
             return I18n.View_VM_CallButton
         }
    }

    var barIsHidden: Bool {
        switch self {
        case .initial:
            return true
        default:
            return false
        }
    }

    var barBackgroundColor: UIColor {
        switch self {
        case .calling, .ringing:
            return UIColor.ud.primaryFillHover.withAlphaComponent(0.2)
        case .connected:
            return UIColor.ud.colorfulGreen.withAlphaComponent(0.2)
        case .offline:
            return UIColor.ud.colorfulOrange.withAlphaComponent(0.2)
        default:
            return .clear
        }
    }

    var barText: String {
        switch self {
        case .calling:
            return I18n.View_G_CallingEllipsis
        case .connected:
            return I18n.View_G_CallConnected
        case .ringing:
            return I18n.View_G_CallingEllipsis
        case let .offline(reason):
            switch reason {
            case .cancel:
                return I18n.View_G_CallCanceledBySelf
            case .busy:
                return I18n.View_G_Busy
            case .refuse:
                return I18n.View_G_CallDeclined
            case .timeout:
                return I18n.View_G_Busy
            case .unknown:
                return I18n.View_G_Busy
            }
        default:
            return I18n.View_G_Busy
        }
    }

    var barTextColor: UIColor {
        switch self {
        case .calling, .ringing:
            return UIColor.ud.primaryFillHover
        case .offline:
            return UIColor.ud.colorfulOrange
        case .connected:
            return UIColor.ud.colorfulGreen
        default:
            return .clear
        }
    }

    var borderColor: UIColor {
        switch self {
        case .calling, .ringing:
            return UIColor.ud.N400.withAlphaComponent(0.3)
        default:
            return UIColor.ud.lineBorderComponent
        }
    }

    var seperatorColor: UIColor {
        return borderColor
    }
}
