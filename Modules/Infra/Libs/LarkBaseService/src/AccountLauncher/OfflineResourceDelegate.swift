//
//  OfflineResourceDelegate.swift
//  LarkApp
//
//  Created by Miaoqi Wang on 2019/12/4.
//

import Foundation
import Swinject
import RxSwift
import LarkAccountInterface
import OfflineResourceManager
import LarkFeatureGating
import LKCommonsLogging
import RustPB
import LarkRustClient

public final class OfflineResourceDelegate {

    public var name: String = "OfflineResourceManager"
    private static let logger = Logger.log(OfflineResourceDelegate.self)
    fileprivate static let updateQueue = DispatchQueue(label: "com.lark.baseService.offlineResoureDelegate")

    private let resolver: Resolver
    private let disposeBag = DisposeBag()

    public init(resolver: Resolver) {
        self.resolver = resolver
    }

    func updateDevice() {
        OfflineResourceManager.setGurdEnable()
        // in case env change
        let domain = OfflineResourceApplicationDelegate.geckoDomain()
        OfflineResourceManager.setDomain(domain)

        let deviceService = resolver.resolve(DeviceService.self)! // Global
        OfflineResourceManager.setDeviceId(deviceService.deviceId)
    }

    func updateSetting() {
        // update setting after login for this user
        var request = RustPB.Settings_V1_GetSettingsRequest()
        request.fields = [URLMapHandler.dynamicUrlMapKey]

        resolver.resolve(RustService.self)!
            .sendAsyncRequest(request, transform: { (response: Settings_V1_GetSettingsResponse) -> [String: String] in
                response.fieldGroups
            })
            .subscribeOn(scheduler)
            .subscribe(onNext: { (settingDic) in
                OfflineResourceDelegate.logger.debug("fetched dynamic settings")
                OfflineResourceDelegate.updateDynamicConfig(settings: settingDic)
            })
            .disposed(by: disposeBag)
    }
}

extension OfflineResourceDelegate {

    class func updateDynamicConfig(settings: [String: String]) {
        updateQueue.async {
            // 更新动态化配置，先移除旧的配置
            OfflineResourceManager.removeBizConfigs(of: [.dynamic])

            guard let mappers = URLMapHandler.getDynamicURLMappers(settingDic: settings) else {
                OfflineResourceDelegate.logger.info("no mapper setting will not register biz")
                return
            }

            let bizConfigs = mappers.map({ (mapper) -> OfflineResourceBizConfig in
                let urlInfo = mapper.dynamicUrlInfo
                return OfflineResourceBizConfig(
                    bizID: urlInfo.bizName,
                    bizKey: urlInfo.accessKey,
                    subBizKey: urlInfo.channel,
                    bizType: .dynamic
                )
            })

            OfflineResourceManager.registerBiz(configs: bizConfigs)
            bizConfigs.forEach { (cfg) in
                OfflineResourceManager.fetchResource(byId: cfg.bizID)
            }
        }
    }
}
