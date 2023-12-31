//
//  DriveUIStateManger.swift
//  SKDrive
//
//  Created by ZhangYuanping on 2022/10/17.
//  

import RxSwift
import RxCocoa
import SKCommon
import SKUIKit
import SKFoundation
import UniverseDesignColor

class DriveUIStateManager {
    // output
    let previewUIState = BehaviorRelay<DriveUIState>(value: DriveUIState())

    // input
    let previewSituation = BehaviorRelay<DrivePreviewSituation>(value: .exitFullScreen)
    let commentBarEnable = BehaviorRelay<Bool>(value: true)
    let orientationDidChangeSubject = PublishSubject<Void>()

    var previewScene: DKPreviewScene
    var dependency: DriveUIStateManagerDependency

    private var orientationChangedhandler: ((_ isLandscape: Bool) -> Void)?
    private weak var hostViewController: UIViewController?
    private let disposeBag = DisposeBag()

    init(scene: DKPreviewScene, dependency: DriveUIStateManagerDependency) {
        DocsLogger.driveInfo("uiState: DriveUIStateManager Init, scene: \(scene)")
        self.previewScene = scene
        self.dependency = dependency
    }

    func setup(hostVC: UIViewController,
               handler: ((_ isLandscape: Bool) -> Void)? = nil) {
        self.hostViewController = hostVC

        NotificationCenter.default.rx
            .notification(UIApplication.didChangeStatusBarOrientationNotification)
            .observeOn(MainScheduler.instance).map { _ in () }
            .bind(to: orientationDidChangeSubject)
            .disposed(by: disposeBag)

        orientationDidChangeSubject.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] in
            self?.orientationDidChange()
        }).disposed(by: disposeBag)

        previewSituation.skip(1).subscribe(onNext: { [weak self] situation in
            self?.updateUIState(situation: situation)
        }).disposed(by: disposeBag)

        commentBarEnable.skip(1).subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            let currentSituation = self.previewSituation.value
            self.updateUIState(situation: currentSituation)
        }).disposed(by: disposeBag)
    }

    private func orientationDidChange() {
        guard let hostViewController = hostViewController else { return }
        // 只有开启自动旋转且是 iPhone 才会响应屏幕旋转事件，避免污染 iPad 的情况
        guard hostViewController.shouldAutorotate == true, dependency.isPhone else { return }
        let orientation = dependency.currentOrientation
        // 实现 AutoRotateAjustable 的 ChildVC(即当前预览的页面) 可以通过 orientationDidChange 特化处理屏幕旋转的情况
        if let currentChildVC = hostViewController.children.last as? DriveAutoRotateAdjustable {
            currentChildVC.orientationDidChange(orientation: orientation)
        }

        if orientation.isLandscape {
            orientationChangedhandler?(true)
        }
        if orientation == .portrait {
            orientationChangedhandler?(false)
        }

        // 横竖屏切换后更新 UI 状态
        let currentSituation = previewSituation.value
        DocsLogger.driveInfo("uiState: orientationDidChange, current: \(currentSituation)")
        updateUIState(situation: currentSituation)
    }

    private func updateUIState(situation: DrivePreviewSituation) {
        var uiState = DriveUIState()
        switch situation {
        case .fullScreen:
            uiState.isStatusBarHidden = true
            uiState.isNavigationbarHidden = true
            uiState.isNaviTrailingButtonHidden = false
            uiState.isBottomBarHidden = true
            uiState.isBannerStackViewHidden = true
            uiState.isInFullScreen = true
        case .exitFullScreen:
            uiState.isStatusBarHidden = false
            uiState.isNavigationbarHidden = false
            uiState.isNaviTrailingButtonHidden = false
            uiState.isBottomBarHidden = false
            uiState.isBannerStackViewHidden = false
            uiState.isInFullScreen = false
        case .presentaion:
            uiState.backgroundColor = .black
            uiState.isStatusBarHidden = true
            uiState.isNavigationbarHidden = true
            uiState.isBottomBarHidden = true
            uiState.isBannerStackViewHidden = true
            uiState.isInFullScreen = true
        case .imageFullScreen:
            uiState.isStatusBarHidden = true
            uiState.isNavigationbarHidden = true
            uiState.isNaviTrailingButtonHidden = false
            uiState.isBottomBarHidden = true
            uiState.isBannerStackViewHidden = true
            uiState.isInFullScreen = true
            uiState.backgroundColor = .black
        }
        if dependency.isPhone {
            let orientation = dependency.currentOrientation
            if orientation.isLandscape {
                uiState.isNaviTrailingButtonHidden = previewScene == .space
                // nolint-next-line: magic number
                if #available(iOS 16.0, *) {
                    // iOS16 隐藏更多按钮，避免横屏下弹出页面让状态栏错乱
                    uiState.isNaviTrailingButtonHidden = true
                }
                uiState.isBottomBarHidden = true
                uiState.interactivePopGestureRecognizerEnabled = false
            }
            if orientation == .portrait {
                uiState.interactivePopGestureRecognizerEnabled = true
            }
        }
        if commentBarEnable.value == false {
            uiState.isBottomBarHidden = true
        }
        self.previewUIState.accept(uiState)
    }
}

struct DriveUIState: Equatable {
    var isStatusBarHidden: Bool = false // 状态栏是否隐藏
    var isNavigationbarHidden: Bool = false // 导航栏是否隐藏
    var isBottomBarHidden: Bool = false // 底部栏是否隐藏
    var isNaviTrailingButtonHidden: Bool = false // 导航栏右边更多按钮是否隐藏
    var displayMode: DrivePreviewMode = .normal // 卡片态or普通态
    var backgroundColor: DriveUIStateColor? // 背景色
    var interactivePopGestureRecognizerEnabled = true // 侧滑返回是否生效
    var isBannerStackViewHidden: Bool = true
    var isInFullScreen: Bool = false
}

enum DrivePreviewSituation {
    case fullScreen
    case exitFullScreen
    case imageFullScreen
    case presentaion
}

enum DriveUIStateColor {
    case black
    case base

    var udColor: UIColor {
        switch self {
        case .black: return UDColor.staticBlack
        case .base: return UDColor.bgBase
        }
    }
}

protocol DriveUIStateManagerDependency {
    var isPhone: Bool { get }
    var currentOrientation: UIDeviceOrientation { get }
}

class DriveUIStateManagerDependencyImpl: DriveUIStateManagerDependency {
    var isPhone: Bool {
        return SKDisplay.phone
    }

    var currentOrientation: UIDeviceOrientation {
        return LKDeviceOrientation.convertMaskOrientationToDevice(UIApplication.shared.statusBarOrientation)
    }
}
