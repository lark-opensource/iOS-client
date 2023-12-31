//
//  SimulatorAndJailBreakCheckTask.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2022/9/3.
//

import Foundation
import EENavigator
import LarkContainer
import BootManager
import LarkSetting
import LarkSecurityComplianceInfra
import LarkSceneManager

final class SimulatorAndJailBreakCheckTask: FlowBootTask, Identifiable {
    static var identify: TaskIdentify = "SimulatorAndJailBreakCheckTask"
    private let settingKey = UserSettingKey.make(userKeyLiteral: "lark_security_compliance_config")
    private let rootAndEmulatorDetectKaEnableKey = "root_and_emulator_detect_ka_enable"
    private let rootAndEmulatorDetectDisableKey = "root_and_emulator_detect_disable"
    
    /// 因为越狱检测的 Task 在 BeforeLoginFlow 阶段，需要使用 FlowBootTask，在 FlowBootTask 是无法使用用户态相关的服务的
    /// 所以无法使用 LarkSecurityComplianceInfra 提供的统一接口获取 setting，因此这里单独提供一个 setting 接口供使用
    var settings: [String: Any] {
        guard let current = try? SettingManager.shared.setting(with: settingKey) else { // Get Global Settings
            return [:]
        }
        return current
    }
    
    var rootAndEmulatorDetectKaEnable: Bool {
        let result = (settings[rootAndEmulatorDetectKaEnableKey] as? Bool) ?? false
        SCLogger.info("\(rootAndEmulatorDetectKaEnableKey): \(result)")
        return result
    }
    
    var rootAndEmulatorDetectDisable: Bool {
        let result = (settings[rootAndEmulatorDetectDisableKey] as? Bool) ?? false
        SCLogger.info("\(rootAndEmulatorDetectDisableKey): \(result)")
        return result
    }

    override func execute(_ context: BootContext) {
#if SECURITY_DEBUG
        // lint:disable:next lark_storage_check
        if !UserDefaults.standard.bool(forKey: "detected_trigger") { return } // debug面板开关
#endif
        SCLogger.info("SimulatorAndJailBreakCheckTask execute (not mean the checks are executed!)")
        let queue = DispatchQueue(label: "SimulatorAndJailBreakCheckQueue", qos: .default)
        // 延迟一秒执行任务，来获取到VC来弹出界面
        queue.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self else { return }
            // 在外部初始化setting会导致task时间过长
            if self.rootAndEmulatorDetectKaEnable && !self.rootAndEmulatorDetectDisable {
                let isSimulator = SimulatorCheck.check()
                if isSimulator {
                    Logger.info("simulatorCheck: failed")
                    DispatchQueue.main.async { [weak self] in
                        // 展示弹窗
                        self?.showAlertViewController(detectedType: .simulator)
                    }
                    return
                }

                let isJailBreak = JailBreakCheck.check()
                if isJailBreak {
                    Logger.info("jailBreakCheck: failed")
                    DispatchQueue.main.async { [weak self] in
                        self?.showAlertViewController(detectedType: .jailBreak)
                    }
                    return
                }
            }
        }
    }

    private func showAlertViewController(detectedType: DetectedType) {
        if #available(iOS 13.0, *) {
            closeAllAssitantScenes()
        }
        guard let currentWindow = LayoutConfig.currentWindow, let alertView = SimulatorAndJailBreakAlertViewController(detectedType: detectedType).view else {
            return
        }
        currentWindow.addSubview(alertView)
        alertView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
            currentWindow.bringSubviewToFront(alertView)
        }
    }

    @available(iOS 13.0, *)
    private func closeAllAssitantScenes() {
        for uiScene in SceneManager.shared.windowApplicationScenes {
            let scene = uiScene.sceneInfo
            if !scene.isMainScene() {
                SceneManager.shared.deactive(scene: scene)
            }
        }
        Logger.info("succeed to close all assistant scenes")
    }
}
