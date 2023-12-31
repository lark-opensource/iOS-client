//
//  SensitivityControlModelRegister.swift
//  SecurityComplianceDebug
//
//  Created by qingchun on 2022/9/24.
//

import Foundation
import LarkSecurityCompliance
import LarkSecurityComplianceInfra
import BDRuleEngine
import EENavigator
import AppContainer
import LarkContainer
import LarkSensitivityControl

final class SensitivityControlModelRegister: SCDebugModelRegister {
    
    let userResolver: UserResolver
    
    required init(resolver: LarkContainer.UserResolver) {
        self.userResolver = resolver
    }
    
    func registModels() {
        // 已有的单元格注册
        guard let debugEntrance = try? userResolver.resolve(assert: SCDebugEntrance.self) else { return }
        debugEntrance.regist(section: .sncInfra) {
            SCDebugModel(cellTitle: "Sensitivity Control", cellType: .normal, normalHandler: {
                self.navigatorToSensitivityControlVC()
            })
        }

        debugEntrance.regist(section: .sncInfra) {
            SCDebugModel(cellTitle: "Sensitivity API Invoke", cellType: .normal, normalHandler: {
                self.navigatorToSensitivityAPIVC()
            })
        }

        debugEntrance.regist(section: .sncInfra) {
            SCDebugModel(cellTitle: "Token List", cellType: .normal, normalHandler: {
                self.navigatorToSensitivityTokenListVC()
            })
        }

        debugEntrance.regist(section: .sncInfra) {
            SCDebugModel(cellTitle: "Local Token List", cellType: .normal, normalHandler: {
                self.navigatorToSensitivityLocalTokenVC()
            })
        }

        debugEntrance.regist(section: .sncInfra) {
            SCDebugModel(cellTitle: "Mock", cellType: .normal, normalHandler: {
                self.navigatorToSensitivityMockVC()
            })
        }

        debugEntrance.regist(section: .sncInfra) {
            SCDebugModel(cellTitle: "Privacy Monitor", cellType: .normal, normalHandler: {
                self.navigatorToPrivacyMonitorVC()
            })
        }

        debugEntrance.regist(section: .sncInfra) {
            SCDebugModel(cellTitle: "Pasteboard Test", cellType: .normal, normalHandler: {
                self.navigatorToSensitivityPasteboardVC()
            })
        }

        debugEntrance.regist(section: .sncInfra) {
            SCDebugModel(cellTitle: "Monitor Debug", cellType: .normal, normalHandler: {
                self.navigatorToMonitorDebugVC()
            })
        }
    }

    private func navigatorToSensitivityPasteboardVC() {
        let vc = SensitivityPasteboardViewController()
        guard let currentVC = self.userResolver.navigator.mainSceneTopMost else { return }
        navigator.push(vc, from: currentVC)
    }

    private func navigatorToSensitivityTokenListVC() {
        let vc = SensitivityTokenListViewController(resolver: userResolver)
        guard let currentVC = self.userResolver.navigator.mainSceneTopMost else { return }
        navigator.push(vc, from: currentVC)
    }

    private func navigatorToSensitivityLocalTokenVC() {
        let vc = SensitivityLocalTokenViewController()
        guard let currentVC = self.userResolver.navigator.mainSceneTopMost else { return }
        Navigator.shared.push(vc, from: currentVC)
    }

    private func navigatorToSensitivityMockVC() {
        let vc = SensitivityMockViewController(resolver: userResolver)
        guard let currentVC = self.userResolver.navigator.mainSceneTopMost else { return }
        navigator.push(vc, from: currentVC)
    }

    private func navigatorToSensitivityAPIVC() {
        let vc = SensitivityAPIViewController()
        guard let currentVC = self.userResolver.navigator.mainSceneTopMost else { return }
        navigator.push(vc, from: currentVC)
    }

    private func navigatorToMonitorDebugVC() {
        let vc = MonitorDebugVC()
        guard let currentVC = self.userResolver.navigator.mainSceneTopMost else { return }
        Navigator.shared.push(vc, from: currentVC)
    }

    // 页面跳转方法
    private func navigatorToSensitivityControlVC() {
        let vm = SensitivityControlViewModel(resolver: userResolver)
        let vc = SensitivityViewControl(viewModel: vm)
        let service = try? resolver.resolve(assert: SCDebugService.self)
        service?.showViewController(vc)
    }

    func navigatorToPrivacyMonitorVC() {
        BDRuleParameterBuilderModel.prepareForMock()
        BDRuleEngineSettings.prepareForMock()
        let debugVC = BDRuleEngineDebugEntryViewController()
        let backBtn = UIButton(frame: CGRect(x: 60, y: 400, width: 300, height: 48))
        backBtn.backgroundColor = .blue
        backBtn.setTitle("Close Page", for: UIControl.State.normal)
        backBtn.addTarget(self, action: #selector(backBtnClick(sender:)), for: .touchUpInside)
        debugVC.view.addSubview(backBtn)
        let service = try? resolver.resolve(assert: SCDebugService.self)
        service?.showViewController(debugVC)
    }

    @objc
    func backBtnClick(sender: UIButton) {
        let service = try? resolver.resolve(assert: SCDebugService.self)
        service?.dismissCurrentWindow()
    }

}
