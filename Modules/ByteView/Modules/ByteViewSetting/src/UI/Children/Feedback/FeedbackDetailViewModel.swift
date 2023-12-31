//
//  FeedbackDetailViewModel.swift
//  ByteView
//
//  Created by fakegourmet on 2022/8/30.
//

import Foundation
import ByteViewTracker
import ByteViewNetwork

struct FeedbackDetailContext {
    let fromSource: SettingSourceContext
    let model: FeedbackIssueModel
}

final class FeedbackDetailViewModel: SettingViewModel<FeedbackDetailContext> {
    private var fromSource: SettingSourceContext { context.fromSource }
    private var model: FeedbackIssueModel { context.model }

    private var selectedSubtype: FeedbackSubtype?
    var descText: String = ""

    var isDataChanged: Bool {
        selectedSubtype != nil || !descText.isEmpty
    }

    var isSubmitEnabled: Bool {
        let hasDesc = !descText.isEmpty
        if let subtype = selectedSubtype {
            if subtype.isOther, model.issueType == .other {
                return hasDesc
            } else {
                return true
            }
        }
        return false
    }

    override func setup() {
        super.setup()
        self.logger = .feedback
        self.pageId = .feedbackDetail
        self.title = I18n.View_G_SliderMenuFeedback
        self.supportedCellTypes.insert(.feedbackInputCell)
    }

    override func buildSections(builder: SettingSectionBuilder) {
        builder
            .section(header: SettingDisplayHeader(type: .titleHeader,
                                                  title: I18n.View_G_IssueDetails))

        model.subtypes.forEach { subtype in
            builder.checkmark(.feedbackSubtype, title: subtype.title, isOn: self.selectedSubtype?.title == subtype.title,
                              action: { [weak self] _ in
                guard let self = self else { return }
                self.logger.info("select \(subtype.title)")
                self.selectedSubtype = subtype
                self.reloadData()
            })
        }

        builder
            .section(header: SettingDisplayHeader(type: .titleHeader,
                                                  title: I18n.View_G_IssueDescription))
            .row(.feedbackDesc, reuseIdentifier: .feedbackInputCell, title: self.descText, subtitle: I18n.View_G_IssueDescriptionMore)
    }

    override var supportsRotate: Bool {
        fromSource.supportsRotate
    }

    func updateDescText(_ text: String) {
        self.descText = text
    }

    func submit(completion: @escaping (Result<Void, Error>) -> Void) {
        var problemType = model.title
        if let subtype = selectedSubtype {
            problemType += "/"
            problemType += subtype.title
        }
        service.httpClient.getResponse(MeetingFeedbackRequest(problemType: problemType, problemText: descText)) { [weak self] result in
            switch result {
            case .success(let resp):
                if let self = self, resp.status == .success, let subtype = self.selectedSubtype {
                    VCTracker.post(name: .vc_meeting_setting_click, params: [
                        .click: "send_report",
                        "feedback_id": resp.feedbackID,
                        "first_problem_type": self.model.trackText,
                        "second_problem_type": subtype.trackText,
                        "is_picture_provide": false,
                        "is_log_provide": false,
                        "is_audio_provide": false,
                        "occur_time": "",
                        "problem_instruction": self.descText,
                        "location": "vc_setting",
                        "setting_tab": "feedback"
                    ])
                }
                completion(.success(Void()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
