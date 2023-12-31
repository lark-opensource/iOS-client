//
//  MagicShareAPICommonImpl+Resources.swift
//  ByteView
//
//  Created by chentao on 2020/4/20.
//

import Foundation
import RxSwift
import ByteViewNetwork

extension MagicShareAPICommonImpl {

    func bindResources() {
        resources.asObservable()
            .filter({ !$0.isEmpty })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (resources) in
                guard let `self` = self else {
                    return
                }
                let validResources = resources.filter({ $0.type == .jsType && !$0.content.isEmpty })
                let entryResources = validResources.filter({ $0.isEntry })
                let normalResources = validResources.filter({ !$0.isEntry })
                for entry in entryResources {
                    self.debugLog(message: "inject entry js resource id:\(entry.id)")
                    self.injectedResources.append(entry.id)
                    self.followAPI.injectJS(entry.content)
                }
                for normal in normalResources {
                    self.debugLog(message: "inject normal js resource id:\(normal.id)")
                    self.injectedResources.append(normal.id)
                    self.followAPI.injectJS(normal.content)
                }
                self.injectJSCompletion(Date().timeIntervalSince1970)
            }).disposed(by: disposeBag)
    }

    func updateStrategyResources() {
        let iosResourceIds = strategy.iosResourceIds
        // 未注入过的资源才需要注入
        let unInjectedResources = iosResourceIds.filter({ !injectedResources.contains($0) })
        debugLog(message: "has unInjected resources ids:\(unInjectedResources)")
        let platformResourceVersions = strategy.resourceVersions.filter {
            unInjectedResources.contains($0.key)
        }
        guard !platformResourceVersions.isEmpty else {
            debugLog(message: "has empty resources")
            return
        }
        injectStrategiesCompletion(Date().timeIntervalSince1970)
        let request = GetFollowResourcesRequest(resources: platformResourceVersions)
        httpClient.getResponse(request, options: .retry(3, owner: self)) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                Self.logger.info("get resources count:\(response.resources.count) by map:\(platformResourceVersions)")
                self.resources.onNext(response.resources.map({ $0.value }))
            case .failure(let error):
                Self.logger.debug("get resources by map:\(platformResourceVersions), and error:\(error)")
            }
        }
    }
}
