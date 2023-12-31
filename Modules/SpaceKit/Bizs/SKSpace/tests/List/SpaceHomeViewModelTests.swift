//
//  SpaceHomeViewModelTests.swift
//  SKSpace-Unit-Tests
//
//  Created by zoujie on 2022/12/1.
//  

import XCTest
@testable import SKSpace
@testable import SKCommon
@testable import SKFoundation
import SKResource
import RxSwift
import LarkContainer

class MockDefaultLocationProvider: WorkspaceDefaultLocationProvider {
    static var defaultLocation: Result<WorkspaceCreateLocation?, Error> = .success(nil)
    static func getDefaultCreateLocation() throws -> WorkspaceCreateLocation? {
        try defaultLocation.get()
    }
}

class SpaceHomeViewModelTests: XCTestCase {

    var disposeBag = DisposeBag()
    let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)

    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
        disposeBag = DisposeBag()
    }

    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
    }

    func testSpaceBitableHome() {
        let viewModel = SpaceStandardHomeViewModel.bitableHome(userResolver: userResolver, module: .baseHomePage(context: BaseHomeContext(userResolver: userResolver, containerEnv: .workbench, baseHpFrom: nil, version: .original)))
        viewModel.notifyViewDidLoad()
        viewModel.notifyViewDidAppear()
        if case let .baseHomePage(_) = viewModel.createContext.module {
            
        } else {
            XCTFail("un-expected create context module found: \(viewModel.createContext.module)")
            return
        }
    }

    func testOfflineCreateToMyLibrary() {
        let context = SpaceCreateContext(module: .home(.recent),
                                         mountLocation: .myLibrary,
                                         folderType: nil)
        let homeVM = LarkSpaceHomeViewModel(userResolver: userResolver,
                                            createContext: context,
                                            badgeConfig: SpaceEmptyBadgeConfig(),
                                            defaultLocationProvider: MockDefaultLocationProvider.self,
                                            netMonitorType: MockRxNetworkMonitor.self)
        MockRxNetworkMonitor.statusRelay.accept((.notReachable, isReachable: false))
        let createDisableExpect = expectation(description: "test create disabled")
        homeVM.createEnableDriver.drive(onNext: { enable in
            XCTAssertTrue(enable)
            createDisableExpect.fulfill()
        })
        .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)
    }

    func testOfflineCreateToDefaultMyLibrary() {
        let context = SpaceCreateContext(module: .home(.recent),
                                         mountLocation: .default,
                                         folderType: nil)
        let homeVM = LarkSpaceHomeViewModel(userResolver: userResolver,
                                            createContext: context,
                                            badgeConfig: SpaceEmptyBadgeConfig(),
                                            defaultLocationProvider: MockDefaultLocationProvider.self,
                                            netMonitorType: MockRxNetworkMonitor.self)
        MockDefaultLocationProvider.defaultLocation = .success(.myLibrary)
        MockRxNetworkMonitor.statusRelay.accept((.notReachable, isReachable: false))
        let createDisableExpect = expectation(description: "test create disabled")
        homeVM.createEnableDriver.drive(onNext: { enable in
            XCTAssertTrue(enable)
            createDisableExpect.fulfill()
        })
        .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)
    }

    func testOfflineCreateToDefaultMySpace() {
        let context = SpaceCreateContext(module: .home(.recent),
                                         mountLocation: .default,
                                         folderType: nil)
        let homeVM = LarkSpaceHomeViewModel(userResolver: userResolver,
                                            createContext: context,
                                            badgeConfig: SpaceEmptyBadgeConfig(),
                                            defaultLocationProvider: MockDefaultLocationProvider.self,
                                            netMonitorType: MockRxNetworkMonitor.self)
        MockDefaultLocationProvider.defaultLocation = .success(.mySpaceV2)
        MockRxNetworkMonitor.statusRelay.accept((.notReachable, isReachable: false))
        let createDisableExpect = expectation(description: "test create disabled")
        homeVM.createEnableDriver.drive(onNext: { enable in
            XCTAssertTrue(enable)
            createDisableExpect.fulfill()
        })
        .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)
    }

    func testOfflineCreateToDefaultUnknown() {
        let context = SpaceCreateContext(module: .home(.recent),
                                         mountLocation: .default,
                                         folderType: nil)
        let homeVM = LarkSpaceHomeViewModel(userResolver: userResolver,
                                            createContext: context,
                                            badgeConfig: SpaceEmptyBadgeConfig(),
                                            defaultLocationProvider: MockDefaultLocationProvider.self,
                                            netMonitorType: MockRxNetworkMonitor.self)
        MockDefaultLocationProvider.defaultLocation = .success(nil)
        MockRxNetworkMonitor.statusRelay.accept((.notReachable, isReachable: false))
        let createDisableExpect = expectation(description: "test create disabled")
        homeVM.createEnableDriver.drive(onNext: { enable in
            XCTAssertFalse(enable)
            createDisableExpect.fulfill()
        })
        .disposed(by: disposeBag)

        let disableClickExpect = expectation(description: "test click when disabled")
        homeVM.actionSignal.emit(onNext: { action in
            guard case let .showHUD(hudAction) = action,
                  case let .warning(tips) = hudAction else {
                XCTFail("un-expected action found: \(action)")
                disableClickExpect.fulfill()
                return
            }
            XCTAssertEqual(tips, BundleI18n.SKResource.Doc_Facade_CreateFailed)
            disableClickExpect.fulfill()
        })
        .disposed(by: disposeBag)
        homeVM.disabledCreateTrigger?.accept(())
        waitForExpectations(timeout: 1)
    }

    func testOfflineCreateToDefaultInvalidUnknown() {
        let context = SpaceCreateContext(module: .home(.recent),
                                         mountLocation: .default,
                                         folderType: nil)
        let homeVM = LarkSpaceHomeViewModel(userResolver: userResolver,
                                            createContext: context,
                                            badgeConfig: SpaceEmptyBadgeConfig(),
                                            defaultLocationProvider: MockDefaultLocationProvider.self,
                                            netMonitorType: MockRxNetworkMonitor.self)
        MockRxNetworkMonitor.statusRelay.accept((.notReachable, isReachable: false))
        MockDefaultLocationProvider.defaultLocation = .success(.default)
        let createDisableExpect = expectation(description: "test create disabled")
        homeVM.createEnableDriver.drive(onNext: { enable in
            XCTAssertFalse(enable)
            createDisableExpect.fulfill()
        })
        .disposed(by: disposeBag)

        let disableClickExpect = expectation(description: "test click when disabled")
        homeVM.actionSignal.emit(onNext: { action in
            guard case let .showHUD(hudAction) = action,
                  case let .warning(tips) = hudAction else {
                XCTFail("un-expected action found: \(action)")
                disableClickExpect.fulfill()
                return
            }
            XCTAssertEqual(tips, BundleI18n.SKResource.Doc_Facade_CreateFailed)
            disableClickExpect.fulfill()
        })
        .disposed(by: disposeBag)
        homeVM.disabledCreateTrigger?.accept(())
        waitForExpectations(timeout: 1)
    }
}
