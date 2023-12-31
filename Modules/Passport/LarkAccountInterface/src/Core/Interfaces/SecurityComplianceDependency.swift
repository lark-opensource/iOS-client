//
//  SecurityComplianceDependency.swift
//  LarkAccountInterface
//
//  Created by bytedance on 2022/6/8.
//

import Foundation
import UIKit

public protocol SecurityComplianceDependency: AnyObject {

    ///  返回条件访问的 window
    func securityComplianceWindow() -> UIWindow?
}
