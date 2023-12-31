//
//  LarkRoomWebViewManager.swift
//  LarkRVC
//
//  Created by zhouyongnan on 2022/7/12.
//

import Foundation
import UIKit
import LarkSuspendable
import RoundedHUD
import LKCommonsLogging
import EENavigator
import LarkUIKit
import LarkSetting
import UniverseDesignTheme
import RxSwift
import RxCocoa
import OPFoundation
import WebBrowser
import LarkEnv
import LarkSensitivityControl
import LarkNavigator
import LarkContainer
import LarkStorage

public final class LarkRoomWebViewManager: NSObject {
    static let env = LarkEnv.EnvManager.env

    private static let floatingWindowKey = "RVCFloatingWindow"
    private static let shareURL = "feishu://client/byteview/share"

    // 扫码绑定
    private static let scanBindURLPattern = "^http(s)?\\:(.*)/view/room_bind/scan/bind(.*)"

    // 不显示导航栏的larkRoom h5页面（目前只有rvc和白板）
    private(set) static var hiddenNavigationBarPathList: [String] = [
        "rvc/scan",
        "whiteboard/save"
    ]

    static let logger = Logger.log(LarkRoomWebViewManager.self, category: "LarkRoom")
    static let loggerH5 = Logger.log(LarkRoomWebViewManager.self, category: "LarkRoom-H5")

    static private var getDeviceIdHandler: (() -> String)?

    static var getWatermarkInfoHandler: ((_ userID: String) -> Observable<(String, String)>)?
    static var shareImageToChatHandler: ((_ userID: String, UIViewController, [String]) -> Void)?
    static var copyMessageWithSecurity: ((String, Bool) -> Void)?

    private static var needSavedPath: [String] = []
    static var currentSaveImagePSDAToken: String?

    static let saveResult = PublishRelay<Bool>()
    static var saveResultObservable: Observable<Bool> {
        return saveResult.asObservable()
    }

    static var urlSettings: LarkRoomURLConfig?
    private static var registerRoutePatternList: [String] = []

    enum URLParams: String {
        case from // 悬浮窗点击进入RVC时需要在已有的url中添加from=float的参数，便于H5端做token的校验检测
        case paddingTop // 用于控制导航栏到屏幕顶部的间距
        case language = "lang" // 语言
        case deviceId = "deviceID" // deviceId
        case userId = "user_id"
        case featureEnv = "x-tt-env"
        case boeFd = "BOEFdKey"
        case mode = "mode" // dark or light mode

        static var featureEnvValue: String {
            return KVPublic.Common.ttenv.value() ?? ""
        }
        static var boeFdValue: String {
            // lint:disable:next lark_storage_check
            return UserDefaults.standard.string(forKey: self.boeFd.rawValue) ?? ""
        }

        static let fromFloatValue: String = "float"
        static var languageValue: String {
            return BundleI18n.currentLanguage.rawValue.replacingOccurrences(of: "_", with: "")
        }
        static var deviceIdValue: String {
            guard let did = LarkRoomWebViewManager.getDeviceIdHandler?() else {
                logger.error("did not find deviceId")
                assertionFailure()
                return ""
            }
            return did
        }

        static var modeValue: String {
            if #available(iOS 13.0, *), UDThemeManager.getRealUserInterfaceStyle() == .dark {
                // dark mode
                return "dark"
            } else {
                // light mode
                return "light"
            }
        }

    }
}

// 对外暴露方法
extension LarkRoomWebViewManager {

    public static func registerRouter() {
        logger.info("register router!")
        registerScanBindRoute()

        Navigator.shared.registerRoute.type(LRVCWebContainerBody.self)
        .factory(LRVCWebContainerHandler.init)
    }

    /// 注册settings推送
    public static func registerSettingsObserve() {
        logger.info("register settings!")
        // 监听URLConfig
        _ = SettingManager.shared.observe(type: LarkRoomURLConfig.self, decodeStrategy: .convertFromSnakeCase) // Global
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { value in
                logger.info("receive url config: \(value)")
                handleURLSettings(value)
            })
    }

    private static func handleURLSettings(_ newSettings: LarkRoomURLConfig) {
        guard urlSettings != newSettings else {
            logger.info("url config not changed!")
            return
        }
        let domains = newSettings.domains.map({ "^(.*)\($0)" })
        let paths = newSettings.paths
        var allUrls: [String] = []
        // 将url和path排列组合注入路由
        domains.forEach({ url in
            paths.forEach({ path in
                let url = "\(url)\(path)"
                allUrls.append(url)
            })
        })
        allUrls.forEach { registerRouteIfNeeded(pattern: $0) }
        newSettings.noHeaderPathList.forEach({ path in
            if !hiddenNavigationBarPathList.contains(path) {
                hiddenNavigationBarPathList.append(path)
            }
        })
        logger.info("all support urls: \(allUrls), hidden navigation bar path list: \(hiddenNavigationBarPathList)")
    }

    private static func registerRouteIfNeeded(pattern: String) {
        guard !registerRoutePatternList.contains(pattern) else {
            return
        }
        Navigator.shared.registerRoute.regex(pattern)
        .factory(LarkRoomWebViewHandler.init)

        logger.info("register route pattern: \(pattern)")
        registerRoutePatternList.append(pattern)
    }

    public static func setupGetDeviceIdHandler(handler: @escaping () -> String) {
        getDeviceIdHandler = handler
    }

    // 设置所需handler
    public static func setupGetWatermarkInfoHandler(handler: @escaping (String) -> Observable<(String, String)>) {
        getWatermarkInfoHandler = handler
    }

    public static func setupShareImageToChatHandler(handler:  @escaping (String, UIViewController, [String]) -> Void) {
        shareImageToChatHandler = handler
    }

    public static func setupCopyMessageWithSecurity(handler: @escaping (String, Bool) -> Void) {
        copyMessageWithSecurity = handler
    }

}

// action
extension LarkRoomWebViewManager {

    // 打开RVC页面
    public static func createLarkRoomWebViewVC(url: URL, userId: String) -> LarkRoomWebViewVC {
        // 创建vc的时候不再获取paddingTop，改为在vc viewDidAppear时填写paddingTop，原因在于这里keyWindow可能是横屏的，获取的paddingTop不准
        let language = URLParams.languageValue
        let deviceId = URLParams.deviceIdValue
        let mode = URLParams.modeValue
        var adjuestURL = url.append(parameters: [URLParams.language.rawValue: language,
                                                 URLParams.deviceId.rawValue: deviceId,
                                                 URLParams.userId.rawValue: userId,
                                                 URLParams.mode.rawValue: mode
                                                ])
        if LarkRoomWebViewManager.env.isStaging {
            let featureEnv = URLParams.featureEnvValue
            let boeFd = URLParams.boeFdValue
            adjuestURL = adjuestURL.append(parameters: [URLParams.featureEnv.rawValue: featureEnv, URLParams.boeFd.rawValue: boeFd])
            logger.info("create lark room vc, add boe params for lark room vc, featureEnv = \(featureEnv), boeFd = \(boeFd)")
        }
        logger.info("create lark room vc, language = \(language), deviceId = \(deviceId), userId = \(userId)")
        let vc = LarkRoomWebViewVC(userID: userId, url: adjuestURL)
        vc.modalPresentationStyle = .fullScreen
        return vc
    }

    // 分享图片至会话
    static func sharePhotoToChat(userID: String, paths: [String], fromVC: UIViewController) {
        logger.info("shareToChat paths count: \(paths.count)")
        let topMostFrom = WindowTopMostFrom(vc: fromVC)
        if let handle = shareImageToChatHandler {
            handle(userID, fromVC, paths)
        }
    }

    // 分享会议至会话
    static func shareMeetingToChat(userID: String, meetingId: String, fromPlatform: String, fromVC: UIViewController) {
        let urlString = shareURL + "?meetingId=\(meetingId)&from=\(fromPlatform)"
        guard let url = URL(string: urlString) else {
            logger.error("create error url while sharing")
            return
        }
        logger.info("share to chat meetingId = \(meetingId)")
        let topMostFrom = WindowTopMostFrom(vc: fromVC)
        (try? Container.shared.getUserResolver(userID: userID).navigator)?.present(
            url,
            from: topMostFrom,
            prepare: {
                if Display.pad {
                    $0.modalPresentationStyle = .formSheet
                } else {
                    $0.modalPresentationStyle = .fullScreen
                }
            }, completion: { (request, res) in
                if let error = res.error {
                    showToast(content: BundleI18n.LarkRVC.Lark_RVC_UnableToShareToChat_Toast)
                    logger.error("share failed, error:\(error.localizedDescription)")
                }
            })
    }

    // 添加小窗
    static func addFloatingWindowModeIfNeeded(userID: String, fromVC: UIViewController, url: URL) {
        let icon: UIImage
        if #available(iOS 13.0, *) {
            icon = UDThemeManager.getRealUserInterfaceStyle() == .dark ? BundleResources.LarkRVC.rvc_icon_dark : BundleResources.LarkRVC.rvc_icon
        } else {
            icon = BundleResources.LarkRVC.rvc_icon
        }
        let adjustUrl = adjuestFloatWindowURL(originUrl: url)
        let tapHandler: () -> Void = {
            (try? Container.shared.getUserResolver(userID: userID).navigator)?
            .push(adjustUrl, from: WindowTopMostFrom(vc: fromVC))
        }
        SuspendManager.shared.addCustomButton(icon,
                                              size: CGSize(width: 24, height: 24),
                                              forKey: LarkRoomWebViewManager.floatingWindowKey,
                                              level: .middle + 1,
                                              tapHandler: tapHandler)
    }

    private static func adjuestFloatWindowURL(originUrl: URL) -> URL {
        guard !originUrl.absoluteString.contains("\(URLParams.from.rawValue)=") else {
            return originUrl
        }
        return originUrl.append(parameters: [URLParams.from.rawValue: URLParams.fromFloatValue])
    }

    static func closeRVCFloatWindow() {
        SuspendManager.shared.removeCustomView(forKey: LarkRoomWebViewManager.floatingWindowKey)
    }

    static func showToast(content: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard let window = self.getKeyWindow() else { return }
            RoundedHUD.showTips(with: content, on: window)
        }
    }

    public static func showImageSentToast() {
        showToast(content: BundleI18n.LarkRVC.Lark_RVC_ImageSent_Toast)
    }

    static func getKeyWindow() -> UIWindow? {
        var window: UIWindow?
        if #available(iOS 13.0, *) {
            window = UIApplication.shared.windowApplicationScenes
                .filter({ $0.activationState == .foregroundActive })
                .map({ $0 as? UIWindowScene })
                .compactMap({ $0 })
                .first?.windows
                .first(where: { $0.isKeyWindow })
        } else {
            window = UIApplication.shared.keyWindow
        }
        return window
    }
}

// 图片处理
extension LarkRoomWebViewManager {

    static func cacheFile(userInfo: [String: String], filename: String, fileToken: String, fileData: String, sandboxPath: IsoPath) -> String? {
        let userInfoHash = String(userInfo.hashValue)
        let savePath = getSavePath(userInfo: userInfoHash, fileToken: fileToken, fileName: filename, sandboxPath: sandboxPath)
        if savePath.fileExists(isDirectory: nil) {
            return savePath.asAbsPath().absoluteString
        } else {
            if let data = base64StringToData(fileData) {
                do {
                    try savePath.createFile(with: data)
                    return savePath.asAbsPath().absoluteString
                } catch let error {
                    logger.error("Save image to local failed, error: \(error), path: \(savePath)")
                    return nil
                }
            } else {
                logger.error("change form base64 to data failed \(savePath)")
                return nil
            }
        }
    }

    // 保存图片到相册
    static func saveImagesToPhotosAlbum(paths: [String], psdaToken: String) {
        currentSaveImagePSDAToken = psdaToken
        logger.info("saveImagesToPhotosAlbum paths count: \(paths.count)")
        needSavedPath = paths
        saveSingleImageToPhotosAlbum(psdaToken: psdaToken)
    }

    private static func saveSingleImageToPhotosAlbum(psdaToken: String) {
        if needSavedPath.count > 0 {
            if let path = needSavedPath.first, let image = getUIImageFromPath(path: path) {
                logger.info("start save SingleImage To PhotosAlbum")
                do {
                    let token = Token(withIdentifier: psdaToken)
                    try AlbumEntry.UIImageWriteToSavedPhotosAlbum(forToken: token, image, self, #selector(saveImageToPhotoAlbumHandler(image:didFinishSavingWithError:contextInfo:)), nil)
                } catch {
                    logger.error("save image failed, token checked failed")
                }
//                UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveImageToPhotoAlbumHandler(image:didFinishSavingWithError:contextInfo:)), nil)
            }
        }
    }

    // 从本地读取图片
    static func getUIImageFromPath(path: String) -> UIImage? {
        guard let imageData = NSData(contentsOf: URL(fileURLWithPath: path)) else {
            logger.info("get image from path failed")
            return nil
        }
        guard let rawImage = UIImage(data: imageData as Data) else { return nil }
        return rawImage
    }

    // 获取本地保存路径
    private static func getSavePath(userInfo: String, fileToken: String, fileName: String, sandboxPath: IsoPath) -> IsoPath {
        let path = sandboxPath.appendingRelativePath("whiteboard/\(userInfo)/\(fileToken)")
        do {
            try path.createDirectoryIfNeeded()
        } catch(let e) {
            logger.error("create directory failed \(e)")
        }
        return path.appendingRelativePath("\(fileName)")
    }

    // 解码base64数据
    private static func base64StringToData(_ base64String: String) -> Data? {
        var str = base64String
        if str.hasPrefix("data:image") {
            guard let newBase64String = str.components(separatedBy: ",").last else {
                return nil
            }
            str = newBase64String
        }
        guard let imgData = Data(base64Encoded: str, options: Data.Base64DecodingOptions()) else {
            return nil
        }
        return imgData
    }

    // 保存图片到相册回调
    @objc
    private static func saveImageToPhotoAlbumHandler(image: UIImage, didFinishSavingWithError: NSError?, contextInfo: AnyObject) {
        if didFinishSavingWithError != nil {
            logger.error("save image failed \(didFinishSavingWithError)")
            saveResult.accept(false)
        } else {
            logger.info("save image success")
        }
        needSavedPath.removeFirst()
        if needSavedPath.count > 0 {
            if let token = currentSaveImagePSDAToken {
                saveSingleImageToPhotosAlbum(psdaToken: token)
            } else {
                logger.error("did not find save image psda token")
                saveResult.accept(false)
            }
        } else {
            logger.info("save images all success")
            currentSaveImagePSDAToken = nil
            saveResult.accept(true)
        }
    }
}

// 扫码绑定
extension LarkRoomWebViewManager {

    // 注册扫码绑定vc
    private static func registerScanBindRoute() {
        Navigator.shared.registerRoute.regex(scanBindURLPattern)
                                       .priority(.high)
                                       .tester({ req in
            req.context["_canOpenInWeb"] = true
            req.context["_handledByDefaultURLRouter"] = true
            return true
        }).handle({ userResolver, req, res in
            // 拼接新的参数
            let url = createRoomsBindURL(url: req.url, userID: userResolver.userID)
            logger.info("capture url for room bind")
            // 重定向
            res.redirect(
                body: WebBody(url: url),
                context: req.context
            )
        })
        logger.info("register scan bind pattern: \(scanBindURLPattern)")
    }

    static func createRoomsBindURL(url: URL, userID: String) -> URL {
        return url.append(parameters: ["user_id": userID])
    }
}

class LarkRoomWebViewHandler: UserRouterHandler {

    func handle(req: EENavigator.Request, res: Response) throws {
        let vc = LarkRoomWebViewManager.createLarkRoomWebViewVC(url: req.url, userId: userResolver.userID)
        res.end(resource: vc)
    }
}

struct LarkRoomURLConfig: SettingDecodable, Equatable {
    static let settingKey = UserSettingKey.make(userKeyLiteral: "rooms_h5_url_config")
    let domains: [String]
    let noHeaderPathList: [String]
    let paths: [String]
}
