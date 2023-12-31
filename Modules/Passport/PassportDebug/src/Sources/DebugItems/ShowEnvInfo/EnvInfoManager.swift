//
//  EnvInfoManager.swift
//  PassportDebug
//
//  Created by ByteDance on 2022/7/20.
//

import Foundation
import LarkUIKit
import LKCommonsLogging
import EENavigator
import UIKit

protocol EnvInfoManagerDelegate: AnyObject {
    func updateButtonStatus()
}

final class EnvInfoManager {
    weak var envInfoManagerDelegate: EnvInfoManagerDelegate?
    static let logger = Logger.log(EnvInfoManager.self, category: "Env.EnvInfoManager")
    private var envInfoView: EnvInfoView?
    static var shared: EnvInfoManager = EnvInfoManager()
    var isEnvInfoViewExist: Bool {
        guard let view = envInfoView else {
            return false
        }
        return true
    }
    
    private init() {
        let _ = UIWindow.hookDidAddSubview
    }
    
    private func getEnvInfoView() -> EnvInfoView {
        guard let view = envInfoView else {
            let view = EnvInfoView()
            envInfoView = view
            return view
        }
        return view
    }
    
    func makeEnvInfoViewTop() {
        guard let envInfoView = envInfoView,
              envInfoView.superview == Navigator.shared.mainSceneWindow else {
            return
        }
        envInfoView.superview?.bringSubviewToFront(envInfoView)
    }
    
    func showEnvInfoView() {
        let envInfoView = getEnvInfoView()
        let mainWindow = Navigator.shared.mainSceneWindow
        if envInfoView.superview == nil {
            mainWindow?.addSubview(envInfoView)
            let rect = CGRect(x: 20, y: 60, width: Display.phone ? 160 : 300, height: Display.phone ? 150 : 220)
            envInfoView.snp.makeConstraints {
                $0.size.equalTo(rect.size)
                $0.left.lessThanOrEqualTo(rect.minX)
                $0.top.lessThanOrEqualTo(rect.minY)
                $0.right.lessThanOrEqualToSuperview()
                let safeArea = mainWindow?.safeAreaInsets ?? UIEdgeInsets.zero
                $0.top.greaterThanOrEqualTo(safeArea.top)
                $0.bottom.lessThanOrEqualTo(-safeArea.bottom)
            }
            UserDefaults.standard.set(true, forKey: "isEnvInfoViewShow")
            EnvInfoManager.logger.info("Show the view of enviroment information")
        }
    }
    
    func changeEnvInfoViewConstraints(rect: CGRect) {
        guard let envInfoView = envInfoView,
              let mainWindow = envInfoView.superview else {
            return
        }
        envInfoView.snp.remakeConstraints {
            $0.size.equalTo(rect.size)
            $0.left.lessThanOrEqualTo(rect.minX)
            $0.top.lessThanOrEqualTo(rect.minY)
            $0.right.lessThanOrEqualToSuperview()
            let safeArea = mainWindow.safeAreaInsets ?? UIEdgeInsets.zero
            $0.top.greaterThanOrEqualTo(safeArea.top)
            $0.bottom.lessThanOrEqualTo(-safeArea.bottom)
        }
    }
    
    func removeEnvInfoView() {
        guard let view = envInfoView else {
            return
        }
        view.removeFromSuperview()
        envInfoView = nil
        UserDefaults.standard.set(false, forKey: "isEnvInfoViewShow")
        EnvInfoManager.logger.info("Destroty the view of enviroment information")
    }
    
    func initEnvInfoView() {
        if UserDefaults.standard.bool(forKey: "isEnvInfoViewShow") {
            showEnvInfoView()
        }
    }
    
    
}


