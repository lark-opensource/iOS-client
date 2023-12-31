//
//  FileUtils+SaveImage.swift
//  OPFoundation
//
//  Created by zhangxudong.999 on 2023/2/20.
//

import Foundation
public struct FileUtils {}
public extension FileUtils {
    struct SaveImageResult {
        // 路径
        public let path: String
        /// 大小，单位byte
        public let size: Int
    }
    enum SaveImageError: Error {
        case saveError
    }
}
extension FileUtils {
    
    /// 图片存储
    /// - Parameters:
    ///   - image: 存储的目标图片
    ///   - isOriginal: 存储的画质
    ///   - fsContext: 文件系统需要的上下文
    /// - Returns: 存储结果
    public static func saveImage(image: UIImage,
                                 compressionQuality: CGFloat,
                                 fsContext: FileSystem.Context) throws -> FileUtils.SaveImageResult {
        fsContext.trace.info("saveImage compressionQuality:\(compressionQuality)")
        let _fixImage: UIImage? = UIImage.bdp_fixOrientation(image)
        guard let fixImage = _fixImage else {
            // 不可能情况
            fsContext.trace.error("chooseImageV2 fixOrientation nil")
            throw SaveImageError.saveError
        }
        let _imageData: Data?
        if fixImage.images != nil {
            /// gif
            _imageData = BDPImageAnimatedGIFRepresentation(fixImage, fixImage.duration, 0, nil)
        } else {
            var newImage = fixImage
            if compressionQuality != 1{
                fsContext.trace.info("saveImage downsampleImage start")
                newImage = ImageDownSampleUtils.downsampleImage(image: fixImage)
            }
            _imageData = newImage.jpegData(compressionQuality: compressionQuality)
        }
        guard let imageData = _imageData, let fileExtension = TMACustomHelper.contentType(forImageData: imageData) else {
            fsContext.trace.error("chooseImageV2 compress error")
            throw SaveImageError.saveError
        }
        fsContext.trace.info("saveImage with imageData.count:\(imageData.count), image.size:\(fixImage.size)")
        do {
            /// 准备数据
            let randomFile = FileObject.generateRandomTTFile(type: .temp, fileExtension: fileExtension)
            /// 写入数据
            try FileSystemCompatible.writeSystemData(imageData, to: randomFile, context: fsContext)
            
            return .init(path: randomFile.rawValue, size: imageData.count)
        } catch let e {
            fsContext.trace.error("chooseImageV2 save failed \(e)")
            throw SaveImageError.saveError
        }
    }
}



