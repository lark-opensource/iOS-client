//
//  TopBarViewModelTest.swift
//  LarkMessengerUnitTest
//
//  Created by 夏汝震 on 2020/9/23.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import XCTest
import RxSwift
import RxCocoa
import RustPB
import LarkSDKInterface
import LarkModel
import LarkFeatureGating
import LarkAccountInterface
import RunloopTools
@testable import LarkFeed

class TopBarViewModelTest: XCTestCase {

    private var disposeBag: DisposeBag!
    private var dependency: TopBarViewModelMockDependency!
    private var topBarViewModel: TopBarViewModel!
    private let viewHeight = 40 as CGFloat

    override class func setUp() {
        MockAccountService.login()
        RunloopDispatcher.enable = true // 打开RunloopTool
    }

    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
        dependency = TopBarViewModelMockDependency()
    }

    override func tearDown() {
        disposeBag = nil
        dependency = nil
        topBarViewModel = nil
        super.tearDown()
    }
}

extension TopBarViewModelTest {

    /*
     有网+无status：什么都不展示
     有网+有status：展示status
     无网+无status：展示无网
     无网+无status：展示无网
     */

    //case 1: 有网+无status：什么都不展示
    func test_netStatus_1() {
        /// 设置有网状态
        let status = PushDynamicNetStatus(dynamicNetStatus: .excellent)
        dependency.pushDynamicNetStatusBuilder = {
            return .just(status)
        }

        /// 稍后处理
        let count = 0
        dependency.markLaterCountBuilder = {
            return .just(count)
        }

        /// 当前有效设备
        dependency.validSessionsBuilder = {
            return .just([])
        }

        /// 通知状态变化信号
        dependency.isNotifyObservableBuilder = {
            return .just(false)
        }

        // 等待信号发出并接收
        topBarViewModel = TopBarViewModel(dependency: dependency)
        mainWait()

        // 网络状态通知
        XCTAssert(topBarViewModel.netStatus == .normal)

        // 团队是否显示
        XCTAssert(topBarViewModel.isShowGroup == false)

        // 团队未读Badge
        topBarViewModel.pushAccountBadgeDriver.drive(onNext: { (badgeType) in
            XCTAssert(badgeType == .none)
        }).disposed(by: disposeBag)

        // 稍后处理：只有markLaterCount > 1就显示
        dependency.markLaterCountBuilder = {
            return .just(count)
        }

        topBarViewModel.markLaterCountDriver.drive(onNext: { number in
            XCTAssert(number == count)
        }).disposed(by: disposeBag)

        // 消息通知
        XCTAssert(topBarViewModel.notificationState == .none)

        // 身份/稍后处理通知
        XCTAssert(topBarViewModel.isShowStatus == false)

        // 读取输出
        XCTAssert(topBarViewModel.display == false)
        XCTAssert(topBarViewModel.viewHeight == 0)
    }

    //case 2: 无网+无status：展示无网
    func test_netStatus_2() {
        /// 设置无网状态
        let status = PushDynamicNetStatus(dynamicNetStatus: .netUnavailable)
        dependency.pushDynamicNetStatusBuilder = {
            return .just(status)
        }

        /// 稍后处理
        let count = 0
        dependency.markLaterCountBuilder = {
            return .just(count)
        }

        /// 当前有效设备
        dependency.validSessionsBuilder = {
            return .just([])
        }

        /// 通知状态变化信号
        dependency.isNotifyObservableBuilder = {
            return .just(false)
        }

        // 等待信号发出并接收
        topBarViewModel = TopBarViewModel(dependency: dependency)
        mainWait()

        // 网络状态通知
        XCTAssert(topBarViewModel.netStatus == .noNetwork)

        // 稍后处理：只有markLaterCount > 1就显示
        dependency.markLaterCountBuilder = {
            return .just(count)
        }

        topBarViewModel.markLaterCountDriver.drive(onNext: { number in
            XCTAssert(number == count)
        }).disposed(by: disposeBag)

        // 消息通知
        XCTAssert(topBarViewModel.notificationState == .none)

        // 身份/稍后处理通知
        XCTAssert(topBarViewModel.isShowStatus == false)

        // 读取输出
        XCTAssert(topBarViewModel.display == true)
        XCTAssert(topBarViewModel.viewHeight == viewHeight)
    }

    //case 3: 无网+有status：展示无网
    func test_netStatus_3() {

        /// 设置无网状态
        let status = PushDynamicNetStatus(dynamicNetStatus: .netUnavailable)
        dependency.pushDynamicNetStatusBuilder = {
            return .just(status)
        }

        /// 稍后处理
        let count = 10
        dependency.markLaterCountBuilder = {
            return .just(count)
        }

        /// 当前有效设备
        dependency.validSessionsBuilder = {
            var sessionModel = ValidSessionModel()
            sessionModel.terminal = .pc
            sessionModel.isOnline = true
            return .just([sessionModel])
        }

        /// 通知状态变化信号
        dependency.isNotifyObservableBuilder = {
            return .just(true)
        }

        // 等待信号发出并接收
        topBarViewModel = TopBarViewModel(dependency: dependency)
        mainWait()

        // 网络状态通知
        XCTAssert(topBarViewModel.netStatus == .noNetwork)

        // 稍后处理：只有markLaterCount > 1就显示
        dependency.markLaterCountBuilder = {
            return .just(count)
        }

        topBarViewModel.markLaterCountDriver.drive(onNext: { number in
            XCTAssert(number == count)
        }).disposed(by: disposeBag)

        // 消息通知
        XCTAssert(topBarViewModel.notificationState == .open)

        // 身份/稍后处理通知
        XCTAssert(topBarViewModel.isShowStatus == true)

        // 读取输出
        XCTAssert(topBarViewModel.display == true)
        XCTAssert(topBarViewModel.viewHeight == viewHeight)
    }

    //case 4: 有网+有status：展示status
    func test_netStatus_4() {

        /// 设置有网状态
        let status = PushDynamicNetStatus(dynamicNetStatus: .excellent)
        dependency.pushDynamicNetStatusBuilder = {
            return .just(status)
        }

        /// 稍后处理
        let count = 10
        dependency.markLaterCountBuilder = {
            return .just(count)
        }

        /// 当前有效设备
        dependency.validSessionsBuilder = {
            var sessionModel = ValidSessionModel()
            sessionModel.terminal = .pc
            sessionModel.isOnline = true
            return .just([sessionModel])
        }

        /// 通知状态变化信号
        dependency.isNotifyObservableBuilder = {
            return .just(true)
        }

        // 等待信号发出并接收
        topBarViewModel = TopBarViewModel(dependency: dependency)
        mainWait()

        // 网络状态通知
        XCTAssert(topBarViewModel.netStatus == .normal)

        // 稍后处理：只有markLaterCount > 1就显示
        dependency.markLaterCountBuilder = {
            return .just(count)
        }

        topBarViewModel.markLaterCountDriver.drive(onNext: { number in
            XCTAssert(number == count)
        }).disposed(by: disposeBag)
        // 消息通知
        XCTAssert(topBarViewModel.notificationState == .open)

        // 身份/稍后处理通知
        XCTAssert(topBarViewModel.isShowStatus == true)

        // 读取输出
        XCTAssert(topBarViewModel.display == true)
        XCTAssert(topBarViewModel.viewHeight == viewHeight)
    }
}

private class TopBarViewModelMockDependency: TopBarViewModelDependency {

    /// 网络状态
    var pushDynamicNetStatusBuilder: (() -> Observable<PushDynamicNetStatus>)?
    var pushDynamicNetStatusOb: Observable<PushDynamicNetStatus> {
        if let builder = pushDynamicNetStatusBuilder {
            return builder()
        }
        return .empty()
    }
    /// 稍后处理
    var markLaterCountBuilder: (() -> Observable<Int>)?
    var markLaterCountDriver: Driver<Int> {
        if let builder = markLaterCountBuilder {
            return builder().asDriver(onErrorJustReturn: 0)
        }
        return .empty()
    }

    /// 当前有效设备
    var validSessionsBuilder: (() -> Observable<[ValidSessionModel]>)?
    var validSessions: Observable<[ValidSessionModel]> {
        if let builder = validSessionsBuilder {
            return builder()
        }
        return .empty()
    }

    /// 通知状态变化信号
    var isNotifyObservableBuilder: (() -> Observable<Bool>)?
    var isNotifyObservable: Observable<Bool> {
        if let builder = isNotifyObservableBuilder {
            return builder()
        }
        return .empty()
    }
}
