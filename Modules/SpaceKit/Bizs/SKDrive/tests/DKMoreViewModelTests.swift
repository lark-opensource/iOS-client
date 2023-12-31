//
//  DKMoreViewModelTests.swift
//  SKDrive-Unit-Tests
//
//  Created by majie.7 on 2022/3/9.
//

import XCTest
import OHHTTPStubs
import SwiftyJSON
import SKFoundation
import SKCommon
import RxSwift
import RxRelay
import SpaceInterface
@testable import SKDrive


class DKMoreViewModelTests: XCTestCase {
    
    func testAttachItemDidClicked() {
        let moreVisable = BehaviorRelay<Bool>(value: true)
        let moreEnable = BehaviorRelay<Bool>(value: true)
        let isReachable = BehaviorRelay<Bool>(value: true)
        let saveToSpaceState = BehaviorRelay<DKSaveToSpaceState>(value: .unsave)
        let dependency = DKMoreDependencyImpl(moreVisable: moreVisable.asObservable(),
                                              moreEnable: moreEnable.asObservable(),
                                              isReachable: isReachable.asObservable(),
                                              saveToSpaceState: saveToSpaceState.asObservable())
        let viewModel = DKMoreViewModel(dependency: dependency, moreType: .attach(items: []))
        let result: Bool
        if case .present = viewModel.itemDidClicked() {
            result = true
        } else {
            result = false
        }
        XCTAssertTrue(result)
    }
    
    func testSpaceItemDidClicked() {
        let moreVisable = BehaviorRelay<Bool>(value: true)
        let moreEnable = BehaviorRelay<Bool>(value: true)
        let isReachable = BehaviorRelay<Bool>(value: true)
        let saveToSpaceState = BehaviorRelay<DKSaveToSpaceState>(value: .unsave)
        let dependency = DKMoreDependencyImpl(moreVisable: moreVisable.asObservable(),
                                              moreEnable: moreEnable.asObservable(),
                                              isReachable: isReachable.asObservable(),
                                              saveToSpaceState: saveToSpaceState.asObservable())
        let viewModel = DKMoreViewModel(dependency: dependency, moreType: .space)
        let result: Bool
        if case .presentSpaceMoreVC = viewModel.itemDidClicked() {
            result = true
        } else {
            result = false
        }
        XCTAssertTrue(result)
    }
}
