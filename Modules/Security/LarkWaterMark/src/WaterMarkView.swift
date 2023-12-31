//
//  WaterMarkView.swift
//  Lark
// 文档：https://bytedance.feishu.cn/docs/doccnc6ehRQNDPTVZHV3DXIjGgh#

import Foundation
import UIKit
import LKCommonsLogging
import ByteWebImage
import UniverseDesignTheme

/// obvious watermark config
struct ObviousWaterMarkConfig {
    let text: String
    let textColor: UIColor
}

/// obvious watermark pattern config
public struct ObviousWaterMarkPatternConfig: Codable, Equatable {
    var opacity: Float = 0.12
    var darkOpacity: Float = 0.08
    var fontSize: Float = 14.0
    var rotateAngle: Float = -15.0
    var density: ObviousWaterMarkDensity = .dense
}

enum ObviousWaterMarkDensity: Int, Codable {
    case sparse = 0, normal, dense
}

/// image watermark config
struct ImageWaterMarkConfig {
    let url: String?
}

@objc
public final class WaterMarkLayer: CALayer {
    public override init(layer: Any) {
        super.init(layer: layer)
    }
    
    public required init?(coder: NSCoder) {
        return nil
    }
    
    public override init() {
        super.init()
    }
}

public final class WaterMarkView: UIView {

    static let logger = Logger.log(WaterMarkView.self, category: "WaterMark")
    static let monitor = WaterMarkMonitor()
    let kObviousWaterMarkMaxWidth: CGFloat = 240.0
    let kObviousWaterMarkVerticalInterval: CGFloat = 40.0
    let kObviousWaterMarkHeightPadding: CGFloat = 200.0

    @objc public var isFirstView: Bool = true {
        didSet {
            isFirstViewCallBack?(isFirstView)
        }
    }
    
    public override class var layerClass: AnyClass { WaterMarkLayer.self }

    public var isFirstViewCallBack: ((Bool) -> Void)?
    
    let useCustomObviousWaterMark: Bool

    /// obvious watermark config
    let obviousWaterMarkConfig: ObviousWaterMarkConfig
    
    /// obvious watermark pattern config
    let obviousWaterMarkPatternConfig: ObviousWaterMarkPatternConfig

    /// image watermark config
    let imageWaterMarkConfig: ImageWaterMarkConfig

    /// watermark view showable
    var obviousWaterMarkShow: Bool = true {
        didSet {
            Self.logger.info("obviousWaterMarkShow change \(obviousWaterMarkShow)")
            obviousContainer.isHidden = !obviousWaterMarkShow
        }
    }

    /// image watermark view showable
    var imageWaterMarkShow: Bool = true {
        didSet {
            Self.logger.info("imageWaterMarkShow change \(imageWaterMarkShow)")
            imageContainer.isHidden = !imageWaterMarkShow
        }
    }

    /// store old frame info to re-layout watermark
    private var oldFrame: CGRect?

    /// obvious watermark view container
    private var obviousContainer: CALayer = CALayer()

    /// image watermark view container
    private var imageContainer: CALayer = CALayer()

    /// image watermark tmp view
    private var imageIconView = UIImageView()
    
    /// init watermark view
    /// - Parameters:
    ///   - obviousConfig: 明水印内容
    ///   - imageWaterMarkConfig: 暗水印配置
    ///   - obviousWaterMarkPatternConfig: 明水印样式自定义配置
    ///   - fillColor: background color, default is nil
    ///   - frame: 业务传入自定义明水印frame
    ///   - updateOnInit: 是否在初始化时绘制，默认为false，layoutSubviews时绘制
    ///   - useCustomObviousWaterMark: 明水印是否使用新版自定义配置
    init(obviousWaterMarkConfig: ObviousWaterMarkConfig,
         imageWaterMarkConfig: ImageWaterMarkConfig,
         obviousWaterMarkPatternConfig: ObviousWaterMarkPatternConfig = ObviousWaterMarkPatternConfig(),
         fillColor: UIColor? = nil,
         frame: CGRect = .zero,
         updateOnInit: Bool = false,
         useCustomObviousWaterMark: Bool = true) {
    
        self.obviousWaterMarkConfig = obviousWaterMarkConfig
        self.imageWaterMarkConfig = imageWaterMarkConfig
        self.obviousWaterMarkPatternConfig = obviousWaterMarkPatternConfig
        self.useCustomObviousWaterMark = useCustomObviousWaterMark
        
        super.init(frame: frame)

        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.contentMode = .scaleAspectFill
        self.clipsToBounds = true
        self.isUserInteractionEnabled = false

        self.layer.addSublayer(obviousContainer)
        self.layer.addSublayer(imageContainer)

        if let fillColor = fillColor {
            self.backgroundColor = fillColor
        }
        
        if updateOnInit {
            self.updateWatermarkView()
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        // check frame change
        guard oldFrame?.size != frame.size else {
            return
        }
        // update watermark view
        self.updateWatermarkView()

        // store new frame info
        self.oldFrame = frame
    }

    override public func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        if let old = self.window, old != newWindow {
            old.waterMarkImageView = nil
        }
        if let new = newWindow {
            new.waterMarkImageView = self
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateWatermarkView() {
        if useCustomObviousWaterMark {
            updateObviousCustomWatermarkView()
        } else {
            updateObviousWatermarkView(textColor: obviousWaterMarkConfig.textColor.resolvedCompatibleColor(with: traitCollection))
        }
        updateImageWatermarkView()
    }

    /// update obvious watermark view
    private func updateObviousWatermarkView(textColor: UIColor) {
        obviousContainer.frame = self.bounds
        if let sublayers = obviousContainer.sublayers {
            for layer in sublayers {
                layer.removeFromSuperlayer()
            }
        }
        
        let size: CGSize = CGSize(width: frame.size.width, height: frame.size.height + kObviousWaterMarkHeightPadding)

        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: textColor]
        let drawedText = NSAttributedString(string: obviousWaterMarkConfig.text, attributes: attrs)

        let textSize = drawedText.boundingRect(
            with: CGSize(width: kObviousWaterMarkMaxWidth, height: CGFloat(MAXFLOAT)),
            options: .usesLineFragmentOrigin,
            context: nil).size
        let angle: CGFloat = 15
        let padding: CGFloat = 80.0
        let height: CGFloat = 80
        var currentWidth: CGFloat = 0
        var currentHeight: CGFloat = height
        var rowCount = 0

        while currentHeight < size.height + height * 2 {
            currentWidth = 0
            while currentWidth < size.width {
                let piAngle = angle * CGFloat.pi / 180.0
                var drawPoint = CGPoint(x: currentWidth, y: currentHeight - currentWidth * tan(piAngle))
                if rowCount % 2 == 1 {
                    drawPoint.y -= textSize.width * sin(piAngle)
                    drawPoint.x += textSize.width * cos(piAngle)
                }
                let textLayer = CATextLayer()
                textLayer.contentsScale = traitCollection.displayScale
                textLayer.string = drawedText
                textLayer.anchorPoint = CGPoint.zero
                textLayer.frame = CGRect(origin: .zero, size: textSize)
                textLayer.isWrapped = true
                let transfrom = CGAffineTransform(rotationAngle: -angle * .pi / 180)
                .concatenating(CGAffineTransform(translationX: drawPoint.x, y: drawPoint.y - textSize.height / 2))
                textLayer.transform = CATransform3DMakeAffineTransform(transfrom)

                var textAlpha = 0.12
                if #available(iOS 13.0, *) {
                    let style = UDThemeManager.getRealUserInterfaceStyle()

                    switch style {
                    case .light, .unspecified:
                        textAlpha = 0.12
                    case .dark:
                        textAlpha = 0.08
                    @unknown default:
                        break
                    }
                }
                textLayer.opacity = Float(textAlpha)
                obviousContainer.addSublayer(textLayer)
                currentWidth += textSize.width + padding
            }
            currentHeight += height
            rowCount += 1
        }
    }
    
    /// update obvious watermark view
    private func updateObviousCustomWatermarkView() {
        obviousContainer.frame = self.bounds
        if let sublayers = obviousContainer.sublayers {
            for layer in sublayers {
                layer.removeFromSuperlayer()
            }
        }
        
        let size: CGSize = CGSize(width: frame.size.width, height: frame.size.height + kObviousWaterMarkHeightPadding)

        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: CGFloat(obviousWaterMarkPatternConfig.fontSize)),
            .foregroundColor: obviousWaterMarkConfig.textColor.resolvedCompatibleColor(with: traitCollection)]

        let textLineWrapped = waterMarkLineWrapped(obviousWaterMarkConfig.text)
        let drawedText = NSMutableAttributedString(string: textLineWrapped, attributes: attrs)
        let textSize = drawedText.boundingRect(
            with: CGSize(width: kObviousWaterMarkMaxWidth, height: CGFloat(MAXFLOAT)),
            options: .usesLineFragmentOrigin,
            context: nil).size
        let angle: CGFloat = CGFloat(obviousWaterMarkPatternConfig.rotateAngle)
        let padding: CGFloat
        switch obviousWaterMarkPatternConfig.density {
        case .sparse:
            padding = 64
        case .normal:
            padding = 32
        default:
            padding = 16
        }
        var textAlpha = obviousWaterMarkPatternConfig.opacity
        if #available(iOS 13.0, *) {
            let style = UDThemeManager.getRealUserInterfaceStyle()
            switch style {
            case .light, .unspecified:
                textAlpha = obviousWaterMarkPatternConfig.opacity
            case .dark:
                textAlpha = obviousWaterMarkPatternConfig.darkOpacity
            @unknown default:
                break
            }
        }
        
        let verticalInterval: CGFloat = kObviousWaterMarkVerticalInterval
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var columnCount = 0
        let piAngle = abs(angle) * CGFloat.pi / 180.0
        let yOffset = textSize.height * cos(piAngle) + textSize.width * sin(piAngle) + verticalInterval
        let translationYOffset = angle > 0 ? 0 : textSize.width * sin(piAngle)
        let translationXOffset = angle < 0 ? 0 : textSize.height * sin(piAngle)
        
        while currentY < size.height + verticalInterval * 2 {
            currentX = 0
            columnCount = 0
            while currentX < size.width {
                var drawPoint = CGPoint(x: currentX, y: currentY)
                if columnCount % 2 == 1 {
                    drawPoint.y += yOffset
                }
                let textLayer = CATextLayer()
                textLayer.contentsScale = traitCollection.displayScale
                textLayer.string = drawedText
                textLayer.anchorPoint = CGPoint.zero
                textLayer.frame = CGRect(origin: .zero, size: CGSize(width: textSize.width, height: ceil(textSize.height + 1)))
                textLayer.isWrapped = true
                let transform = CGAffineTransform(rotationAngle: angle * .pi / 180)
                                .concatenating(CGAffineTransform(translationX: drawPoint.x + translationXOffset, y: drawPoint.y + translationYOffset))
                textLayer.transform = CATransform3DMakeAffineTransform(transform)
                textLayer.opacity = Float(textAlpha)
                obviousContainer.addSublayer(textLayer)
                currentX += textSize.width + padding
                columnCount += 1
            }
            currentY += yOffset * 2
        }
    }
    
    private func waterMarkLineWrapped(_ waterMarkText: String) -> String {
        
        let waterMarkTextTrimmed = waterMarkText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !waterMarkTextTrimmed.isEmpty else { return waterMarkText }
        
        func waterMarkPartition(_ text: String) -> [String] {
            var textRemain = String(text)
            var wrappedList = [String]()
            let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: CGFloat(obviousWaterMarkPatternConfig.fontSize))]
            var loopCount = 0
            let loopCountMax = 50
            
            func isAttributedStrFitted(_ str: String) -> Bool {
                return str.trimmingCharacters(in: .whitespacesAndNewlines).size(withAttributes: attrs).width <= kObviousWaterMarkMaxWidth
            }
            
            func nextSpacePosition(of str: String, after afterIndex: String.Index) -> String.Index? {
                let substr = str.suffix(from: afterIndex).trimmingCharacters(in: .whitespacesAndNewlines)
                guard let findIndex = substr.firstIndex(of: " ") else { return nil }
                let distance = str.distance(from: str.startIndex, to: afterIndex)
                let subDistance = substr.distance(from: substr.startIndex, to: findIndex)
                return str.index(str.startIndex, offsetBy: distance + subDistance)
            }
            
            func backtrack(_ wrappedList: inout [String], _ textRemain: inout String, _ fromIndex: String.Index) {
                textRemain = textRemain.trimmingCharacters(in: .whitespacesAndNewlines)
                loopCount += 1
                guard !textRemain.isEmpty, loopCount <= loopCountMax else { return }
                if !textRemain.contains(" ") {
                    wrappedList.append(textRemain)
                } else {
                    guard let spaceIndex = nextSpacePosition(of: textRemain, after: fromIndex) else {
                        if textRemain.contains(" "), !isAttributedStrFitted(textRemain) {
                            let textRemainPrefix = String(textRemain.prefix(upTo: fromIndex)).trimmingCharacters(in: .whitespacesAndNewlines)
                            wrappedList.append(textRemainPrefix)
                            let textRemainSuffix = String(textRemain.suffix(from: fromIndex)).trimmingCharacters(in: .whitespacesAndNewlines)
                            wrappedList.append(textRemainSuffix)
                        } else {
                            wrappedList.append(textRemain)
                        }
                        return
                    }

                    let substring = String(textRemain[textRemain.startIndex...spaceIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if isAttributedStrFitted(substring) {
                        backtrack(&wrappedList, &textRemain, spaceIndex)
                    } else {
                        let strToWrapped = String(textRemain[textRemain.startIndex..<fromIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
                        if strToWrapped.isEmpty {
                            wrappedList.append(substring)
                            textRemain = String(textRemain.suffix(textRemain.count - substring.count))
                        } else {
                            wrappedList.append(strToWrapped)
                            textRemain = String(textRemain.suffix(textRemain.count - strToWrapped.count))
                        }
                        
                        backtrack(&wrappedList, &textRemain, textRemain.startIndex)
                    }
                }
            }

            backtrack(&wrappedList, &textRemain, textRemain.startIndex)
            return wrappedList
        }
        
        let waterMarkPartitioned = waterMarkPartition(waterMarkTextTrimmed)
        return waterMarkPartitioned.joined(separator: "\n")
    }

    /// update image watermark view
    private func updateImageWatermarkView() {
        imageContainer.frame = self.bounds
        if let sublayers = imageContainer.sublayers {
            for layer in sublayers {
                layer.removeFromSuperlayer()
            }
        }
        guard let url = self.imageWaterMarkConfig.url, !url.isEmpty else {
            return
        }
        let setImageBlock = { [weak self] (image: UIImage) in
            guard let self = self, let cgImage = image.cgImage else {
                assertionFailure()
                return
            }
            let size = CGSize(width: self.frame.width, height: self.frame.height)
            let viewSize = CGSize(width: image.size.width, height: image.size.height)
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            while currentY <= size.height {
                currentX = 0
                while currentX <= size.width {
                    let imageView = CALayer()
                    imageView.frame = CGRect(x: currentX, y: currentY, width: viewSize.width, height: viewSize.height)
                    imageView.contentsGravity = .center
                    imageView.contents = cgImage
                    imageView.masksToBounds = true
                    imageView.contentsScale = image.scale

                    self.imageContainer.addSublayer(imageView)
                    currentX += viewSize.width
                }
                currentY += viewSize.height
            }
        }
        // swiftlint:disable superfluous_disable_command
        self.imageIconView.bt.setLarkImage(with: .default(key: url),
                                           options: [.onlyLoadFirstFrame],
                                           completion: { result in
                                            switch result {
                                            case .success(let imageResult):
                                                if let image = imageResult.image {
                                                    setImageBlock(image)
                                                    Self.monitor.monitorHiddenWaterMarkLoadImage(status: 0)
                                                } else {
                                                    Self.logger.error("fetch image url failed")
                                                    Self.monitor.monitorHiddenWaterMarkLoadImage(status: 1, extra: [
                                                        "urlLength": url.count,
                                                        "errorInfo": "set_image_block_failed"
                                                    ])
                                                }
                                            case .failure(let error):
                                                Self.logger.error("fetch image url failed \(error)")
                                                Self.monitor.monitorHiddenWaterMarkLoadImage(status: 1, extra: [
                                                    "urlLength": url.count,
                                                    "errorInfo": error.localizedDescription,
                                                    "errorCode": error.code
                                                ])
                                            }
                                           })
        // swiftlint:enable superfluous_disable_command
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if useCustomObviousWaterMark {
            updateObviousCustomWatermarkView()
        } else {
            updateObviousWatermarkView(textColor: obviousWaterMarkConfig.textColor.resolvedCompatibleColor(with: traitCollection))
        }
    }
}
