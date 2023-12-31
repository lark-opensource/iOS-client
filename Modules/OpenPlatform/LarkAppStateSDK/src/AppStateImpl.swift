//
//  AppStateImpl.swift
//  LarkAppStateSDK
//
//  Created by ByteDance on 2023/6/25.
//

import Foundation
import LarkOPInterface
import LarkContainer
import RustPB
import RxSwift
import LKCommonsLogging
import LarkRustClient

public final class AppStateImpl: AppStateService {
    static let logger = Logger.log(AppStateImpl.self, category: "AppStateImpl")
    private let netDisposeBag: DisposeBag = DisposeBag()
    private let localDisposeBag: DisposeBag = DisposeBag()
    private let client: RustService?
    
    private let resolver: UserResolver
    
    init(resolver: UserResolver) {
        self.resolver = resolver
        self.client = try? resolver.resolve(assert: RustService.self)
    }
    
    public func getMiniAppControlInfo(appID: String, callback: (RustPB.Openplatform_V1_GetMiniAppControlInfoResponse?) -> Void) {
    }
    
    public func getBotControlInfo(appID: String, callback: (RustPB.Openplatform_V1_GetBotControlInfoResponse?) -> Void) {
    }
    
    public func getWebControlInfo(appID: String, callback:@escaping (RustPB.Openplatform_V1_GetH5ControlInfoResponse?) -> Void) {
        Self.logger.info("AppStateImpl: getWebControlInfo, appId:\(appID)")
        AppStateSDK.shared.updateLastUsedTimeWith(appID: appID)
        var request = Openplatform_V1_GetH5ControlInfoRequest()
        request.appID = appID
        request.strategy = .localOnly
        let ob: Observable<RustPB.Openplatform_V1_GetH5ControlInfoResponse>? = self.client?.sendAsyncRequest(request)
        ob?.observeOn(MainScheduler.instance).subscribe(onNext: { (localResponse) in
            request.strategy = .netOnly
            if localResponse.h5Info.hasAppID && localResponse.h5Info.status == .usable {
                Self.logger.info("AppStateImpl: h5 localResponse status is usable")
                callback(localResponse)
                self.client?.sendAsyncRequest(request).subscribe(onNext:{ _ in
                    OPMonitor(name: AppStateDefines.monitorName, code: EPMClientOpenPlatformAppStrategyCode.h5_state_success)
                        .setResultTypeSuccess()
                        .addCategoryValue("appID", appID)
                        .addCategoryValue("strategy", "network")
                        .flush()
                }, onError: { (error) in
                    OPMonitor(name: AppStateDefines.monitorName, code: EPMClientOpenPlatformAppStrategyCode.h5_state_fail)
                        .setResultTypeFail()
                        .addCategoryValue("appID", appID)
                        .addCategoryValue("strategy", "network")
                        .setError(error)
                        .flush()
                }).disposed(by: self.netDisposeBag)
            } else {
                Self.logger.info("AppStateImpl: h5 localResponse status is not usable")
                let startTime = CFAbsoluteTimeGetCurrent()
                let netDataOb: Observable<RustPB.Openplatform_V1_GetH5ControlInfoResponse>? = self.client?.sendAsyncRequest(request)
                netDataOb?.observeOn(MainScheduler.instance).subscribe(onNext: {(netResponse) in
                    OPMonitor(name: AppStateDefines.monitorName, code: EPMClientOpenPlatformAppStrategyCode.h5_state_success)
                        .setResultTypeSuccess()
                        .addCategoryValue("appID", appID)
                        .addCategoryValue("strategy", "network")
                        .flush()
                    callback(netResponse)
                }, onError: {(error) in
                    OPMonitor(name: AppStateDefines.monitorName, code: EPMClientOpenPlatformAppStrategyCode.h5_state_fail)
                        .setResultTypeFail()
                        .addCategoryValue("appID", appID)
                        .addCategoryValue("strategy", "network")
                        .setError(error)
                        .flush()
                    callback(localResponse)
                }).disposed(by: self.netDisposeBag)
            }
        }, onError: { (error) in
            OPMonitor(name: AppStateDefines.monitorName, code: EPMClientOpenPlatformAppStrategyCode.h5_state_fail)
                .setResultTypeFail()
                .addCategoryValue("appID", appID)
                .addCategoryValue("strategy", "local")
                .setError(error)
                .flush()
            callback(nil)
        }).disposed(by: self.localDisposeBag)
    }
    
    public func presentAlert(appID: String, appName: String, tips: Openplatform_V1_GuideTips, VC: UIViewController, appType: AppType, closeAppBlock: (() -> Void)?) {
        Self.logger.info("AppStateImpl: presentAlert, appId:\(appID), appType:\(appType)")
        GuideTipHandler(resolver: resolver).presentAlert(appId: appID,
                                                         appName: appName,
                                                         tip: tips,
                                                         webVC: VC,
                                                         appType: appType,
                                                         closeAppBlock: closeAppBlock)
    }
    
}
