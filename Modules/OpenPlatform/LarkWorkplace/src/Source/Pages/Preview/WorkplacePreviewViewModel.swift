//
//  WorkplacePreviewViewModel.swift
//  LarkWorkplace
//
//  Created by Meng on 2022/10/12.
//

import Foundation
import RxSwift
import RxRelay
import LKCommonsLogging
import ECOProbe
import ECOProbeMeta
import LarkContainer

enum WorkplacePreviewState: CustomStringConvertible {
    enum FailedState {
        case expired
        case permission
        case deleted
        case unknown
    }

    case loading
    case success(WPHomeVCInitData.LowCode)
    case loadFailed(FailedState)

    var description: String {
        switch self {
        case .loading:
            return "loading"
        case .success:
            return "success"
        case .loadFailed(let state):
            return "load failed(\(state))"
        }
    }
}

final class WorkplacePreviewViewModel {
    static let logger = Logger.log(WorkplacePreviewViewModel.self)

    let token: String
    private let disposeBag = DisposeBag()

    let stateRelay = BehaviorRelay<WorkplacePreviewState>(value: .loading)

    private let traceService: WPTraceService
    private let networkService: WPNetworkService

    init(token: String, traceService: WPTraceService, networkService: WPNetworkService) {
        self.token = token
        self.traceService = traceService
        self.networkService = networkService
    }

    func reloadPreviewData() {
        stateRelay.accept(.loading)
        Self.logger.info("start fetch preview data")
        let monitor = WPMonitor().timing()
        let context = WPNetworkContext(injectInfo: .session, trace: traceService.currentTrace)
        let params: [String: Any] = [
            "token": token
        ].merging(WPGeneralRequestConfig.legacyParameters) { $1 }
        networkService.request(
            WPGetBuilderInstancePreviewConfig.self,
            params: params,
            context: context
        ).map({ [weak self]json -> WorkplacePreviewResponse in
            Self.logger.info("did received response", additionalData: [
                "code": "\(json["code"])",
                "msg": "\(json["msg"])",
                "request_id": "\(json[WPNetworkConstants.requestId])",
                "log_id": "\(json[WPNetworkConstants.logId])",
                "token": "\(self?.token ?? "")"
            ])
            let response = try JSONDecoder().decode(WorkplacePreviewResponse.self, from: json.rawData())
            return response
        })
        .subscribe(onSuccess: { [weak self]response in
            guard let `self` = self else { return }
            monitor
                .timing()
                .setCode(WPMCode.workplace_get_preview_data_success)
                .setTrace(self.traceService.root)
                .setNetworkStatus()
                .setResult(.success())
                .setInfo(self.token, key: "token")
                .flush()
            let state = self.handleResponse(response: response)
            self.stateRelay.accept(state)
        }, onError: { [weak self]error in
            Self.logger.error("fetch preview data failed", error: error)
            monitor
                .timing()
                .setCode(WPMCode.workplace_get_preview_data_fail)
                .setTrace(self?.traceService.root)
                .setNetworkStatus()
                .setError(error)
                .setInfo(self?.token ?? "", key: "token")
                .flush()
            self?.stateRelay.accept(.loadFailed(.unknown))
        })
        .disposed(by: disposeBag)
    }

    private func handleResponse(response: WorkplacePreviewResponse) -> WorkplacePreviewState {
        guard let code = WorkplacePreviewResponse.Code(rawValue: response.code) else {
            return .loadFailed(.unknown)    // unknown code
        }
        switch code {
        case .permission:
            return .loadFailed(.permission)
        case .expired:
            return .loadFailed(.expired)
        case .deleted:
            return .loadFailed(.deleted)
        case .success:
            return handlePreview(response: response)
        }
    }

    private func handlePreview(response: WorkplacePreviewResponse) -> WorkplacePreviewState {
        guard let template = response.data,
              let portal = WPPortal.templatePortal(with: template),
              let initData = WPHomeVCInitData.LowCode(portal) else {
            Self.logger.error("generate preview init data failed", additionalData: [
                "hasTemplateData": "\(response.data != nil)"
            ])
            return .loadFailed(.unknown)
        }
        return .success(initData)
    }
}
