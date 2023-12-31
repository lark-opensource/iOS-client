//
//  HugeImageView.swift
//  ByteWebImage
//
//  Created by Saafo on 2023/5/10.
//

import UIKit

/// 大图展示容器
///
/// 可以播放动图、展示超大图（按需分片）
public final class HugeImageView: UIView {

    // MARK: Public attributes

    /// 图片大小，单位 px
    public private(set) var imageSize: CGSize = .zero

    /// 性能安全的图片
    ///
    /// 当未触发分片时（小图），返回原图；当触发分片时（大图），返回预览图
    public var safeImage: UIImage? {
        normalImageView.image
    }

    /// 图片原始数据
    public private(set) var imageData: Data?

    /// 图片格式
    public private(set) var imageFileFormat: ImageFileFormat = .unknown

    /// 是否为动图
    public private(set) var isAnimatedImage: Bool = false

    /// 是否分片
    public private(set) var usingTile: Bool = false

    // MARK: Public config

    /// 大图展示容器配置
    public struct Config {

        /// 触发分片宽高乘积阈值
        public var tileThresholdPixels: Int = (1000 * Self.scale) ^ 2

        /// 分片预览图宽高乘积限制
        public var tilePreviewPixels: Int = (700 * Self.scale) ^ 2

        private static let scale = Int(UIScreen.main.scale)
        fileprivate static func sizeFrom(pixels: Int) -> CGSize {
            let side = CGFloat(sqrt(Double(pixels)))
            return CGSize(width: side, height: side)
        }
    }

    /// 大图展示容器默认配置
    public static var defaultConfig: Config = .init()

    /// 大图展示容器配置
    public var config: Config = defaultConfig

    // MARK: Animated Image Config

    /// ``ByteImageView/animateRunLoopMode``
    public var animateRunLoopMode: RunLoop.Mode {
        get { normalImageView.animateRunLoopMode }
        set { normalImageView.animateRunLoopMode = newValue }
    }

    /// ``ByteImageView/autoPlayAnimatedImage``
    public var autoPlayAnimatedImage: Bool {
        get { normalImageView.autoPlayAnimatedImage }
        set { normalImageView.autoPlayAnimatedImage = newValue }
    }

    // MARK: Internal attributes

    private let normalImageView = ByteImageView()

    private let tiledImageView = TiledImageView()

    // MARK: Public methods

    /// 创建一个大图展示容器
    public override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(normalImageView)
        addSubview(tiledImageView)
        normalImageView.isUserInteractionEnabled = true
        normalImageView.contentMode = .scaleAspectFill
        tiledImageView.contentMode = .scaleAspectFill
        tiledImageView.isHidden = true // hidden by default

        normalImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            normalImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            normalImageView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            normalImageView.topAnchor.constraint(equalTo: self.topAnchor),
            normalImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        tiledImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tiledImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            tiledImageView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            tiledImageView.topAnchor.constraint(equalTo: self.topAnchor),
            tiledImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }

    /// 设置图片
    /// - Parameters:
    ///   - data: 图片数据
    ///   - completion: 设置成功后回调，可以在此回调时机获取各种属性
    public func setImage(data: Data, completion: ((Result<Void, Error>) -> Void)? = nil) {
        imageData = data
        let decodeBox: ImageDecodeBox
        do {
            decodeBox = try ImageDecodeBox(data, needCrop: true)
            imageSize = try decodeBox.pixelSize
            imageFileFormat = decodeBox.format
            isAnimatedImage = decodeBox.isAnimatedImage
        } catch {
            completion?(.failure(error))
            return
        }

        DispatchImageQueue.async { [weak self] in
            guard let self else { return }
            // Tile image
            if ImageConfiguration.enableTile,
               self.imageSize.width * self.imageSize.height > CGFloat(self.config.tileThresholdPixels) {
                do {
                    try self.tiledImageView.set(with: decodeBox)
                    let downsampleSize = Config.sizeFrom(pixels: self.config.tilePreviewPixels)
                    let previewImage = try ByteImage(data, downsampleSize: downsampleSize)
                    DispatchMainQueue.async { [weak self] in
                        guard let self else { return }
                        self.normalImageView.image = previewImage
                        self.tiledImageView.isHidden = false
                        self.usingTile = true
                        completion?(.success(()))
                    }
                    return
                } catch {
                    Log.info("set tiledImageView with error: \(error)")
                }
            }
            // Normal image
            do {
                let downsampleSize = Config.sizeFrom(pixels: self.config.tileThresholdPixels)
                let image = try ByteImage(decodeBox, downsampleSize: downsampleSize)
                DispatchMainQueue.async { [weak self] in
                    guard let self else { return }
                    self.normalImageView.image = image
                    self.tiledImageView.isHidden = true
                    self.usingTile = false
                    completion?(.success(()))
                }
            } catch {
                DispatchMainQueue.async {
                    completion?(.failure(error))
                }
            }
        }
    }

    /// 更新分片容器缩放比
    ///
    /// - Note: 设置图片完成后，需要调用此方法触发分片容器的渲染
    public func updateTiledView(maxScale: CGFloat = TiledImageView.defaultMaxScale,
                                minScale: CGFloat = TiledImageView.defaultMinScale) {
        tiledImageView.update(maxScale: maxScale, minScale: minScale)
    }

    /// 重置容器
    public func reset() {
        normalImageView.image = nil
        tiledImageView.reset()
        imageSize = .zero
        imageData = nil
        imageFileFormat = .unknown
        isAnimatedImage = false
        usingTile = false
        config = Self.defaultConfig
    }

    /// 播放动图
    public func startAnimating() {
        guard isAnimatedImage else { return }
        normalImageView.startAnimating()
    }

    /// 暂停播放动图
    public func pause() {
        guard isAnimatedImage else { return }
        normalImageView.pause()
    }

    /// 暂停播放动图
    public func stopAnimating() {
        guard isAnimatedImage else { return }
        normalImageView.stopAnimating()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
