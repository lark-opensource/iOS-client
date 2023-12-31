//
// Created by maozhixiang.lip on 2022/8/3.
//

import Foundation
import ByteViewNetwork
import RxSwift
import RxCocoa

class InterviewQuestionnaireViewModel {
    private let info: InterviewQuestionnaireInfo
    let dependency: InterviewQuestionnaireDependency
    private let i18nMapRelay: BehaviorRelay<[String: String]> = .init(value: [:])
    private var httpClient: HttpClient { dependency.httpClient }

    init(info: InterviewQuestionnaireInfo, dependency: InterviewQuestionnaireDependency) {
        self.info = info
        self.dependency = dependency
        self.fetchI18n(info)
    }

    private func fetchI18n(_ info: InterviewQuestionnaireInfo) {
        let keys = [
            info.titleI18nKey,
            info.guideI18nKey,
            info.acceptButtonI18nKey,
            info.refuseButtonI18nKey
        ]
        httpClient.i18n.get(keys) { result in
            guard case let .success(i18nMap) = result else { return }
            self.i18nMapRelay.accept(i18nMap)
        }
    }

    var link: String {
        self.info.link
    }

    var title: Driver<String> {
        self.i18nMapRelay.asDriver().map { $0[self.info.titleI18nKey] ?? "" }
    }

    var description: Driver<String> {
        self.i18nMapRelay.asDriver().map { $0[self.info.guideI18nKey] ?? "" }
    }

    var acceptButtonText: Driver<String> {
        self.i18nMapRelay.asDriver().map { $0[self.info.acceptButtonI18nKey] ?? "" }
    }

    var refuseButtonText: Driver<String> {
        self.i18nMapRelay.asDriver().map { $0[self.info.refuseButtonI18nKey] ?? "" }
    }
}
