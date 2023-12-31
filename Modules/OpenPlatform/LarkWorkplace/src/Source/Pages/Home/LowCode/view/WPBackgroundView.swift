//
//  WPBackgroundView.swift
//  LarkWorkplace
//
//  Created by 窦坚 on 2022/5/13.
//

import UIKit
import LarkUIKit
import RxSwift
import RxRelay
import ByteWebImage
import LKCommonsLogging
import UniverseDesignTheme
import ECOProbe
import ECOProbeMeta
import LarkSetting

/// 工作台背景
final class WPBackgroundView: UIImageView {

    private static let logger = Logger.log(WPBackgroundView.self)

    private var enableBackgroundImage: Bool { !Display.pad }

    private var udImage: UDImage?
    private let disposeBag = DisposeBag()

    init() {
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        refreshImage()
    }

    private func setupView() {
        backgroundColor = .ud.bgBody
        // 裁剪超出view的图像部分
        clipsToBounds = true
        contentMode = .scaleAspectFill
    }

    /// 更新背景图 - 数据变更
    /// - Parameter backgroundProps: 背景图model
    func refreshWhenDataChange(with backgroundProps: BackgroundPropsModel) {
        Self.logger.info("refresh views when data changed", additionalData: [
            "lightImageKey": "\(backgroundProps.background.light?.key ?? "")",
            "darkImageKey": "\(backgroundProps.background.dark?.key ?? "")",
            "enableBackgroundImage": "\(enableBackgroundImage)"
        ])
        guard enableBackgroundImage else { return }

        let lightObservableImage = observeImageEvent(imageProps: backgroundProps.background.light)
        let darkObservableImage = observeImageEvent(imageProps: backgroundProps.background.dark)
        Observable
            .zip(lightObservableImage, darkObservableImage)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self](lightImage, darkImage) in
                self?.setupUDImage(lightImage: lightImage, darkImage: darkImage)
                self?.refreshImage()
            })
            .disposed(by: disposeBag)
    }

    private func setupUDImage(lightImage: UIImage?, darkImage: UIImage?) {
        Self.logger.info("handle setup image", additionalData: [
            "hasLightImage": "\(lightImage != nil)",
            "hasDarkImage": "\(darkImage != nil)"
        ])
        self.udImage = UDImage { trait -> UIImage in
            if #available(iOS 12.0, *) {
                switch trait.userInterfaceStyle {
                case .dark:
                    return darkImage ?? UIImage()
                case .light, .unspecified:
                    return lightImage ?? UIImage()
                @unknown default:
                    return lightImage ?? UIImage()
                }
            } else {
                return lightImage ?? UIImage()
            }
        }
    }

    private func refreshImage() {
        let resolveImage = udImage?.dynamicProvider(traitCollection)
        let interfaceStyleDebugRaw: String
        if #available(iOS 12.0, *) {
            switch traitCollection.userInterfaceStyle {
            case .dark:
                interfaceStyleDebugRaw = "dark"
            case .light:
                interfaceStyleDebugRaw = "light"
            case .unspecified:
                interfaceStyleDebugRaw = "unspecified"
            @unknown default:
                interfaceStyleDebugRaw = "unknown"
            }
        } else {
            interfaceStyleDebugRaw = "unknown(iOS 11)"
        }
        Self.logger.error("refresh image", additionalData: [
            "hasImage": "\(resolveImage != nil)",
            "viewSize": "\(frame.size)",
            "imageSize": "\(resolveImage?.size ?? .zero)",
            "interfaceStyle": interfaceStyleDebugRaw
        ])
        guard let image = resolveImage,
              frame.size.width > 0,
              frame.size.height > 0,
              image.size.width > 0,
              image.size.height > 0 else {
            self.image = nil
            return
        }

        // 图片横纵比
        let imageAspectRatio: Double = image.size.width / image.size.height
        // 背景View横纵比
        let viewAspectRatio: Double = frame.size.width / frame.size.height
        if imageAspectRatio < 1 && imageAspectRatio < viewAspectRatio {// 图片相比视图，是长图
            // 计算缩放比例：Image宽度对齐UIImageView宽度
            let resizeRate = frame.size.width / image.size.width
            let image = UIImage.resizeImage(image: image, targetSize: CGSize(
                width: resizeRate * image.size.width,
                height: resizeRate * image.size.height
            ))
            // 长图从顶部开始铺开
            contentMode = .top
            self.image = image
        } else {// 图片为宽图
            // 宽图居中显示，长度适配view长度
            contentMode = .scaleAspectFill
            self.image = image
        }
    }

    private func observeImageEvent(
        imageProps: BackgroundPropsModel.Background.ImageModel?
    ) -> Observable<UIImage?> {
        // swiftlint:disable closure_body_length
        return Observable<UIImage?>.create { [weak self] (observer) -> Disposable in
            Self.logger.info("prepare fetch image", additionalData: [
                "hasSelf": "\(self != nil)",
                "imageURL": imageProps?.url ?? "",
                "imageKey": imageProps?.key ?? ""
            ])
            guard let `self` = self, let imageURL = imageProps?.url, let imageKey = imageProps?.key else {
                observer.onNext(nil)
                observer.onCompleted()
                return Disposables.create()
            }

            let resource: LarkImageResource = .default(key: imageURL)
            let monitor = OPMonitor(
                name: "op_workplace_event",
                code: EPMClientOpenPlatformAppCenterBackgroundCode.workplace_background_fetch_result
            )
            monitor.timing()
                .addCategoryValue("isCached", LarkImageService.shared.isCached(resource: resource))
                .addCategoryValue("key", imageKey)
                .addCategoryValue("url", imageURL)
                .addCategoryValue("fsUnit", imageProps?.fsUnit)

            // 获取图片：内存 -> 磁盘 -> 网络 ，从网络获取到后自动设置缓存
            // 适配主端图片降采样逻辑，传入 view 的 size，把降采样阈值提升到 view 大小，从而直接使用原图，保证背景图清晰度。
            // 因为 LarkImageService 内部使用尺寸单位为 px，这里需要做一个 dp * scale = px 的转换。
            let options: ImageRequestOptions = [.downsampleSize(CGSize(
                width: ceil(self.bounds.size.width * UIScreen.main.scale),
                height: ceil(self.bounds.size.height * UIScreen.main.scale)
            ))]
            LarkImageService.shared.setImage(with: resource, options: options, completion: { result in
                switch result {
                case .success(let imageResult):
                    if let image = imageResult.image {
                        Self.logger.info("fetch background image success", additionalData: ["key": imageKey])
                        monitor.setResultTypeSuccess()
                        observer.onNext(image)
                    } else {
                        Self.logger.error("fetch background image failed, result is nil", additionalData: [
                            "key": imageKey
                        ])
                        monitor.setResultTypeFail()
                        observer.onNext(nil)
                    }
                case .failure(let error):
                    Self.logger.error("fetch background image failed", additionalData: [
                        "key": imageKey
                    ], error: error)
                    monitor.setResultTypeFail()
                    observer.onNext(nil)
                }
                monitor.timing().flush()
                observer.onCompleted()
            })
            return Disposables.create()
        }
        // swiftlint:enable closure_body_length
    }
}

extension UIImage {
    fileprivate static func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size

        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height

        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }

        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(origin: .zero, size: newSize)

        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
}
