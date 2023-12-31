//
//  EventDetailTableAttachmentViewModel.swift
//  Calendar
//
//  Created by Rico on 2021/4/21.
//

import Foundation
import LarkCombine
import LarkContainer
import LarkRustClient
import RxSwift
import RxRelay
import ServerPB
import Swinject

final class EventDetailTableAttachmentViewModel: EventDetailComponentViewModel {

    @ContextObject(\.rxModel) var rxModel

    @ScopedInjectedLazy var calendarApi: CalendarRustAPI?

    private var attachments: [CalendarEventAttachmentEntity] = []
    private var fileRiskTags: [String: Server.FileRiskTag] = [:]

    let viewData = CurrentValueSubject<EventDetailTableAttachmentViewDataType?, Never>(nil)
    let route = PassthroughSubject<Route, Never>()
    private let disposeBag = DisposeBag()

    override init(context: EventDetailContext, userResolver: UserResolver) {

        super.init(context: context, userResolver: userResolver)

        bindRx()
    }

    private func bindRx() {
        rxModel
            .compactMap { $0.event }
            .flatMap { [weak self] (event) -> Observable<[Server.FileRiskTag]> in
                guard let `self` = self else { return .empty() }
                self.attachments = event.attachments
                    .filter { !$0.isDeleted }
                    .map { CalendarEventAttachmentEntity(pb: $0) }
                self.buildViewData()
                return self.fetchAttachmentRiskTags().catchErrorJustReturn([])
            }
            .subscribe(onNext: { [weak self] riskTags in
                guard let `self` = self, !riskTags.isEmpty else { return }
                self.fileRiskTags = Dictionary(uniqueKeysWithValues: riskTags.map { ($0.fileToken, $0) })
                self.buildViewData()
            }).disposed(by: disposeBag)
    }
}

// MARK: - Action
extension EventDetailTableAttachmentViewModel {

    enum Route {
        case preview(token: String)
        case googleLink(link: URL)
        case urlLink(link: String, token: String)
    }

    func clickAttachment(at index: Int) {
        if let entity = attachments[safeIndex: index] {
            EventDetail.logInfo("click attachment: \(entity.token)")
            switch entity.type {
            case .googleDrive:
                jumpGoogleDriveLink(urlString: entity.googleDriveLink)
            case .url:
                jumpGeneralDriveLink(urlString: entity.urlLink, token: entity.token)
            case .largeAttachment, .local:
                route.send(.preview(token: entity.token))
            @unknown default: break
            }

            CalendarTracer.shareInstance.calAttachmentOperation(sourceType: .detail)
            CalendarTracerV2.EventDetail.traceClick {
                $0.click("show_attachment").target(.none)
                $0.event_type = model.isWebinar ? "webinar" : "normal"
                $0.mergeEventCommonParams(commonParam: CommonParamData(instance: self.model.instance, event: self.model.event))
            }
        }
    }
    
    private func jumpGoogleDriveLink(urlString: String) {
        guard let url = URL(string: urlString) else {
            EventDetail.logError("cannot jump url: \(urlString)")
            return
        }
        route.send(.googleLink(link: url))
    }
    
    private func jumpGeneralDriveLink(urlString: String, token: String) {
        route.send(.urlLink(link: urlString, token: token))
    }
}

extension EventDetailTableAttachmentViewModel {

    struct ViewData: EventDetailTableAttachmentViewDataType {
        let items: [AttachmentUIData]
        let source: Rust.CalendarEventSource?
    }

    private func buildViewData() {
        let attachments = getAttachments()
        if !self.fileRiskTags.isEmpty {
            let newAttachments = attachments.map {
                var atta = $0
                atta.fileRiskTag = self.fileRiskTags[$0.token] ?? $0.fileRiskTag
                return atta
            }
            viewData.send(ViewData(items: newAttachments, source: model.event?.source))
        } else {
            viewData.send(ViewData(items: attachments, source: model.event?.source))
        }
    }

    private func getAttachments() -> [CalendarEventAttachmentEntity] {
        return attachments
    }

    var model: EventDetailModel {
        rxModel.value
    }
}

// Server Request
extension EventDetailTableAttachmentViewModel {
    private func fetchAttachmentRiskTags() -> Observable<[Server.FileRiskTag]> {
        guard !attachments.isEmpty else {
            fileRiskTags.removeAll()
            return .empty()
        }

        return self.calendarApi?.fetchAttachmentRiskTags(fileTokens: self.attachments.map { $0.token }) ?? .empty()
    }
}
