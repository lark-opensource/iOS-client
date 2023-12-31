//
//  LeanModeMockAssembly.swift
//  LarkLeanMode
//
//  Created by 袁平 on 2020/3/11.
//

import UIKit
import Swinject
import RxSwift

public final class LeanModeMockAssembly {

    private var dependency: (Resolver) -> LeanModeDependency

    public init(dependency: ((Resolver) -> LeanModeDependency)? = nil) {
        self.dependency = dependency ?? { _ in return LeanModeMockDependency() }
    }
}

open class LeanModeMockDependency: LeanModeDependency {
    public init() {}

    public var routerFromProvider: UIViewController {
        return UIViewController()
    }

    public var showLoading: Bool = false
}
