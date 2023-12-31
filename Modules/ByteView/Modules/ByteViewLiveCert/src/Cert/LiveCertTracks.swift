//
//  LiveCertTracks.swift
//  ByteView
//
//  Created by kiri on 2020/10/21.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewTracker

final class LiveCertTracks {
    static func trackScanSuccess() {
        VCTracker.post(name: .vc_meeting_popup, params: [.from_source: "identity_verification_qrcode", .action_name: "scan_success"])
    }

    static func trackTwoElementsPage(nextStep: Bool?) {
        let actionName: String
        if let nextStep = nextStep {
            actionName = nextStep ? "next_step" : "return"
        } else {
            actionName = "display"
        }
        VCTracker.post(name: .vc_meeting_popup, params: [.from_source: "identity_verification_page", .action_name: actionName])
    }

    static func trackTwoElementsFailed(reason: TwoEleFailReason) {
        let errorName: String
        switch reason {
        case .underAge:
            errorName = "underage"
        case .linkedID:
            errorName = "linked_id"
        case .wrongID:
            errorName = "wrong_id"
        default:
            return
        }
        VCTracker.post(name: .vc_meeting_popup, params: [.from_source: "identity_verification_error", "error_name": errorName])
    }

    static func trackTwoElementsFailedAlert(reason: TwoEleFailReason, isFinished: Bool) {
        let fromSource: String
        switch reason {
        case .underAge:
            fromSource = "underage"
        case .linkedID:
            fromSource = "linked_id"
        default:
            return
        }
        let actionName = isFinished ? "finish" : "cancel"
        VCTracker.post(name: .vc_meeting_popup, params: [.from_source: fromSource, .action_name: actionName])
    }

    static func trackTimeout() {
        VCTracker.post(name: .vc_meeting_popup, params: [.from_source: "failed_five_times", .action_name: "display"])
    }

    static func trackLivenessPage(nextStep: Bool?) {
        let actionName: String
        if let nextStep = nextStep {
            actionName = nextStep ? "start" : "return"
        } else {
            actionName = "display"
        }
        VCTracker.post(name: .vc_meeting_popup, params: [.from_source: "face_recognition", .action_name: actionName])
    }

    static func trackLivenessResult(isSuccess: Bool) {
        let actionName = isSuccess ? "success" : "fail"
        VCTracker.post(name: .vc_meeting_popup, params: [.from_source: "face_recognition", .action_name: actionName])
    }

    static func trackLivenessFailPage(retry: Bool) {
        let actionName = retry ? "retry" : "finish"
        VCTracker.post(name: .vc_meeting_popup, params: [.from_source: "face_recognition_fail", .action_name: actionName])
    }
}
