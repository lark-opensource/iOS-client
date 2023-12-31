//
//  DynamicRenderingTemplateExporter.swift
//  LarkContact
//
//  Created by shizhengyu on 2020/9/14.
//

import UIKit
import Foundation
import LarkSDKInterface
import LKCommonsLogging
import SnapKit
import LarkContainer
import RustPB
import RxSwift
import CoreGraphics
import Kingfisher
import LarkRustClient
import LarkFoundation
import LarkUIKit
import KingfisherWebP

// swiftlint:disable init_color_with_token
extension Contact_V1_ImageOptions {
    public static func `default`() -> Contact_V1_ImageOptions {
        var options = Contact_V1_ImageOptions()
        options.resolutionType = .highDefinition
        return options
    }
}

public enum DynamicResourceExportError: Error {
    case unknownError(logMsg: String)  // 未知或极端错误(比如self被异常释放等)
    case pullDynamicResourceFailed(logMsg: String, userMsg: String)  // 请求动态资源错误
    case downloadFailed(logMsg: String)    // 下载 cdn 图片错误
    case bytesParseFailed(logMsg: String)  // 图片字节流解析错误
    case constraintsError(logMsg: String)  // 业务方参数有误或server下发数据不符合预期等
    case graphContextError(logMsg: String) // 图层叠加过程发生错误(比如找不到graph上下文等)

    public static func transform(error: Error) -> DynamicResourceExportError {
        guard let wrappedError = error as? WrappedError,
            let rcError = wrappedError.metaErrorStack.first(where: { $0 is RCError }) as? RCError else {
            return .unknownError(logMsg: "no suitable error captured from metaErrorStack")
        }
        switch rcError {
        case .businessFailure(let buzErrorInfo):
            return .pullDynamicResourceFailed(
                logMsg: buzErrorInfo.serverMessage,
                userMsg: buzErrorInfo.displayMessage
            )
        default:
            break
        }
        return .unknownError(logMsg: "no suitable error captured from request")
    }

    public static func extremeError() -> DynamicResourceExportError {
        return .unknownError(logMsg: "extremeError occurred abnormally")
    }
}

public struct TemplateConfiguration {
    public let bizScenario: RustPB.Contact_V1_BizScenario
    public let imageOptions: RustPB.Contact_V1_ImageOptions
    public let extraRequestParams: RustPB.Contact_V1_GetDynamicMediaRequest.OneOf_BusinessOptions?
    public var textContentReplacer: [String: String]?
    public init(
        bizScenario: RustPB.Contact_V1_BizScenario,
        imageOptions: RustPB.Contact_V1_ImageOptions = Contact_V1_ImageOptions.default(),
        extraRequestParams: RustPB.Contact_V1_GetDynamicMediaRequest.OneOf_BusinessOptions? = nil,
        textContentReplacer: [String: String]? = nil
    ) {
        self.bizScenario = bizScenario
        self.imageOptions = imageOptions
        self.extraRequestParams = extraRequestParams
        self.textContentReplacer = textContentReplacer
    }
}

public typealias OverlayViewType = Contact_V1_ConstantKeyImageData.ConstantKeyImageType

public final class DynamicRenderingTemplateExporter: UserResolverWrapper {
    private typealias E = DynamicResourceExportError

    public var userResolver: LarkContainer.UserResolver
    @ScopedInjectedLazy private var dynamicResourceAPI: DynamicResourceAPI?
    private var templateConfiguration: TemplateConfiguration
    private var templateCache: UIImage?
    private var needCache: Bool
    private var extraOverlayViews: [OverlayViewType: UIView]
    private let monitor = InviteMonitor()
    private let disposeBag = DisposeBag()
    private static let logger = Logger.log(
        DynamicRenderingTemplateExporter.self,
        category: "ug.dynamicResource"
    )
    private lazy var urlDownloader: ImageDownloader = {
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        let downloader = ImageDownloader(name: "DynamicRenderingTemplateExporter.urlDownloader")
        downloader.sessionConfiguration = sessionConfiguration
        downloader.downloadTimeout = 5.0
        return downloader
    }()
    private lazy var webpProcessor: ImageProcessor = {
        return WebPProcessor(identifier: "DynamicRenderingTemplateExporter.webpProcessor")
    }()
    private var cdnDownloadOptionInfo: KingfisherOptionsInfo {
        return [
            .onlyLoadFirstFrame,
            .cacheMemoryOnly,
            .fromMemoryCacheOrRefresh,
            .processor(webpProcessor),
            .cacheSerializer(WebPSerializer.default)
        ]
    }

    public init(
        templateConfiguration: TemplateConfiguration,
        needCache: Bool = true,
        extraOverlayViews: [OverlayViewType: UIView] = [:],
        resolver: UserResolver
    ) {
        self.templateConfiguration = templateConfiguration
        self.needCache = needCache
        self.extraOverlayViews = extraOverlayViews
        self.userResolver = resolver
    }

    public func export() -> Observable<UIImage> {
        if needCache, let cacheInMemory = templateCache {
            return .just(cacheInMemory)
        }
        guard let dynamicResourceAPI = self.dynamicResourceAPI else { return .error(DynamicResourceExportError.unknownError(logMsg: "fetchDynamicResource is empty")) }
        let startTimeInterval = CACurrentMediaTime()
        monitor.startEvent(
            name: "ug_fetch_dy_resource",
            indentify: String(startTimeInterval)
        )
        return dynamicResourceAPI.fetchDynamicResource(
            businessScenario: templateConfiguration.bizScenario,
            imageOptions: templateConfiguration.imageOptions,
            extraRequestParams: templateConfiguration.extraRequestParams
        )
        .observeOn(MainScheduler.instance)
        .do(onNext: { [weak self] (_) in
            self?.monitor.endEvent(
                name: "ug_fetch_dy_resource",
                indentify: String(startTimeInterval),
                category: ["succeed": "true",
                           "biz_scene": self?.templateConfiguration.bizScenario.toString() ?? "unknown"]
            )
        }, onError: { [weak self] (error) in
            guard let wrappedError = error as? WrappedError,
                let rcError = wrappedError.metaErrorStack.first(where: { $0 is RCError }) as? RCError else {
                return
            }
            switch rcError {
            case .businessFailure(let buzErrorInfo):
                self?.monitor.endEvent(
                    name: "ug_fetch_dy_resource",
                    indentify: String(startTimeInterval),
                    category: ["succeed": "false",
                               "error_code": buzErrorInfo.code,
                               "biz_scene": self?.templateConfiguration.bizScenario.toString() ?? "unknown"],
                    extra: ["error_msg": buzErrorInfo.serverMessage]
                )
            default: break
            }
        })
        .flatMap({ [weak self] (response) -> Observable<UIImage> in
            guard let `self` = self else {
                return .error(E.extremeError())
            }
            return self.export(by: response.imageConfigurations)
        })
    }

    public func export(by configurations: [Contact_V1_ImageConfiguration]) -> Observable<UIImage> {
        let renderTimeInterval = CACurrentMediaTime()
        monitor.startEvent(
            name: "ug_dy_resource_generate_img",
            indentify: String(renderTimeInterval)
        )
        return genLayers(from: configurations)
            .flatMap({ [weak self] (imageLayers) -> Observable<UIImage> in
                guard let `self` = self else {
                    return .error(E.extremeError())
                }
                return self.overlay(by: imageLayers)
            })
            .do(onNext: { [weak self] image in
                self?.templateCache = image
                self?.monitor.endEvent(
                    name: "ug_dy_resource_generate_img",
                    indentify: String(renderTimeInterval),
                    category: ["succeed": "true",
                               "biz_scene": self?.templateConfiguration.bizScenario.toString() ?? "unknown"]
                )
            }, onError: { [weak self] (error) in
                guard let wrappedError = error as? WrappedError,
                      let rcError = wrappedError.metaErrorStack.first(where: { $0 is RCError }) as? RCError else {
                    return
                }
                switch rcError {
                case .businessFailure(let buzErrorInfo):
                    self?.monitor.endEvent(
                        name: "ug_dy_resource_generate_img",
                        indentify: String(renderTimeInterval),
                        category: ["succeed": "false",
                                   "error_code": buzErrorInfo.code,
                                   "biz_scene": self?.templateConfiguration.bizScenario.toString() ?? "unknown"],
                        extra: ["error_msg": buzErrorInfo.serverMessage]
                    )
                default: break
                }
            })
    }

    public func updateTemplateConfiguration(_ new: TemplateConfiguration) {
        self.templateConfiguration = new
        templateCache = nil
    }

    public func updateNeedCache(_ new: Bool) {
        guard needCache != new else { return }
        if !new {
            templateCache = nil
        }
        needCache = new
    }

    public func updateExtraOverlayViews(_ new: [OverlayViewType: UIView]) {
        extraOverlayViews = new
    }

    public func clearCache() {
        guard needCache else { return }
        templateCache = nil
    }
}

private extension DynamicRenderingTemplateExporter {
    func genLayers(from configurations: [Contact_V1_ImageConfiguration]) -> Observable<[(UIImage, Contact_V1_ImageConfigurationProperty)]> {
        if configurations.isEmpty {
            DynamicRenderingTemplateExporter.logger.error("configurations is empty")
            return .error(E.constraintsError(logMsg: "configurations is empty"))
        }

        var overlayConfs = configurations

        // 如果画布位于非头部位置，会校准画布的位置
        if !(configurations.first?.isBackground ?? false) {
            let index = overlayConfs.firstIndex { (configuration) -> Bool in
                configuration.isBackground
            }
            if let index = index {
                let canvasConf = overlayConfs[index]
                overlayConfs.remove(at: index)
                overlayConfs.insert(canvasConf, at: 0)
            } else {
                DynamicRenderingTemplateExporter.logger.error("canvas configuration not found")
                return .error(E.constraintsError(logMsg: "canvas configuration not found"))
            }
        }

        let needDownloadResourceConfs = overlayConfs.filter { (conf) -> Bool in
            return .decryptedRawCdnURL == conf.data.type
        }.compactMap { (conf) -> (Int, Contact_V1_ImageConfiguration)? in
            if let index = configurations.firstIndex(of: conf) {
                return (index, conf)
            }
            return nil
        }

        let constantResourceConfs = overlayConfs.filter { (conf) -> Bool in
            return .constantKey == conf.data.type
        }

        let rawBytesResourceConfs = overlayConfs.filter { (conf) -> Bool in
            return .decryptedRawBytes == conf.data.type
        }

        let rawTextResourceConfs = overlayConfs.filter { (conf) -> Bool in
            return .rawText == conf.data.type || .rawHtml == conf.data.type
        }

        // 如果存在约定资源，须检查业务方提供的overlayView的完整性
        for conf in constantResourceConfs {
            if !extraOverlayViews.contains(where: { $0.key == conf.data.constantKeyImage.type }) {
                let rawValue = conf.data.constantKeyImage.type.rawValue
                DynamicRenderingTemplateExporter.logger.error("constant overlay view did not found, type = \(rawValue)")
                return .error(E.constraintsError(logMsg: "constant overlay view did not found, type = \(rawValue)"))
            }
        }

        let constantResourceLayers = constantResourceConfs.compactMap { [weak self] (conf) -> (Int, UIImage)? in
            if let index = configurations.firstIndex(of: conf) {
                guard let `self` = self else {
                    return nil
                }
                let constantKey = conf.data.constantKeyImage.type
                if self.extraOverlayViews.contains(where: { (type2view) -> Bool in
                    constantKey.rawValue == type2view.key.rawValue
                }) {
                    let width = CGFloat(conf.property.resizeWidth)
                    let height = CGFloat(conf.property.resizeHeight)

                    if let constantView = self.extraOverlayViews[constantKey] {
                        constantView.prepare(with: conf.property)

                        if let snapshot = UIImage.snapshot(from: constantView, size: CGSize(width: width, height: height)) {
                            return (index, snapshot)
                        }
                    }
                }
            }
            return nil
        }

        let rawTextResourceLayers = rawTextResourceConfs.compactMap { [weak self] (conf) -> (Int, UIImage)? in
            if let index = configurations.firstIndex(of: conf) {
                guard let `self` = self else {
                    return nil
                }
                if let textSnapshot = self.genTextLayer(by: conf) {
                    return (index, textSnapshot)
                }
            }
            return nil
        }

        let rawBytesResourceLayers = rawBytesResourceConfs.compactMap { (conf) -> (Int, UIImage)? in
            if let index = configurations.firstIndex(of: conf),
                let image = UIImage(data: conf.data.rawImage.rawData) {
                return (index, image)
            }
            return nil
        }

        let downloadObservables: [Observable<(Int, UIImage)>] = needDownloadResourceConfs.compactMap { (indexAndConf) -> Observable<(Int, UIImage)>? in
            let (index, conf) = indexAndConf
            if let cdnUrl = URL(string: conf.data.cdnImage.url) {
                return Observable<(Int, Image)>.create { [weak self] (observer) -> Disposable in
                    self?.urlDownloader.downloadImage(
                        with: cdnUrl,
                        options: self?.cdnDownloadOptionInfo,
                        progressBlock: nil) { (result) in
                            switch result {
                            case .success(let loadingResult):
                                observer.onNext((index, loadingResult.image.clipped(conf: conf)))
                                observer.onCompleted()
                            case .failure(let error):
                                DynamicRenderingTemplateExporter.logger.error("errCode = \(error.errorCode), errMsg = \(error.errorDescription ?? "")")
                                observer.onError(
                                    E.downloadFailed(
                                        logMsg: "errCode = \(error.errorCode), errMsg = \(error.errorDescription ?? "")"
                                    )
                                )
                            @unknown default: break
                            }
                    }
                    return Disposables.create()
                }
            } else {
                DynamicRenderingTemplateExporter.logger.error("cdn url is not a valid url")
                return nil
            }
        }

        return Observable.zip(downloadObservables)
            .observeOn(MainScheduler.instance)
            .flatMap { (cdnImageInfos) -> Observable<[(UIImage, Contact_V1_ImageConfigurationProperty)]> in
                return .just(
                    [cdnImageInfos, constantResourceLayers, rawBytesResourceLayers, rawTextResourceLayers]
                    .reduce([], +)
                    .sorted(by: { $0.0 < $1.0 })
                    .map({ ($0.1, configurations[$0.0].property) })
                )
            }
    }

    func overlay(by overlayContexts: [(UIImage, Contact_V1_ImageConfigurationProperty)]) -> Observable<UIImage> {
        if overlayContexts.isEmpty {
            return .error(E.constraintsError(logMsg: "overlayContexts is empty"))
        }

        let canvasImage = overlayContexts[0].0
        let canvasDrawContext = overlayContexts[0].1
        let canvasWidth = CGFloat(canvasDrawContext.resizeWidth)
        let canvasHeight = CGFloat(canvasDrawContext.resizeHeight)
        let canvasAlpha = canvasDrawContext.hasAlpha ? CGFloat(canvasDrawContext.alpha) : 1.0
        UIGraphicsBeginImageContextWithOptions(
            CGSize(width: canvasWidth, height: canvasHeight),
            false,
            UIScreen.main.scale
        )
        canvasImage.draw(in: CGRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight),
                         blendMode: .normal,
                         alpha: canvasAlpha)
        if let canvas = UIGraphicsGetImageFromCurrentImageContext() {
            UIGraphicsEndImageContext()
            if overlayContexts.count > 1 {
                return Observable.create { (observer) -> Disposable in
                    let output = Array(overlayContexts[1...]).reduce(canvasImage) { (output, overlayContext) -> UIImage? in
                        if let output = output {
                            return output.overlay(by: overlayContext.0, with: overlayContext.1)
                        } else {
                            return nil
                        }
                    }
                    if let outputOverlay = output {
                        observer.onNext(outputOverlay)
                        observer.onCompleted()
                    } else {
                        DynamicRenderingTemplateExporter.logger.error("UIGraphicsGetImageFromCurrentImageContext is nil")
                        observer.onError(E.graphContextError(logMsg: "UIGraphicsGetImageFromCurrentImageContext is nil"))
                    }
                    return Disposables.create()
                }
            } else {
                return .just(canvas)
            }
        }

        DynamicRenderingTemplateExporter.logger.error("UIGraphicsGetImageFromCurrentImageContext is nil")
        return .error(E.graphContextError(logMsg: "UIGraphicsGetImageFromCurrentImageContext is nil"))
    }

    func genTextLayer(by configuration: Contact_V1_ImageConfiguration) -> UIImage? {
        let fromHtml = configuration.data.type == .rawHtml
        let property = configuration.property
        let rawContentData = fromHtml ? configuration.data.rawHtml : configuration.data.text
        let width = CGFloat(property.resizeWidth)
        let height = CGFloat(property.resizeHeight)
        var textValue = rawContentData.value
        if let replacer = templateConfiguration.textContentReplacer, !replacer.isEmpty {
            for (origin, new) in replacer {
                textValue = textValue.replacingOccurrences(of: origin, with: new)
            }
        }
        let fontSize = CGFloat(rawContentData.fontSize)
        let rgbaStr = rawContentData.color
        let align = rawContentData.align
        let overflowType = rawContentData.overflow
        let minFontSize = rawContentData.minFontSize
        let fontWeight: UIFont.Weight = (rawContentData.textStyle == .bold ? .medium : .regular)
        var font = UIFont.systemFont(ofSize: fontSize, weight: fontWeight)
        if rawContentData.hasFontFamily {
            // swiftlint:disable init_font_with_name
            font = UIFont(name: rawContentData.fontFamily, size: fontSize) ?? UIFont.systemFont(ofSize: fontSize, weight: fontWeight)
            // swiftlint:enable init_font_with_name
        }

        let foregroundColor = UIColor.by(rgbaStr: rgbaStr)
        var alignment = NSTextAlignment.center
        switch align {
        case .alignCenter:
            alignment = .center
        case .alignLeft:
            alignment = .left
        case .alignRight:
            alignment = .right
        @unknown default: break
        }
        let lineSpacing: CGFloat? = (rawContentData.hasLineSpace && .multi == overflowType) ? CGFloat(rawContentData.lineSpace) : nil
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        if let lineSpacing = lineSpacing {
            paragraphStyle.lineSpacing = lineSpacing
        }

        var attributedString: NSAttributedString?
        if fromHtml {
            attributedString = textValue.html2AttributeStringUnsafe(font: font, forgroundColor: foregroundColor, paragraphStyle: paragraphStyle)
        } else {
            let attributes: [NSAttributedString.Key: Any] =
                [.font: font,
                 .foregroundColor: foregroundColor,
                 .paragraphStyle: paragraphStyle]
            let temp = NSMutableAttributedString(string: textValue)
            temp.addAttributes(attributes, range: NSRange(location: 0, length: textValue.count))
            attributedString = temp
        }

        guard let attrStr = attributedString else {
            return nil
        }

        var visualLabel: InsetsLabel?
        switch overflowType {
        case .multi:
            UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, UIScreen.main.scale)
            attrStr.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return image
        case .singleAdaptive:
            visualLabel = InsetsLabel(frame: CGRect(x: 0, y: 0, width: width, height: height), insets: .zero)
            visualLabel?.minimumScaleFactor = CGFloat(minFontSize) / fontSize
            visualLabel?.adjustsFontSizeToFitWidth = true
        case .singleFixed:
            visualLabel = InsetsLabel(frame: CGRect(x: 0, y: 0, width: width, height: height), insets: .zero)
        @unknown default: break
        }
        if let label = visualLabel {
            label.numberOfLines = 1
            label.lineBreakMode = .byTruncatingTail
            label.textAlignment = alignment
            label.font = font
            label.backgroundColor = .clear
            label.textColor = UIColor.by(rgbaStr: rgbaStr)
            if fromHtml {
                label.setHtml(textValue, forceLineSpacing: lineSpacing)
            } else {
                label.text = textValue
            }
            return UIImage.snapshot(from: label, size: CGSize(width: width, height: height))
        }
        return nil
    }
}

private extension UIImage {
    func overlay(by sublayer: UIImage, with drawContext: Contact_V1_ImageConfigurationProperty) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.size, false, UIScreen.main.scale)
        let sublayerAlpha = drawContext.hasAlpha ? CGFloat(drawContext.alpha) : 1.0
        draw(in: CGRect(x: 0,
                        y: 0,
                        width: size.width,
                        height: size.height),
             blendMode: .normal,
             alpha: 1.0)
        sublayer.draw(in: CGRect(x: CGFloat(drawContext.offsetX),
                                 y: CGFloat(drawContext.offsetY),
                                 width: CGFloat(drawContext.resizeWidth),
                                 height: CGFloat(drawContext.resizeHeight)),
                      blendMode: .normal,
                      alpha: sublayerAlpha)
        if let image = UIGraphicsGetImageFromCurrentImageContext() {
            UIGraphicsEndImageContext()
            return image
        }
        UIGraphicsEndImageContext()
        return nil
    }

    static func snapshot(from view: UIView, size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        if let ctx = UIGraphicsGetCurrentContext() {
            view.layer.render(in: ctx)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return image
        }
        UIGraphicsEndImageContext()
        return nil
    }

    func clipped(conf: Contact_V1_ImageConfiguration) -> UIImage {
        let maxRadius = min(size.width, size.height) / 2
        let suitableRadius = min(maxRadius, CGFloat(conf.property.borderRadius.bottomLeft))
        if suitableRadius.isZero { return self }

        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        let rect = CGRect(origin: .zero, size: size)
        UIBezierPath(roundedRect: rect, cornerRadius: suitableRadius).addClip()
        draw(in: rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image ?? self
    }
}

private extension UIView {
    func prepare(with configurationProperty: Contact_V1_ImageConfigurationProperty) {
        let width = CGFloat(configurationProperty.resizeWidth)
        let height = CGFloat(configurationProperty.resizeHeight)
        let topLeftRadius = configurationProperty.borderRadius.topLeft
        let topRightRadius = configurationProperty.borderRadius.topRight
        let bottomLeftRadius = configurationProperty.borderRadius.bottomLeft
        let bottomRightRadius = configurationProperty.borderRadius.bottomRight

        // 使外部约定view强制约束失效，避免frame不生效
        removeAllConstraints()
        frame = CGRect(x: 0, y: 0, width: width, height: height)
        // 设置圆角
        lu.addCorner(corners: [.layerMinXMaxYCorner], cornerSize: CGSize(width: topLeftRadius, height: topLeftRadius))
        lu.addCorner(corners: [.layerMaxXMaxYCorner], cornerSize: CGSize(width: topRightRadius, height: topRightRadius))
        lu.addCorner(corners: [.layerMinXMinYCorner], cornerSize: CGSize(width: bottomLeftRadius, height: bottomLeftRadius))
        lu.addCorner(corners: [.layerMaxXMinYCorner], cornerSize: CGSize(width: bottomRightRadius, height: bottomRightRadius))
    }

    func removeAllConstraints() {
        var _superview = superview
        while let superview = _superview {
            for constraint in superview.constraints {
                if let first = constraint.firstItem as? UIView, first == self {
                    superview.removeConstraint(constraint)
                }
                if let second = constraint.secondItem as? UIView, second == self {
                    superview.removeConstraint(constraint)
                }
            }
            _superview = superview.superview
        }
        removeConstraints(constraints)
        translatesAutoresizingMaskIntoConstraints = true
    }
}

private extension UIColor {
    convenience init(hex: UInt) {
        self.init(
            red: CGFloat((hex & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((hex & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(hex & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }

    static func by(rgbaStr: String) -> UIColor {
        let hexStr = rgbaStr.replacingOccurrences(of: "#", with: "0x", options: .regularExpression)
        if let hexValue = UInt(String(hexStr.suffix(6)), radix: 16) {
            return UIColor(hex: hexValue)
        }
        return UIColor.ud.N900
    }
}

private extension RustPB.Contact_V1_BizScenario {
    func toString() -> String {
        switch self {
        case .contactCard: return "contactCard"
        case .teamCard: return "teamCard"
        case .eduCard: return "eduCard"
        case .teamQrcardLight: return "teamQrCoardLight"
        case .teamQrcardDark: return "teamQrcardDark"
        @unknown default: return "unknown"
        }
    }
}
// swiftlint:enable init_color_with_token
