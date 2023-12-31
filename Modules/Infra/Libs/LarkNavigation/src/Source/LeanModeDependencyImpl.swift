//
//  LeanModeDependencyImpl.swift
//  LarkNavigation
//
//  Created by Supeng on 2021/9/28.
//

import UIKit
import Foundation
import LarkLeanMode
import RxSwift
import Swinject

final class LeanModeDependencyImp: LeanModeDependency {
    var routerFromProvider: UIViewController {
        return RootNavigationController.shared.visibleViewController ?? RootNavigationController.shared
    }

    var showLoading: Bool = false {
        didSet {
            RootNavigationController.shared.isLoading = showLoading
        }
    }
}
