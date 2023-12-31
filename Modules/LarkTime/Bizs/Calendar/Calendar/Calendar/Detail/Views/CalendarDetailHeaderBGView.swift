//
//  CalendarDetailHeaderBGView.swift
//  Calendar
//
//  Created by Hongbin Liang on 4/13/23.
//
//  copy from LarkChatSetting/GroupQRCodeHeaderBGView

import Foundation
import UIKit
import LarkUIKit

final class CalendarDetailHeaderBGView: UIView {
    private lazy var colorImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.alpha = 0.8
        imageView.clipsToBounds = true
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        addSubview(colorImageView)
        colorImageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setHeaderBGImageWithOriginImage(_ originImage: UIImage, _ key: String) {
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
                return
            }
        }

        CalendarPrimaryColorManager.getPrimaryColorImageBy(image: originImage, avatarKey: key, size: originImage.size) { [weak self] (image, error) in
            if let image = image {
                self?.colorImageView.image = image
                self?.colorImageView.alpha = 0.8
            } else {
                CalendarBiz.detailLogger.error("setHeaderBackGroundImageWithOriginImage -----key: \(key) ---- error: \(error.debugDescription)")
            }
        }
    }
}

private extension UIImage {
    static func getGradientImageByColors(_ colors: [UIColor], startPoint: CGPoint, endPoint: CGPoint, size: CGSize) -> UIImage? {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(origin: .zero, size: size)
        gradientLayer.colors = colors.map({ (color) -> CGColor in
            return color.cgColor
        })
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        
        return UIGraphicsImageRenderer(size: size).image { context in
            gradientLayer.render(in: context.cgContext)
        }
    }
}
