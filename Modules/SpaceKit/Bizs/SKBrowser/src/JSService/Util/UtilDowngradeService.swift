//
//  UtilDowngradeService.swift
//  SKBrowser
//
//  Created by ByteDance on 2022/11/28.
//

import Foundation
import SKCommon
import SKFoundation
import RustPB
import LarkRustClient
import RxSwift
import LarkContainer
import SpaceInterface
import SKInfra

/// 监听Rust推送的性能降级的通知，再告知前端（用于在出现功耗问题时让前端减少耗电量）
class UtilDowngradeService: BaseJSService {
    
    typealias DowngradeStrategyModel = Tool_V1_PushCpuManagerMagicShareSceneDowngradeStrategy
    
    // 2022年策略，rust降级策略
    private let callback = DocsJSCallBack("lark.biz.perf.onDowngradeStatusChange")
    
    // 2023年策略，VC降级策略
    private let callbackV2 = DocsJSCallBack("lark.biz.perf.onMSDowngradeStatusChange")
    
    // 单个文档内发生降级的次数
    public private(set) var downgradeCounter = 0
    
    private var disposeBag = DisposeBag()
    
    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
        PowerConsumptionExtendedStatistic.shared.registerMSDegradeHandler(self)
        if UserScopeNoChangeFG.CS.msDowngradeNewStrategyEnable,
           let service = try? model.userResolver.resolve(assert: CCMMagicShareDowngradeService.self) {
            service.perfInfoObservable.subscribe(onNext: { [weak self] in
                self?.handleDowngradeV2($0)
            }).disposed(by: disposeBag)
        }
    }
    
    deinit {
        DocsLogger.info("downgrade handler: \(ObjectIdentifier(self)) deinit")
    }
    
    private func handleDowngradeV2(_ info: CCMMagicSharePerfInfo) {
        if msNewDowngradeEnable() == false { return }
        let params = info.encodedDict()
        self.model?.jsEngine.callFunction(callbackV2, params: params, completion: nil)
        DocsLogger.info("handleDowngradeV2 => \(params)")
    }
    
    private func msNewDowngradeEnable() -> Bool {
        let enable: Bool
        if let optConfig = try? model?.userResolver.resolve(assert: PowerOptimizeConfigProvider.self) {
            enable = optConfig.vcPowerDowngradeEnable
        } else {
            enable = false
        }
        return enable
    }
}

extension UtilDowngradeService: MSDegradeRustPushHandler {
    
    func handleDowngradePush(payload: Data) {
        if msNewDowngradeEnable() == true { return }
        let isInVC = self.model?.hostBrowserInfo.isInVideoConference ?? false
        
        guard isInVC else { // MS中的文档才进行降级
            DocsLogger.info("not in MS, handle downgrade ignored.")
            return
        }
        
        let model: DowngradeStrategyModel?
        do {
            model = try DowngradeStrategyModel(serializedData: payload)
        } catch {
            model = nil
            DocsLogger.error("parse DowngradeStrategyModel failed:\(error)")
        }
        
        let webviewId = self.model?.jsEngine.editorIdentity ?? ""
        let extraInfo = "webviewId:\(webviewId), isInVC:\(isInVC)"
        DocsLogger.info("handle downgrade rust push, data:\(payload), model:\(String(describing: model)), \(extraInfo)")
        
        guard let model = model else { return }
        
        if model.hasMsStrategy {
            let strategy = model.msStrategy
            var params = [String: Any]()
            if strategy.hasSendCursorDebounce {
                params["sendCursorDebounce"] = Int(strategy.sendCursorDebounce)
            }
            if strategy.hasUpdateCursorShortThrottle {
                params["updateCursorShortThrottle"] = Int(strategy.updateCursorShortThrottle)
            }
            if strategy.hasUpdateCursorLongThrottle {
                params["updateCursorLongThrottle"] = Int(strategy.updateCursorLongThrottle)
            }
            if strategy.hasMemberBufferActiveConsumeInterval {
                params["memberBufferActiveConsumeInterval"] = Int(strategy.memberBufferActiveConsumeInterval)
            }
            if strategy.hasEngineBufferActiveConsumeInterval {
                params["engineBufferActiveConsumeInterval"] = Int(strategy.engineBufferActiveConsumeInterval)
            }
            self.model?.jsEngine.callFunction(callback, params: params, completion: nil)
            DocsLogger.info("handleDowngrade => \(params)")
            downgradeCounter += 1
        } else {
            self.model?.jsEngine.callFunction(callback, params: nil, completion: nil)
            DocsLogger.info("handleDowngrade => null")
        }
    }
}

extension UtilDowngradeService: DocsJSServiceHandler {
    
    public var handleServices: [DocsJSService] {
        []
    }

    public func handle(params: [String: Any], serviceName: String) {
        
    }
}

extension UtilDowngradeService {
    
    /// 获取当前的MS降级信息
    static func getCurrentMSPowerDowngradeInfoParams(userResolver: LarkContainer.UserResolver) -> [String: Any]? {
        guard UserScopeNoChangeFG.CS.msDowngradeNewStrategyEnable else {
            return nil
        }
        if let service = try? userResolver.resolve(assert: CCMMagicShareDowngradeService.self) {
            let dict = service.currentPerfInfo?.encodedDict()
            return dict
        } else {
            return nil
        }
    }
}

extension CCMMagicSharePerfInfo {
    /// 传给前端的字典
    func encodedDict() -> [String: Any] {
        [
            "level": level,
            "details": [
                "systemLoad": systemLoadScore,
                "dynamic": dynamicScore,
                "thermal": thermalScore,
                "openDoc": openDocScore
            ]
        ]
    }
}
