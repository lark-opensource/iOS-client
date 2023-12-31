//
//  ImageUtil.swift
//  Pods
//
//  Created by Yuri on 2023/8/3.
//

import Foundation

class ImageUtil {
    static func combineImages(_ image1: UIImage, _ image2: UIImage) -> UIImage? {
        // 获取两张图片的大小
        let size = image1.size

        // 使用UIGraphicsImageRenderer绘制组合图像
        let renderer = UIGraphicsImageRenderer(size: size)
        let combinedImage = renderer.image { _ in
            // 将两张图片绘制到同一个图形上下文中
            image1.draw(in: CGRect(origin: .zero, size: size))
            image2.draw(in: CGRect(origin: .zero, size: size))
        }
        return combinedImage
    }
}
