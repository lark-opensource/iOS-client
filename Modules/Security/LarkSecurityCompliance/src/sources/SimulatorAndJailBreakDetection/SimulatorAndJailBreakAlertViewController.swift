//
//  SimulatorAndJailBreakAlertViewController.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2022/8/31.
//

import Foundation
import LarkSecurityComplianceInfra
import UniverseDesignDialog

enum DetectedType {
    case simulator
    case jailBreak
}

final class SimulatorAndJailBreakAlertViewController: UIViewController {
    
    // 初始化的检测类型为模拟器类型
    private var detectedType: DetectedType = .simulator
    
    convenience init(detectedType: DetectedType) {
        self.init()
        
        self.detectedType = detectedType
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 12.0, *) {
            if traitCollection.userInterfaceStyle == .dark {
                view.backgroundColor = .black
            } else {
                // swiftlint:disable:next init_color_with_token
                view.backgroundColor = UIColor(red: 153 / 255, green: 153 / 255, blue: 153 / 255, alpha: 1)
            }
        } else {
            // swiftlint:disable:next init_color_with_token
            view.backgroundColor = UIColor(red: 153 / 255, green: 153 / 255, blue: 153 / 255, alpha: 1)
        }
        switch detectedType {
        case .simulator:
            showSimulatorDetectedAlert()
        case .jailBreak:
            showJailBreakDetectedAlert()
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13, *) {
            if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                if self.traitCollection.userInterfaceStyle == .dark {
                    view.backgroundColor = .black
                } else {
                    // swiftlint:disable:next init_color_with_token
                    view.backgroundColor = UIColor(red: 153 / 255, green: 153 / 255, blue: 153 / 255, alpha: 1)
                }
            }
        }
    }
    
    private func showSimulatorDetectedAlert() {
        let dialog = UDDialog()
        dialog.setTitle(text: I18NSuiteAdminFrontend.SuiteAdmin_ROOTDetect_Dialog_UnableToUseWithDevice)
        dialog.setContent(text: I18NSuiteAdminFrontend.SuiteAdmin_ROOTDetect_Dialog_DeviceInEmulationMode)
        addChild(dialog)
        view.addSubview(dialog.view)
        dialog.view.frame = view.frame
    }
    
    private func showJailBreakDetectedAlert() {
        let dialog = UDDialog()
        dialog.setTitle(text: I18NSuiteAdminFrontend.SuiteAdmin_ROOTDetect_Dialog_UnableToUseWithDevice)
        dialog.setContent(text: I18NSuiteAdminFrontend.SuiteAdmin_ROOTDetect_Dialog_DeviceJailbroken)
        addChild(dialog)
        view.addSubview(dialog.view)
        dialog.view.frame = view.frame
    }
    
}
