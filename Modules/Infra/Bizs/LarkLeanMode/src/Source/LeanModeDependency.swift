//
//  LeanModeDependency.swift
//  LarkLeanMode
//
//  Created by 袁平 on 2020/3/10.
//

import UIKit
import RxSwift

public protocol LeanModeDependency {
    var routerFromProvider: UIViewController { get }
    var showLoading: Bool { get set }
}
