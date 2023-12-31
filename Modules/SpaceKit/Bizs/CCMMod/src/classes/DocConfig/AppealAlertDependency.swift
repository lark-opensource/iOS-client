//
//  AppealAlertDependency.swift
//  CCMMod
//
//  Created by tanyunpeng on 2022/9/28.
//  


import EENavigator
import SKDrive
import LarkSecurityCompliance
import LarkSecurityComplianceInfra
import Swinject
import SpaceInterface

class AppealAlertDependencyImpl: AppealAlertDependency {
    
    func openAppealAlert(objToken: String, version: Int, locale: String) {
        
        let body = FileAppealPageBody(objToken: objToken,
                                      version: version ,
                                      fileType: 12,
                                      locale: locale)
        guard let vc = LayoutConfig.currentWindow else { return }
        Navigator.shared.present(body: body, from: vc)
    }
}
