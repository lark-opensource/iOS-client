//
//  BubbleBannerView.swift
//  LarkGuide
//
//  Created by zhenning on 2020/10/16.
//

import UIKit
import Foundation
import LKCommonsLogging
import LarkExtensions
import Kingfisher
import Lottie
import UniverseDesignTheme

public final class BubbleBannerView: UIView {

    static let logger = Logger.log(BubbleBannerView.self)
    // 计算普通的image、gifImageData类型，不包含lottie类型
    private var resizedImage: UIImage {
        var sourceImage: UIImage
        switch bannerInfoConfig.imageType {
        case let .image(image):
            // 根据当前的主体模式, 使用对应照片进行渲染
            if #available(iOS 13.0, *), var config = image.configuration {
                switch UDThemeManager.getRealUserInterfaceStyle() {
                case .dark:
                    config = config.withTraitCollection(.init(userInterfaceStyle: .dark))
                    sourceImage = image.withConfiguration(config)
                case .light:
                    config = config.withTraitCollection(.init(userInterfaceStyle: .light))
                    sourceImage = image.withConfiguration(config)
                default:
                    sourceImage = image
                }
            } else {
                sourceImage = image
            }
        case let .gifImageData(data):
            sourceImage = UIImage(data: data) ?? UIImage()
        default:
            sourceImage = UIImage()
        }
        let _resizedImage = resizeImageIfNeed(image: sourceImage)
        return _resizedImage
    }

    private var bannerInfoConfig: BannerInfoConfig {
        didSet {
            switch bannerInfoConfig.imageType {
            case .image:
                self.animatedImageView.image = self.resizedImage
            case let .gifImageData(data):
                let cacheKey: String = data.md5().toHexString()
                let provider = RawImageDataProvider(data: data, cacheKey: cacheKey)
                self.animatedImageView.kf.setImage(with: .provider(provider))
            case .gifImageURL(let info):
                self.animatedImageView.kf.setImage(with: info.url)
            case let .lottie(info):
                self.lottieView = self.createLOTAnimationView(filePath: info.filePath)
            }
        }
    }

    private lazy var animatedImageView: AnimatedImageView = {
        let _animatedImageView = AnimatedImageView()
        _animatedImageView.contentMode = .scaleAspectFit
        return _animatedImageView
    }()

    private var lottieView: LOTAnimationView?

    private var marginWidth: CGFloat {
        return Layout.contentInset.left + Layout.contentInset.right
    }
    private var marginHeight: CGFloat {
        return Layout.contentInset.top + Layout.contentInset.bottom
    }

    public override var intrinsicContentSize: CGSize {
        var sourceImgSize = CGSize.zero
        switch bannerInfoConfig.imageType {
        case .image, .gifImageData:
            sourceImgSize = self.resizedImage.size
        case .gifImageURL(let info):
            sourceImgSize = info.size
        case let .lottie(info):
            sourceImgSize = info.size
        }
        let imageWidth: CGFloat = sourceImgSize.width
        let contentWidth = imageWidth + marginWidth
        let width = (contentWidth < Layout.defaultMaxWidth) ? contentWidth : Layout.defaultMaxWidth
        let height = sourceImgSize.height + marginHeight
        return CGSize(width: width, height: height)
    }

    init(bannerInfoConfig: BannerInfoConfig) {
        self.bannerInfoConfig = bannerInfoConfig
        super.init(frame: .zero)
        setupUI()
    }

    public func update() {
        updateContent(bannerInfoConfig: self.bannerInfoConfig)
    }

    private func setupUI() {
        switch bannerInfoConfig.imageType {
        case .image, .gifImageData:
            self.addSubview(self.animatedImageView)
            self.animatedImageView.snp.makeConstraints { (make) in
                make.top.equalToSuperview().offset(Layout.contentInset.top)
                make.centerX.equalToSuperview()
                make.size.equalTo(self.resizedImage.size)
            }
        case .gifImageURL(let info):
            self.addSubview(self.animatedImageView)
            self.animatedImageView.snp.makeConstraints { (make) in
                make.top.equalToSuperview().offset(Layout.contentInset.top)
                make.centerX.equalToSuperview()
                make.size.equalTo(info.size)
            }
        case let .lottie(info):
            // 设置lottie
            let lottieView: LOTAnimationView = self.lottieView ?? self.createLOTAnimationView(filePath: info.filePath)
            self.addSubview(lottieView)
            lottieView.snp.updateConstraints { (make) in
                make.top.equalToSuperview().offset(Layout.contentInset.top)
                make.centerX.equalToSuperview()
                make.size.equalTo(info.size)
            }
            if !lottieView.isAnimationPlaying {
                lottieView.play()
            }
        }
    }

    func updateContent(bannerInfoConfig: BannerInfoConfig) {
        self.bannerInfoConfig = bannerInfoConfig
        switch bannerInfoConfig.imageType {
        case .gifImageURL(let info):
            self.animatedImageView.snp.updateConstraints { (make) in
                make.size.equalTo(info.size)
            }
        default:
            self.animatedImageView.snp.updateConstraints { (make) in
                make.size.equalTo(self.resizedImage.size)
            }
        }
        if let lottieView = self.lottieView,
           case let .lottie(info) = bannerInfoConfig.imageType {
            lottieView.snp.updateConstraints { (make) in
                make.size.equalTo(info.size)
            }
        }
    }

    // 创建lottie动图
    func createLOTAnimationView(filePath: String) -> LOTAnimationView {
        let lottieView = LOTAnimationView(filePath: filePath)
        lottieView.backgroundColor = .clear
        lottieView.isUserInteractionEnabled = false
        lottieView.contentMode = .scaleAspectFit
        lottieView.loopAnimation = true
        return lottieView
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.lottieView?.stop()
    }
}

extension BubbleBannerView {

    private func resizeImageIfNeed(image: UIImage) -> UIImage {
        let bannerMaxWidth: CGFloat = Layout.defaultMaxWidth - marginWidth
        let imageSize: CGSize = image.size
        if imageSize.width > bannerMaxWidth {
            let fitWidth: CGFloat = bannerMaxWidth
            let fitHeight: CGFloat = fitWidth * imageSize.height / imageSize.width
            let resizedImage = image.lu.resize(maxSize: CGSize(width: fitWidth, height: fitHeight))
            BubbleBannerView.logger.debug("[GuideUI]: resizeImageIfNeed resizedImage size = \(resizedImage.size)")
            return resizedImage
        } else {
            BubbleBannerView.logger.debug("[GuideUI]: resizeImageIfNeed image size = \(image.size)")
            return image
        }
    }
}

extension BubbleBannerView {
    enum Layout {
        static let contentInset: UIEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 15, right: 20)
        static let defaultMaxWidth: CGFloat = BaseBubbleView.Layout.defaultMaxWidth
    }
}
