//
//  DriveUIStateManagerTests.swift
//  SKDrive_Tests-Unit-_Tests
//
//  Created by ZhangYuanping on 2022/10/21.
//  


import XCTest
import RxSwift
import RxCocoa
import SKFoundation
import UniverseDesignColor
@testable import SKDrive

final class DriveUIStateManagerTests: XCTestCase {
    
    var dependency = MockLandscapeDriveUIStateManagerDependency()
    var protraitDependency = MockPortaitDriveUIStateManagerDependency()
    var bag = DisposeBag()
    
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }
    
    func testSpaceFileExitFullScreen() {
        let expectation = XCTestExpectation(description: "Space Exit FullScreen")
        var uiState = DriveUIState()
        uiState.isStatusBarHidden = false
        uiState.isNavigationbarHidden = false
        uiState.isNaviTrailingButtonHidden = true
        uiState.isBottomBarHidden = true
        uiState.isBannerStackViewHidden = false
        uiState.isInFullScreen = false
        uiState.interactivePopGestureRecognizerEnabled = false
        let sut = DriveUIStateManager(scene: .space, dependency: dependency)
        sut.setup(hostVC: UIViewController())
        sut.previewSituation.accept(.exitFullScreen)
        sut.previewUIState.subscribe(onNext: { state in
            XCTAssertEqual(state, uiState)
            expectation.fulfill()
        }).disposed(by: bag)
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testSpaceFileFullScreen() {
        let expectation = XCTestExpectation(description: "Space Exit FullScreen")
        var uiState = DriveUIState()
        uiState.isStatusBarHidden = true
        uiState.isNavigationbarHidden = true
        uiState.isNaviTrailingButtonHidden = true
        uiState.isBottomBarHidden = true
        uiState.isBannerStackViewHidden = true
        uiState.isInFullScreen = true
        uiState.interactivePopGestureRecognizerEnabled = false
        
        let sut = DriveUIStateManager(scene: .space, dependency: dependency)
        sut.setup(hostVC: UIViewController())
        sut.previewSituation.accept(.fullScreen)
        sut.previewUIState.subscribe(onNext: { state in
            XCTAssertEqual(state, uiState)
            expectation.fulfill()
        }).disposed(by: bag)
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testSpaceFilePresentaion() {
        let expectation = XCTestExpectation(description: "Space Exit FullScreen")
        var uiState = DriveUIState()
        uiState.backgroundColor = .black
        uiState.isStatusBarHidden = true
        uiState.isNavigationbarHidden = true
        uiState.isBottomBarHidden = true
        uiState.isBannerStackViewHidden = true
        uiState.isInFullScreen = true
        uiState.isNaviTrailingButtonHidden = true
        uiState.interactivePopGestureRecognizerEnabled = false
        let sut = DriveUIStateManager(scene: .space, dependency: dependency)
        sut.setup(hostVC: UIViewController())
        sut.previewSituation.accept(.presentaion)
        sut.previewUIState.subscribe(onNext: { state in
            XCTAssertEqual(state, uiState)
            expectation.fulfill()
        }).disposed(by: bag)
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testSpaceFileImageFullScreen() {
        let expectation = XCTestExpectation(description: "Space Exit FullScreen")
        var uiState = DriveUIState()
        uiState.isStatusBarHidden = true
        uiState.isNavigationbarHidden = true
        uiState.isNaviTrailingButtonHidden = false
        uiState.isBottomBarHidden = true
        uiState.isBannerStackViewHidden = true
        uiState.isInFullScreen = true
        uiState.backgroundColor = .black
        uiState.isNaviTrailingButtonHidden = true
        uiState.isBottomBarHidden = true
        uiState.interactivePopGestureRecognizerEnabled = false
        let sut = DriveUIStateManager(scene: .space, dependency: dependency)
        sut.setup(hostVC: UIViewController())
        sut.previewSituation.accept(.imageFullScreen)
        sut.previewUIState.subscribe(onNext: { state in
            XCTAssertEqual(state, uiState)
            expectation.fulfill()
        }).disposed(by: bag)
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testSpaceFileOrientationChange() {
        let expectation = XCTestExpectation(description: "Space Exit FullScreen")
        var uiState = DriveUIState()
        uiState.isStatusBarHidden = false
        uiState.isNavigationbarHidden = false
        uiState.isNaviTrailingButtonHidden = false
        uiState.isBottomBarHidden = false
        uiState.isBannerStackViewHidden = false
        uiState.isInFullScreen = false
        
        let hostVC = MockHostViewController()
        let subVC = MockSubViewController()
        hostVC.addChild(subVC)
        hostVC.view.addSubview(subVC.view)
        subVC.didMove(toParent: hostVC)
        
        let sut = DriveUIStateManager(scene: .space, dependency: protraitDependency)
        sut.setup(hostVC: hostVC)
        sut.orientationDidChangeSubject.onNext(())
        sut.previewUIState.subscribe(onNext: { state in
            XCTAssertEqual(state, uiState)
            expectation.fulfill()
        }).disposed(by: bag)
        wait(for: [expectation], timeout: 3.0)
    }
}

class MockLandscapeDriveUIStateManagerDependency: DriveUIStateManagerDependency {
    var isPhone: Bool {
        return true
    }
    
    var currentOrientation: UIDeviceOrientation {
        return .landscapeLeft
    }
}

class MockPortaitDriveUIStateManagerDependency: DriveUIStateManagerDependency {
    var isPhone: Bool {
        return true
    }
    
    var currentOrientation: UIDeviceOrientation {
        return .portrait
    }
}

class MockHostViewController: UIViewController {
    override var shouldAutorotate: Bool {
        return true
    }
}

class MockSubViewController: UIViewController, DriveAutoRotateAdjustable {
    func orientationDidChange(orientation: UIDeviceOrientation) {
        
    }
}
