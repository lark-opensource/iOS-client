//
//  BDPAppPageControllerExtension.swift
//  TTMicroApp
//
//  Created by laisanpin on 2022/5/13.
//

import Foundation
import UIKit
import LKCommonsLogging
import LarkUIKit
import OPFoundation
import OPSDK

fileprivate let logger = Logger.oplog(BDPAppPageController.self, category: "BDPAppPageControllerExtension")

@objc extension BDPAppPageController {
    open override var shouldAutorotate: Bool {
        guard OPGadgetRotationHelper.enableGadgdetRotation(self.uniqueID) else {
            return BDPDeviceManager.shouldAutorotate()
        }

        if forceAutorotate {
            return true
        }

        switch pageOrientation {
        case .notSet:
            return false
        case .portrait:
            return false
        case .landscape:
            return true
        case .auto:
            return true
        @unknown default:
            return BDPDeviceManager.shouldAutorotate()
        }
    }

    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        guard OPGadgetRotationHelper.enableGadgdetRotation(self.uniqueID) else {
            return .portrait
        }

        // iOS16之后,shouldAutorotate不再生效(是iOS16.0(20A5339d)测试结果);
        // 后面都是直接依靠supportedInterfaceOrientations来控制是否自动旋转.因此这边需要根据业务配置返回正确的方向
        if #available(iOS 16.0, *) {
            // 止血开关, 如果iOS16正式发布后修改了规则, 那么通过该开关关闭自动旋转功能
            if OPSDKFeatureGating.disableIOS16Orientation() {
                return .portrait
            }

            switch pageOrientation {
            case .notSet:
                return .portrait
            case .portrait:
                return .portrait
            case .landscape:
                // 手势侧滑返回的时候,系统会询问当前页面所支持方向(时机很早),然后进行旋转
                // 在当前页面没有开始展现的时候就开始读取配置并开始旋转, 效果并不符合预期
                if self.hadDidAppeared && !self.isAppeared {
                    return .allButUpsideDown
                }
                return .landscape
            case .auto:
                return .allButUpsideDown
            @unknown default:
                return .portrait
            }
        } else {
            switch pageOrientation {
                // portrait/notset配置这个是因为横屏返回竖屏后, 这边配置portrait会崩溃.
                // 保持竖屏是通过在shouldAutorate方法中返回false来实现
            case .notSet:
                return .allButUpsideDown
            case .portrait:
                return .allButUpsideDown
            case .landscape:
                return .landscape
            case .auto:
                return .allButUpsideDown
            @unknown default:
                return .portrait
            }
        }
    }

    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        guard OPGadgetRotationHelper.enableGadgdetRotation(self.uniqueID) else {
            return
        }

        coordinator.animate(alongsideTransition: nil) { (_) in
            if let appPage = self.appPage {
                self.fireOnPageResizeEvent(pageSize: appPage.bdp_size, sourceID: appPage.appPageID)
            }
            self.forceAutorotate = false
        }
    }

    /// 当前页面所用Orientation状态
    public func currentPageOrientation(appConfig: BDPAppConfig?, pageConfig: BDPPageConfig?) -> GadgetMetaOritation {
        guard OPGadgetRotationHelper.enableGadgdetRotation(self.uniqueID) else {
            return .notSet
        }

        let appPageOrientation = appPageOrientation(pageConfig)
        // 如果当前页面没有配置该字段, 则读取全局配置中该字段配
        guard appPageOrientation != .notSet else {
            return appOrientation(appConfig)
        }
        return appPageOrientation
    }

    /// 调整当前页面方向
    public func adjustInterfaceOrientation() {
        guard OPGadgetRotationHelper.enableGadgdetRotation(self.uniqueID) else {
            return
        }

        // iOS 16下开启止血开关, 那么通过该开关关闭自动旋转功能
        if #available(iOS 16.0, *), OPSDKFeatureGating.disableIOS16Orientation() {
            return
        }

        // 解决通过侧滑返回手势从B小程序返回A小程时,前后2个页面方向不同时, A页面无法正确恢复成正确方向问题.
        // 当通过手势侧滑退出小程序时, OPGadgetontainer的containerDidHide方法(在containerController的didDisAppear中被调用)
        // 会在下一个runloop中调用containerController的onApplicationExitWithRestoreStatus方法.
        // 这个方法会将屏幕重置成竖屏.而这个执行会晚于这个方法的调用, 因此会导致界面无法恢复成原先的状态.
        // 因此这边也将该方法放到下一个runloop中执行,并增加一个延迟, 确保在重置竖屏之后执行.
        DispatchQueue.main.async {
            // 页面展现后, 需要根据用户配置进行旋转. 如portrait->landscape, 需要进入横屏后进行旋转.
            switch self.pageOrientation {
                // 这边从非竖屏返回时, 需要恢复竖屏;
            case .portrait:
                self.forcePortraitIfNeed()
            case .notSet:
                self.forcePortraitIfNeed()
            case .landscape:
                if (OPGadgetRotationHelper.currentDeviceOrientation() == .landscapeLeft) {
                    BDPDeviceManager.deviceInterfaceOrientationAdapt(to: UIInterfaceOrientation.landscapeLeft)
                } else {
                    BDPDeviceManager.deviceInterfaceOrientationAdapt(to: UIInterfaceOrientation.landscapeRight)
                }
            case .auto:
                logger.info("auto case do nothing")
            @unknown default:
                logger.warn("should not go default. pageOrientation is invalid: \(self.pageOrientation)")
                self.forcePortraitIfNeed()
                break
            }
        }
    }

    public func fireOnPageResizeEvent(pageSize: CGSize, sourceID: Int) {
        guard OPGadgetRotationHelper.enableGadgdetRotation(self.uniqueID) else {
            return
        }

        guard let uniqueID = self.uniqueID else {
            logger.warn("current page uniqueID is nil", tag: String.BDPAppPageRotationTag)
            return
        }

        guard let task = BDPTaskManager.shared().getTaskWith(uniqueID),
              let engine = task.context else {
                  logger.warn("can not find engine for: \(uniqueID.fullString)", tag: String.BDPAppPageRotationTag)
                  return
              }

        let screenWidth = UIScreen.main.bounds.size.width
        let screenHeight = UIScreen.main.bounds.size.height

        let data: [String : Any] = ["size" :
                                        ["pageWidth" : pageSize.width,
                                         "pageHeight" : pageSize.height,
                                         "windowWidth": self.view.bdp_width,
                                         "windowHeight": self.view.bdp_height,
                                         "screenWidth" : screenWidth,
                                         "screenHeight" : screenHeight],
                                    "webviewId" : sourceID,
                                    "pageOrientation" : OPGadgetRotationHelper.configPageInterfaceResponse(pageInterfaceOrientation)]

        logger.info("\(uniqueID) onPageResize: \(data)", tag: String.BDPAppPageRotationTag)

        engine.bdp_fireEvent("onPageResize", sourceID: sourceID, data: data)
    }

    func forcePortraitIfNeed() {
        if (OPGadgetRotationHelper.currentDeviceOrientation() != .portrait) {
            forceAutorotate = true
            BDPDeviceManager.deviceInterfaceOrientationAdapt(to: UIInterfaceOrientation.portrait)
        }
    }

    /// 当前页面pageOrientation状态
    func appPageOrientation(_ pageConfig: BDPPageConfig?) -> GadgetMetaOritation {
        guard let pageOrientation = pageConfig?.window?.pageOrientation else {
                  logger.info("pageConfig is nil or user not set pageOrientation", tag: String.BDPAppPageRotationTag)
                  return .notSet
              }
        reportConfigOrientationInfo(true, pageOrientation)
        return OPGadgetRotationHelper.convertOritation(pageOrientation)
    }

    /// 当前小程序pageOrientation状态
    func appOrientation(_ appConfig: BDPAppConfig?) -> GadgetMetaOritation {
        guard let pageOrientation = appConfig?.window?.pageOrientation else {
                  logger.info("pageConfig is nil or user not set pageOrientation", tag: String.BDPAppPageRotationTag)
                  return .notSet
              }

        reportConfigOrientationInfo(false, pageOrientation)
        return OPGadgetRotationHelper.convertOritation(pageOrientation)
    }

    ///  上报从json中读取pageOrientation配置信息
    /// - Parameters:
    ///   - fromAppPageJson: 是否配置在页面的json中
    ///   - orientation: 用户配置的方向
    func reportConfigOrientationInfo(_ fromAppPageJson: Bool, _ orientation: String) {
        guard let uniqueID = self.uniqueID else {
            logger.warn("uniqueID is nil when report orientationConfig")
            return
        }

        guard let common = BDPCommonManager.shared().getCommonWith(uniqueID),
              let meta = common.model else {
                  logger.warn("cannot find meta for uniqueID: \(BDPSafeString(uniqueID.fullString))")
                  return
              }

        let orientation_type = fromAppPageJson ? "page_setting" : "app_setting"
        let applicationID = uniqueID.appID
        OPMonitor("openplatform_micro_program_page_orientation_view")
            .addCategoryValue("application_id", BDPSafeString(applicationID))
            .addCategoryValue("orientation_type", orientation_type)
            .addCategoryValue("page_orientation_value", orientation)
            .addCategoryValue("program_version_id", BDPSafeString(meta.appVersion))
            .setPlatform(.tea)
            .flush()
    }
}

fileprivate extension String {
    static let BDPAppPageRotationTag = "BDPAppPageRotationTag"
}

@objcMembers
public final class OPGadgetRotationHelper: NSObject {
    public static func enableGadgdetRotation(_ uniqueID: BDPUniqueID?) -> Bool {
        
        // 半屏状态下，不允许旋转
        if BDPXScreenManager.isXScreenMode(uniqueID) {
            return false
        }
        
        guard OPSDKFeatureGating.enablePageOrientation() else {
            return false
        }

        guard let uniqueID = uniqueID else {
            logger.warn("uniqueID is nil")
            return false
        }

        guard uniqueID.appType == .gadget else {
            logger.warn("current app is not gadget")
            return false
        }

        // iPad也使用原逻辑,不读取配置中的"appPageOrientation"配置信息
        if Display.pad {
            logger.warn("current device is iPad, should not read appPageOrientation", tag: String.BDPAppPageRotationTag)
            return false
        }

        // tab小程序也不读取配置中的"appPageOrientation"配置信息
        if isTabGadget(uniqueID) {
            logger.warn("\(BDPSafeString(uniqueID.fullString)) is tabGadget, not support rotation", tag: String.BDPAppPageRotationTag)
            return false
        }

        return true
    }

    // 相关API是否返回方向信息
    public static func enableResponseOrientationInfo() -> Bool {
        guard OPSDKFeatureGating.enablePageOrientation() else {
            return false
        }

        // iPad也使用原逻辑,不读取配置中的"appPageOrientation"配置信息
        if isPad() {
            logger.info("current device is iPad, should not read appPageOrientation", tag: String.BDPAppPageRotationTag)
            return false
        }

        return true
    }

    /// 将pageOrientation字符串转换成GadgetMetaOritation
    public static func convertOritation(_ pageOrientation: String) -> GadgetMetaOritation {
        if (pageOrientation == "auto") {
            return .auto
        }

        if (pageOrientation == "landscape") {
            return .landscape
        }

        if (pageOrientation == "portrait") {
            return .portrait
        }

        return .notSet
    }

    public static func isPad() -> Bool {
        return Display.pad
    }

    public static func isTabGadget(_ uniqueID: BDPUniqueID?) -> Bool {
        guard let uniqueID = uniqueID else {
            logger.warn("uniqueID is nil", tag: String.BDPAppPageRotationTag)
            return false
        }

        guard let container = OPApplicationService.current.getContainer(uniuqeID: uniqueID),
              let mountData = container.containerContext.currentMountData else {
                  logger.warn("cannot get mountData \(uniqueID.fullString)", tag: String.BDPAppPageRotationTag)
                  return false
              }

        let scene = mountData.scene
        logger.info("current gagdet \(uniqueID.fullString) scene: \(scene) ", tag: String.BDPAppPageRotationTag)
        return scene == .mainTab || scene == .convenientTab
    }

    public static func configPageInterfaceResponse(_ interface: UIInterfaceOrientation) -> String {
        switch interface {
        case .unknown:
            return ""
        case .portrait:
            return "portrait"
        case .portraitUpsideDown:
            return ""
        case .landscapeLeft:
            return "landscapeReverse"
        case .landscapeRight:
            return "landscape"
        @unknown default:
            return ""
        }
    }

    public static func currentDeviceOrientation() -> UIInterfaceOrientation {
        return UIApplication.shared.statusBarOrientation
    }

    /// 获取导航栏高度. 横屏下不同设备下小于400pt的设备导航栏高度为32pt, 大于400pt导航栏高度则为44pt.
    /// 调用前需使用enableGadgdetRotation判断FG是否允许
    public static func navigationBarHeight() -> Double {
        let kRegularDeviceHorizontalNavigationBarHeight = 44.0
        let kCompactDeviceHorizontalNavigationBarHeight = 32.0

        if isLandscape() {
            if let size = OPWindowHelper.fincMainSceneWindow()?.bounds.size {
                let width = min(size.width, size.height)
                return width < 400 ? kCompactDeviceHorizontalNavigationBarHeight : kRegularDeviceHorizontalNavigationBarHeight
            }
        }

        return kRegularDeviceHorizontalNavigationBarHeight
    }

    public static func isLandscape() -> Bool {
        let orientation = UIApplication.shared.statusBarOrientation
        return orientation == .landscapeLeft || orientation == .landscapeRight
    }

    /// 横屏下的安全区域
    /// 调用前需使用enableGadgdetRotation判断FG是否允许
    public static func opHorizontalSafeArea() -> UIEdgeInsets {
        guard let window = OPWindowHelper.fincMainSceneWindow() else {
            return .zero
        }

        // 判断是否为刘海屏设备
        if (window.safeAreaInsets.bottom != 0) {
            return UIEdgeInsets(top: 0, left: 48, bottom: 21, right: 48)
        }

        return .zero
    }
}
