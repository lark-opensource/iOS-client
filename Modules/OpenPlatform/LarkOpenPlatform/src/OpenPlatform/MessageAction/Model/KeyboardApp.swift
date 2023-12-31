//
//  MessageActionDataProvider.swift
//  LarkOpenPlatform
//
//  Created by lilun.ios on 2020/9/24.
//

import LKCommonsLogging
import Swinject
import RxSwift
import RustPB
import LarkRustClient
import SwiftyJSON
import LarkExtensions
import LKCommonsTracker
import LarkAccountInterface
import LarkLocalizations
import LarkModel
import EENavigator
import LarkAppLinkSDK
import LarkCache
import ByteWebImage
import LarkOPInterface
import LarkMessageBase
import LarkFoundation
import UniverseDesignColor

private let logger = Logger.oplog(KeyBoardAppImageManager.self,
                                  category: MessageActionPlusMenuDefines.messageActionLogCategory)
extension UIImage {
    func removeAlpha() -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = true // removes Alpha Channel
        format.scale = scale // keeps original image scale
        return UIGraphicsImageRenderer(size: size, format: format).image { renderContext in
            UIColor.white.setFill()
            renderContext.fill(CGRect(origin: .zero, size: size))
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

class KeyBoardAppImageManager {
    private var cache: NSCache<NSString, UIImage> = NSCache()
    private static let _shared: KeyBoardAppImageManager = {
        let shareInstance = KeyBoardAppImageManager()
        return shareInstance
    }()
    public class func shared() -> KeyBoardAppImageManager {
         return _shared
    }
    public func getImageFromCache(key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }
    public func setImage(key: String, image: UIImage) {
        cache.setObject(image, forKey: key as NSString)
    }
    /// 异步加载图片
    public func loadImage(key: String,
                          fsUnit: String?,
                          appInfo: String,
                          completion: @escaping ((UIImage?) -> Void)) {
        let tempImageView = UIImageView()
        /// 需要头像的尺寸是 40.0 * 40.0, 如果图片的尺寸是小于44.0那么显示将会出现异常
        let iconNormalSize: CGFloat = 40.0
        tempImageView.bt.setLarkImage(with: .avatar(key: key, entityID: "0", params: .init(sizeType: .size(iconNormalSize))),
                                      completion: { [weak tempImageView] result in
                                        tempImageView?.backgroundColor = UIColor.ud.N300
                                        switch result {
                                        case .success(let imageResult):
                                            if let downloadImage = imageResult.image {
                                                let resultImage = UIImage.dynamic(light: downloadImage,
                                                                                  dark: downloadImage)
                                                KeyBoardAppImageManager.shared().setImage(key: key,
                                                                                          image: resultImage)
                                                DispatchQueue.main.async {
                                                    completion(resultImage)
                                                }
                                            }
                                        case .failure:
                                            logger.error("App \(appInfo) image \(key) load fail")
                                        }
                                      })
    }
}

final class KeyboardApp: Equatable {
    var appModel: MoreAppItemModel
    var iconImg: UIImage?
    var dataUpdateBlock: (() -> Void)
    init(appModel: MoreAppItemModel, dataUpdateBlock: @escaping (() -> Void)) {
        self.appModel = appModel
        self.dataUpdateBlock = dataUpdateBlock
        self.iconImg = KeyBoardAppImageManager.shared().getImageFromCache(key: appModel.icon.key)
        reloadImage()
    }

    /// 重新reload 头像
    func reloadImage() {
        KeyBoardAppImageManager.shared().loadImage(key: appModel.icon.key,
                                                   fsUnit: appModel.icon.fsUnit,
                                                   appInfo: "\(appModel.appId)_\(appModel.name ?? "")") { [weak self] (image) in
            guard let self = self else {
                return
            }
            let imageFirstComplete = self.iconImg == nil && image != nil
            self.iconImg = image
            if imageFirstComplete {
                self.dataUpdateBlock()
            }
        }
    }
    func isAppCanDisplay() -> Bool {
        return iconImg != nil && sourceTargetUrl() != nil
    }

    public func sourceTargetUrl() -> String? {
        return appModel.mobileApplinkUrl
    }

    func toDynamicItem(tap: @escaping () -> Void ) -> KeyBoardItem {
        let icon = iconImg ?? UIImage()
        let item = KeyBoardItem(app: nil,
                                customViewBlock: nil,
                                icon: icon,
                                selectIcon: nil,
                                tapped: tap,
                                text: appModel.name ?? "",
                                priority: 1000,
                                badge: nil)
        return item
    }
    public static func == (lhs: KeyboardApp, rhs: KeyboardApp) -> Bool {
        return lhs.appModel.appId == rhs.appModel.appId && lhs.appModel.id == rhs.appModel.id
    }
}
