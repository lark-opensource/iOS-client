//
//  GroupQRCodeHeaderBGView.swift
//  LarkChatSetting
//
//  Created by liuxianyu on 2021/9/15.
//

import Foundation
import LKCommonsLogging
import AvatarComponent
import LarkBizAvatar
import UIKit
import LarkUIKit

final class GroupQRCodeHeaderBGView: UIView {
    static let logger = Logger.log(GroupQRCodeHeaderBGView.self, category: "Module.LarkChatSetting.GroupQRCodeHeaderBGView")

    public lazy var backgroundImageView: BizAvatar = {
        let view = BizAvatar()
        var config = AvatarComponentUIConfig(style: .square)
        config.backgroundColor = UIColor.clear
        config.contentMode = .scaleAspectFill
        view.setAvatarUIConfig(config)
        view.isUserInteractionEnabled = false
        view.isHidden = true
        view.alpha = 0.5
        return view
    }()

    private lazy var colorImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.alpha = 0.8
        imageView.clipsToBounds = true
        return imageView
    }()

    init() {
        super.init(frame: .zero)
        setupView()
    }
    private func setupView() {
        self.clipsToBounds = true
        self.backgroundColor = GroupQRCodePrimaryColorManager.defaultColor
        addSubview(backgroundImageView)
        addSubview(colorImageView)
        backgroundImageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        colorImageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func setHeaderBGImageWithOriginImage(_ originImage: UIImage, entityId: String, key: String, finish: ((UIImage) -> Void)?) {
        // 这里和UI确认过 gif不支持播放
        backgroundImageView.setAvatarByIdentifier(entityId,
                                                  avatarKey: key,
                                                  avatarViewParams: .defaultMiddle,
                                                  backgroundColorWhenError: .clear) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                if let image = self.backgroundImageView.image {
                    self.backgroundImageView.image = UIImage.applyBlurRadius(toImage: image)
                }
            default:
                break
            }
        }

        // 当头像取色为偏白色时，改用默认背景图展示
        if let colors = ColorThief.getPalette(from: originImage, colorCount: 5, quality: 10, ignoreWhite: false), !colors.isEmpty {
            let dominantColor = colors[0]
            if dominantColor.r >= 250,
               dominantColor.g >= 250,
               dominantColor.b >= 250 {
                let defaultImage = UIImage.getGradientImageByColors([UIColor.ud.rgb(0x4C88FF), UIColor.ud.rgb(0x2E65D1)],
                                                                    startPoint: CGPoint(x: 0, y: 0),
                                                                    endPoint: CGPoint(x: 1, y: 0),
                                                                    size: originImage.size)
                self.colorImageView.image = defaultImage
                self.colorImageView.alpha = 1
                self.backgroundColor = .clear
                self.backgroundImageView.isHidden = true
                if let defaultImage = defaultImage {
                    finish?(defaultImage)
                }
                return
            }
        }

        GroupQRCodePrimaryColorManager.getPrimaryColorImageBy(image: originImage, avatarKey: key, size: originImage.size) { [weak self] (image, error) in
            if let image = image {
                self?.colorImageView.image = image
                self?.colorImageView.alpha = 0.8
                self?.backgroundColor = .clear
                self?.backgroundImageView.isHidden = false
                finish?(image)
            } else {
                Self.logger.error("setHeaderBackGroundImageWithOriginImage -----key: \(key) ---- error: \(error)")
            }
        }
    }
}

private extension UIImage {
    public static func applyBlurRadius(radius: CGFloat? = 150, toImage: UIImage) -> UIImage? {
        var validRadius: CGFloat = 0
        if let radius = radius, radius > 0 {
            validRadius = radius
        }

        let context: CIContext = CIContext()
        guard let cgImg = toImage.cgImage else {
            return toImage
        }
        let inputImage = CIImage(cgImage: cgImg)
        guard let filter = CIFilter(name: "CIGaussianBlur", parameters: nil) else {
            return toImage
        }
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(validRadius, forKey: "inputRadius")
        guard let result = filter.value(forKey: kCIOutputImageKey) as? CIImage else {
            return toImage
        }
        guard let cgImage = context.createCGImage(result, from: inputImage.extent) else {
            return toImage
        }
        let returnImage = UIImage(cgImage: cgImage)
        return returnImage
    }

    public static func getGradientImageByColors(_ colors: [UIColor], startPoint: CGPoint, endPoint: CGPoint, size: CGSize) -> UIImage? {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(origin: .zero, size: size)
        gradientLayer.colors = colors.map({ (color) -> CGColor in
            return color.cgColor
        })
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint

        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }
        if let ctx = UIGraphicsGetCurrentContext() {
            gradientLayer.render(in: ctx)
            return UIGraphicsGetImageFromCurrentImageContext()
        }
        return nil
    }
}
