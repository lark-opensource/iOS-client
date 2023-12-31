//
//  WorkplacePreviewController+LarkNaviBarDataSource.swift
//  LarkWorkplace
//
//  Created by Meng on 2022/10/13.
//

import Foundation
import RxRelay
import LarkNavigation
import LarkUIKit

extension WorkplacePreviewController: LarkNaviBarDataSource {
    var isNaviBarLoading: BehaviorRelay<Bool> {
        templateVC?.isNaviBarLoading ?? BehaviorRelay(value: false)
    }

    var titleText: BehaviorRelay<String> {
        templateVC?.titleText ?? BehaviorRelay(value: BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_Title)
    }

    var isNaviBarEnabled: Bool {
        templateVC?.isNaviBarEnabled ?? true
    }

    var isDrawerEnabled: Bool { false }

    var useNaviButtonV2: Bool { true }
    
    var bizScene: LarkNaviBarBizScene? {
        return .workplace
    }

    func larkNaviBarV2(userDefinedButtonOf type: LarkNaviButtonTypeV2) -> UIButton? {
        return templateVC?.larkNaviBarV2(userDefinedButtonOf: type)
    }

    func larkNaviBarV2(
        userDefinedColorOf type: LarkNaviButtonTypeV2, state: UIControl.State
    ) -> UIColor? {
        return templateVC?.larkNaviBarV2(userDefinedColorOf: type, state: state)
    }
}
