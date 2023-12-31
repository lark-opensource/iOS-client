//
//  RouteOCBadge.swift
//  EEMicroAppSDK
//
//  Created by kongkaikai on 2021/6/16.
//

import OPGadget
import LarkSetting
import Foundation
import OPSDK

@objc
public final class RouteOCBadge: NSObject {
    @objc
    public class func gadgetContainerService(from applicationService: OPApplicationService) -> OPGadgetContainerService {
        applicationService.gadgetContainerService()
    }
}

@objc
public final class AppLinkOCBadge: NSObject {
    @objc
    public class func domainCurrentSetting() -> Array<String>? {
        DomainSettingManager.shared.currentSetting["applink"]
    }
}

