//
//  Debug.swift
//  SuiteLogin
//
//  Created by Yiming Qu on 2019/11/11.
//
//
// export internal class for debug
//

import Foundation
import LarkContainer
import RxSwift

public class DebugFactory {

    @Provider var loginService: V3LoginService

    @Provider var launcher: Launcher

    @Provider var switchUserService: NewSwitchUserService

    public let disposeBag = DisposeBag()

    public static let shared: DebugFactory = DebugFactory()
}
