//
//  DebugRegister.swift
//  SecurityComplianceDebug
//
//  Created by qingchun on 2022/9/18.
//

import Foundation
import LarkSecurityCompliance
import LarkSecurityComplianceInfra
import LarkSceneManager
import LarkContainer

final class DefaultDebugRegister: SCDebugModelRegister {
    
    let userResolver: UserResolver
    
    required init(resolver: LarkContainer.UserResolver) {
        self.userResolver = resolver
    }
    
    @ScopedProvider var settings: SCSettingService?
    
    func registModels() {
        guard let debugEntrance = try? userResolver.resolve(assert: SCDebugEntrance.self) else { return }
        debugEntrance.regist(section: .deviceSecurity) {
            SCDebugModel(cellTitle: "simulator/jailBreak detect trigger", cellType: .normal, normalHandler: { [weak self] in
                guard let self, let fromVC = self.userResolver.navigator.mainSceneTopMost else { return }
                let value = UserDefaults.standard.bool(forKey: "detected_trigger")
                UserDefaults.standard.set(!value, forKey: "detected_trigger")
                Alerts.showAlert(from: fromVC, title: "detected_trigger", content: String(UserDefaults.standard.bool(forKey: "detected_trigger")), actions: [
                    Alerts.AlertAction(title: "我知道了", style: .default, handler: nil)])
            })
        }
        
        debugEntrance.regist(section: .deviceSecurity) {
            SCDebugModel(cellTitle: "simulator/jailBreak detect result", cellType: .normal, normalHandler: { [weak self] in
                guard let self, let fromVC = self.userResolver.navigator.mainSceneTopMost else { return }
                let simulatorCheckResult = SimulatorCheck.check()
                let jailBreakCheckResult = JailBreakCheck.check()
                Alerts.showAlert(from: fromVC, title: "detected_trigger", content: "simulator check: " + String(simulatorCheckResult) + "\njailBreak check: " + String(jailBreakCheckResult), actions: [
                    Alerts.AlertAction(title: "我知道了", style: .default, handler: nil)])
            })
        }
        
        debugEntrance.regist(section: .deviceSecurity) {
            SCDebugModel(cellTitle: "simulator detected page", cellType: .normal, normalHandler: { [weak self] in
                if #available(iOS 13.0, *) {
                    Self.closeAllAssitantScenes()
                }
                guard let self,
                      let currentWindow = self.userResolver.navigator.mainSceneWindow,
                      let alertView = implicitResolver?.resolve(SCDebugService.self)?.getSimulatorAlertView() else {
                    return
                }
                currentWindow.addSubview(alertView)
                alertView.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }
                Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
                    currentWindow.bringSubviewToFront(alertView)
                }
            })
        }
        
        
        debugEntrance.regist(section: .deviceSecurity) {
            SCDebugModel(cellTitle: "jailBreak detected page", cellType: .normal, normalHandler: { [weak self] in
                if #available(iOS 13.0, *) {
                    Self.closeAllAssitantScenes()
                }
                guard let self,
                      let currentWindow = self.userResolver.navigator.mainSceneWindow,
                      let alertView = implicitResolver?.resolve(SCDebugService.self)?.getJailBreakAlertView() else {
                    return
                }
                currentWindow.addSubview(alertView)
                alertView.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }
                Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
                    currentWindow.bringSubviewToFront(alertView)
                }
            })
        }
    }
    
    @available(iOS 13.0, *)
    private static func closeAllAssitantScenes() {
        for uiScene in SceneManager.shared.windowApplicationScenes {
            let scene = uiScene.sceneInfo
            if !scene.isMainScene() {
                SceneManager.shared.deactive(scene: scene)
            }
        }
        Logger.info("succeed to close all assistant scenes")
    }
}
