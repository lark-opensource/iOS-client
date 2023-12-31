//
//  LabImageLoader.swift
//  ByteView
//
//  Created by wangpeiran on 2021/11/9.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

class LabImageLoader {

    let serialQueue = DispatchQueue(label: "lab bg quene")

    let service: MeetingBasicService

    private lazy var cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
//        cache.countLimit = 128
//        cache.totalCostLimit = 5 * 1024 * 1024
        return cache
    }()

    init(service: MeetingBasicService) {
        self.service = service
        Logger.lab.info("lab bg: LabImageLoader init")
    }

    deinit {
        Logger.lab.info("lab bg: LabImageLoader deinit")
    }

    func obtainImageWithPath(model: VirtualBgModel, completionHandler: @escaping (UIImage?) -> Void) {
        let imagePath = model.thumbnailPath
        if let image = self.cache.object(forKey: imagePath as NSString) {
//            Logger.lab.debug("lab bg: load thumbnailImage from cache")
            completionHandler(image)
        } else {
            if model.hasCropThumbnail() { // 如果存在缩略图，已经裁剪过，直接读取+解码
                serialQueue.async {
                    let absPath = self.service.storage.getAbsPath(absolutePath: model.thumbnailPath)
                    if absPath.fileExists(),
                       let imageData = try? absPath.readData(options: .mappedIfSafe),
                       let image = UIImage(data: imageData),
                       let decodedImage = image.decode() {
                        self.cache.setObject(decodedImage, forKey: imagePath as NSString)
                        DispatchQueue.main.async {
//                            Logger.lab.debug("lab bg: load from decode")
                            completionHandler(image)
                        }
                    } else {
                        DispatchQueue.main.async {
//                            Logger.lab.debug("lab bg: load from decode failed")
                            completionHandler(nil)
                        }
                    }
                }
            } else { // 如果不存在，裁剪
                let placeholderImage: UIImage? = nil  // 可以添加placeholder图
                DispatchQueue.main.async {
                    completionHandler(placeholderImage)
                }
                serialQueue.async {
                    if let image = LabImageCrop.cropThumbnailImageAt(path: model.originPath, thumbnailPath: model.thumbnailIsoPath, service: self.service) {
                        self.cache.setObject(image, forKey: imagePath as NSString)
                        DispatchQueue.main.async {
                            Logger.lab.debug("lab bg: load from crop")
                            completionHandler(image)
                        }
                    } else {
                        DispatchQueue.main.async {
                            completionHandler(nil)
                        }
                    }
                }
            }
        }
    }
}

extension UIImage {

    /**
     解码UIImage为bitmap(位图)

     - returns: UIImage 位图对象
     */
    func decode() -> UIImage? {

        // 获取UIImage对应的CGImage对象
        guard let imageRef = self.cgImage else { return self }

        // 获取 宽和高
        let width = imageRef.width
        let height = imageRef.height

        guard width != 0 || height != 0 else { return self }

        // 使用设备的颜色空间 RGB
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        // 判断是否有 alpha 通道
        let alphaInfo = imageRef.alphaInfo
        var hasAlpha = false
        if alphaInfo == .premultipliedLast ||
           alphaInfo == .premultipliedFirst ||
           alphaInfo == .last ||
           alphaInfo == .first {
            hasAlpha = true
        }

        // 位图布局信息
        var bitmapInfo = CGBitmapInfo.byteOrder32Little.rawValue
        bitmapInfo |= hasAlpha ? CGImageAlphaInfo.premultipliedFirst.rawValue : CGImageAlphaInfo.noneSkipFirst.rawValue

        // 创建context
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo) else { return self }

        context.draw(imageRef, in: CGRect(x: 0.0, y: 0.0, width: CGFloat(width), height: CGFloat(height)))

        // 获取解码后的CGImage对象
        guard let docededImageRef = context.makeImage() else { return self }

        // 返回解码后的UIImage对象
        return UIImage(cgImage: docededImageRef, scale: self.scale, orientation: self.imageOrientation)

    }
}
