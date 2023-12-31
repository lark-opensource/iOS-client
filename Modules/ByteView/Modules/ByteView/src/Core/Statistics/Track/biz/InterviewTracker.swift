//
// Created by maozhixiang.lip on 2022/8/10.
//

import Foundation
import ByteViewTracker

final class InterviewTracker {
    private static let interviewQuestionnaireContent = "interview_satisfaction"

    static func trackShowInterviewQuestionnaireWindow() {
        let params: TrackParams = [.content: Self.interviewQuestionnaireContent]
        VCTracker.post(name: .vc_interview_satisfaction_popup_view, params: params)
    }

    enum InterviewQuestionnaireButton: String {
        case fillIn = "fill_in"
        case close = "close"
    }

    static func trackClickInterviewQuestionnaireButton(_ button: InterviewQuestionnaireButton) {
        let params: TrackParams = [.content: Self.interviewQuestionnaireContent, .click: button.rawValue]
        VCTracker.post(name: .vc_interview_satisfaction_popup_click, params: params)
    }
}
