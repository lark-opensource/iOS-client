//
//  LarkCoreDependency.swift
//  LarkCore
//
//  Created by 袁平 on 2020/11/20.
//

import UIKit
import Foundation
import RxSwift
import LarkModel
import SwiftyJSON

public typealias LarkCoreDependency = LarkCoreAvatarDependency & LarkCoreVCDependency

public protocol LarkCoreVCDependency {
    func showQuataAlertFromVC(_ vc: UIViewController)
}

public protocol LarkCoreAvatarDependency {
    func fetchRawAvatarApplicationList(appVersion: String, accessToken: String) -> Observable<(Int?, JSON)>
}
