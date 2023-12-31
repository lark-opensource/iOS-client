//
//  FeedbackViewModel.swift
//  ByteView
//
//  Created by fakegourmet on 2022/8/30.
//

import Foundation
import UniverseDesignIcon
import ByteViewCommon
import ByteViewNetwork

extension Logger {
    static let feedback = getLogger("Feedback")
}

enum FeedbackIssueType: Equatable {
    case `default`
    case other
}

struct FeedbackIssueModel {
    let issueType: FeedbackIssueType
    let title: String
    let trackText: String
    var subtypes: [FeedbackSubtype]
}

struct FeedbackSubtype {
    let title: String
    let trackText: String
    let isOther: Bool
}

final class FeedbackViewModel: SettingViewModel<SettingSourceContext> {

    override func setup() {
        super.setup()
        self.logger = .feedback
        self.pageId = .feedback
        self.title = I18n.View_G_SliderMenuFeedback
        pullConfigI18ns()
    }

    override func buildSections(builder: SettingSectionBuilder) {
        let service = self.service
        builder
            .section(header: SettingDisplayHeader(type: .titleHeader,
                                                  title: I18n.View_G_IssueType_SubTitle))
        models.forEach { model in
            let detailContext = FeedbackDetailContext(fromSource: self.context, model: model)
            builder.gotoCell(.feedbackNext, title: model.title) { context in
                let viewModel = FeedbackDetailViewModel(service: service, context: detailContext)
                context.push(FeedbackDetailViewController(viewModel: viewModel))
            }
        }
    }

    override var supportsRotate: Bool {
        context.supportsRotate
    }

    private var models: [FeedbackIssueModel] = []

    private func pullConfigI18ns() {
        let configs = service.feedbackConfig.items
        let i18ns: [String] = configs.map { $0.i18nKey } + configs.flatMap { $0.subKeys.map { $0.i18nKey } }
        httpClient.i18n.get(i18ns) { [weak self] result in
            guard let self = self, case .success(let i18nValues) = result else { return }
            var models: [FeedbackIssueModel] = []
            configs.forEach { item in
                if let i18n = i18nValues[item.i18nKey] {
                    var model = FeedbackIssueModel(issueType: item.key.isOther ? .other : .default,
                                                   title: i18n,
                                                   trackText: item.key,
                                                   subtypes: [])
                    var types: [FeedbackSubtype] = []
                    item.subKeys.forEach { subItem in
                        if let subI18n = i18nValues[subItem.i18nKey] {
                            let type = subItem.key.isOther ? FeedbackSubtype.other(subI18n, subItem.key) : FeedbackSubtype.default(subI18n, subItem.key)
                            types.append(type)
                        }
                    }
                    model.subtypes = types
                    models.append(model)
                }
            }
            self.models = models
            self.buildSections()
            self.delegate?.requireUpdateSections()
        }
    }
}

private extension FeedbackSubtype {
    static func `default`(_ title: String, _ trackText: String) -> FeedbackSubtype {
        FeedbackSubtype(title: title, trackText: trackText, isOther: false)
    }

    static func other(_ title: String, _ trackText: String) -> FeedbackSubtype {
        FeedbackSubtype(title: title, trackText: trackText, isOther: true)
    }
}

private extension String {
    var isOther: Bool {
        self == "other_issue_report"
    }
}
