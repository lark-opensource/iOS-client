//
//  SideBarVCReigistry.swift
//  LarkNavigation
//
//  Created by CharlieSu on 1/2/20.
//

import Foundation
import UIKit
import LarkUIKit
import LarkContainer

public typealias SideBarVC = (UserResolver, UIViewController?) throws -> UIViewController?

var sideBarVC: SideBarVC?
var sideBarFilterVC: SideBarVC?

public enum SideBarVCRegistry {
    public static func registerSideBarVC(_ vc: @escaping SideBarVC) {
        sideBarVC = vc
    }
    public static func registerSideBarFilterVC(_ vc: @escaping SideBarVC) {
        sideBarFilterVC = vc
    }
}
