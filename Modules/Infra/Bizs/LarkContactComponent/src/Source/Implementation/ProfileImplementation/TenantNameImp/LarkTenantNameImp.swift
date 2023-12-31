//
//  LarkTenantNameIml.swift
//  LarkContactComponent
//
//  Created by ByteDance on 2023/3/20.
//

import Foundation
import UIKit

final class LarkTenantNameImp: LarkTenantNameService {

    func generateTenantNameView(with uiConfig: LarkTenantNameUIConfig) -> LarkTenantNameViewInterface {
        let tenantNameView = LarkTenantNameView(uiConfig: uiConfig)
        return tenantNameView
    }

}
