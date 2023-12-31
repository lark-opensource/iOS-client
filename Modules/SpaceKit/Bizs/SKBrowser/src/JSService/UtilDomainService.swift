//
//  UtilDomainService.swift
//  SpaceKit
//
//  Created by litao_dev on 2020/1/8.
//  

import Foundation
import SKCommon
import RxSwift
import SKInfra

final class UtilDomainService: BaseJSService {
    private var dispose = DisposeBag()
}

extension UtilDomainService: DocsJSServiceHandler {
    var handleServices: [DocsJSService] {
        return [.utilFetchDomainConfig]
    }

    func handle(params: [String: Any], serviceName: String) {
        showTipAlertView()
    }

    private func showTipAlertView() {
        DomainConfig.requestExDomainConfig().subscribe(onNext: { (_) in
            RNManager.manager.updateAPPInfoIfNeed()
        }).disposed(by: dispose)
    }
}
