//
//  MinutesNoticeViewModel.swift
//  Minutes
//
//  Created by panzaofeng on 2021/1/12.
//  Copyright © 2021年 wangcong. All rights reserved.
//

import UIKit
import LarkLocalizations
import MinutesFoundation
import MinutesNetwork
import RustPB
import LarkFeatureSwitch

class MinutesNoticeViewModel {

    public var minutes: Minutes

    init(minutes: Minutes) {
        self.minutes = minutes
    }

    var shouldShownNotice: Bool {
        if minutes.info.reviewStatus != .normal {
            return true
        } else {
            return false
        }
    }

    func getReviewText() -> String? {
        let reviewStatus = minutes.info.reviewStatus
        var text: String?
        switch reviewStatus {
        case .autoReviewFailed: // 审核不通过
            text = BundleI18n.Minutes.MMWeb_G_NotComplyNotice
        case .complainFailed:   // 申诉失败
            text = BundleI18n.Minutes.MMWeb_G_SubmitAppealAgain
        case .manualReviewing:  // 审核中
            text = BundleI18n.Minutes.MMWeb_G_ClickViewAppealProgress
        default:
            text = nil
        }
        return text
    }

    func getSchemes() -> [Int: String] {
        let reviewStatus = minutes.info.reviewStatus
        switch reviewStatus {
            case .autoReviewFailed:
                return [1: "protocol://", 3: "appeal://"]
            case .complainFailed:
                return [1: "appeal://"]
            case .manualReviewing:
                return [1: "appealDetail://"]
            default:
                return[:]
        }
    }

    func reviewAppeal(completionHandler: ((Bool) -> Void)?) {
        minutes.info.reviewAppeal(completionHandler: completionHandler)
    }
}
