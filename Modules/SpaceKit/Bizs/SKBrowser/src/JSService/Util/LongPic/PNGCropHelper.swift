//
//  PNGCropHelper.swift
//  TestLongPic
//
//  Created by 吴珂 on 2020/9/11.
//  Copyright © 2020 bytedance. All rights reserved.


import Foundation
import MobileCoreServices
import SKFoundation
import libpng

protocol PNGCropHelperDelegate: AnyObject {
    func didFinishCropImage(_ helper: PNGCropHelper)
    func didGenerateOneImage(_ helper: PNGCropHelper, _ y: Int32)
    func didCancelled(_ helper: PNGCropHelper)
    func cropFailed(_ helper: PNGCropHelper)
}

class PNGCropHelper {
    
    weak var delegate: PNGCropHelperDelegate?
    private let cacheLimitCount = 100
    private var cache: NSCache<NSString, UIImage>
    private var tileSize: UInt32 = 256
    private var pngPtr: png_structp?
    private var infoPtr: png_infop?
    
    private var isCancelled = false
    
    //一张图有几个tile
    private var rowsPerImage: UInt32 {
        return 1
    }
    
    init(_ tileSize: UInt32) {
        self.tileSize = tileSize
        cache = NSCache<NSString, UIImage>()
        cache.countLimit = cacheLimitCount
    }
    
    func cropImage(_ path: String) {
        clearResources()
        cropImageCore(path)
    }
    
    private func cropImageCore(_ path: String) {
        
        if !SKFilePath(absPath: path).exists {
            DocsLogger.error("crop helper 文件不存在")
            delegate?.cropFailed(self)
            return
        }
        
        let startDate = Date()
        DispatchQueue.global().async { [weak self] in
            guard let self = self else {
                return
            }
            Date.measure(prefix: "crop image") {
                var width: png_uint_32 = 0
                var height: png_uint_32 = 0
                
                var fp1: UnsafeMutablePointer<FILE>?
                
                fp1 = fopen(path.cString(using: .utf8), "rb")
                
                guard let fp = fp1 else {
                    DocsLogger.error("crop helper 文件读取失败")
                    self.delegate?.cropFailed(self)
                    return
                }
                
                guard let pngPtr = png_create_read_struct(PNG_LIBPNG_VER_STRING,
                                                           nil, nil, nil) else {
                                                            fclose(fp)
                                                            DocsLogger.info("read failed")
                                                            return
                }
                png_set_user_limits(pngPtr, 0x7fffffff, 0x7fffffff)
                self.pngPtr = pngPtr
                
                guard let infoPtr = png_create_info_struct(pngPtr) else {
                    fclose(fp)
                    png_destroy_read_struct(&self.pngPtr, nil, nil)
                    DocsLogger.info("crop helper read failed")
                    self.delegate?.cropFailed(self)
                    return
                }
                
                self.infoPtr = infoPtr
                png_init_io(pngPtr, fp1)
                
                var bitDepth: Int32 = 0
                var colorType: Int32 = 0
                var interlaceType: Int32 = 0
                
                png_read_info(pngPtr, infoPtr)
                
                png_get_IHDR(pngPtr, infoPtr, &width, &height, &bitDepth, &colorType, &interlaceType, nil, nil)
                    
                let capacityPerRow = Int(width) * 4
                
                let readHeightPerTime: UInt32 = self.tileSize
                let readCount = Int32(ceil(Double(Double(height) / Double(readHeightPerTime))))
                var leftRows: UInt32 = height
                
                for row in 0..<readCount {
                    guard !self.isCancelled else {
                        self.delegate?.didCancelled(self)
                        self.clearResources()
                        return
                    }
                    let fixReadHeight = min(leftRows, readHeightPerTime)
                    
                    var rowsP: [UnsafeMutablePointer<UInt8>?] = []
                    let buffers = createBuffer(Int32(capacityPerRow), Int32(fixReadHeight))
                    var rowsPP = self.getMutablePointerType(ptr: &rowsP)
                    if let buffers = buffers {
                        rowsPP = buffers
                    }
                    png_read_rows(pngPtr, rowsPP, nil, png_uint_32(fixReadHeight))
                    
                    guard let renderRows = rowsPP.pointee else {
                        continue
                    }
                    
                    autoreleasepool {
                        let image = UIImage.imageWithPixelsRGBA8(renderRows, width: Int(width), height: Int(fixReadHeight))
                        if let imageRef = image?.cgImage {
                            let path = self.imagePath(Int(row))
                            let success = self.writeCGImage(imageRef, to: path)
                            if success {
                                let endDate = Date()
                                let elaspedTime = endDate.timeIntervalSince(startDate)
                                DocsLogger.info("pngHelper get first image elaspedTime: \(elaspedTime * 1000) ")
                                self.delegate?.didGenerateOneImage(self, row)
                            }
                            DocsLogger.info("pngHelper write \(row) \(success) \n \(path)")
                        }
                    }
                    freeBuffer(buffers, Int32(fixReadHeight))
                    if row == readCount - 1 {
                        break
                    }
                    leftRows -= readHeightPerTime
                }
                
                png_destroy_read_struct(&self.pngPtr, &self.infoPtr, nil)
                
                self.delegate?.didFinishCropImage(self)
            }
        }
    }
    
    func getMutablePointerType<T> (ptr: UnsafeMutablePointer<T>) -> UnsafeMutablePointer<T> {
        return ptr
    }
    
    
    @discardableResult
    func writeCGImage(_ image: CGImage, to destinationURL: SKFilePath) -> Bool {
        guard let destination = CGImageDestinationCreateWithURL(destinationURL.pathURL as CFURL, kUTTypePNG, 1, nil) else { return false }
        CGImageDestinationAddImage(destination, image, nil)
        return CGImageDestinationFinalize(destination)
    }

    func getCacheKey(x: UInt32, y: UInt32) -> NSString {
        return "\(x)_\(y)" as NSString
    }
    
    func getImage(x: UInt32, y: UInt32) -> UIImage? {
        let imageY = Int((floor(Double(y) / Double(rowsPerImage))))
        let path = imagePath(imageY)
        
        guard let image = try? UIImage.read(from: path) else {
            DocsLogger.error("can not get image from url")
            return nil
        }
                
        let size = CGFloat(tileSize)
        let fixY = CGFloat(y % rowsPerImage)
        let xPoint = CGFloat(x * tileSize)
        let yPoint = CGFloat(fixY * size)
        
        let cacheKey = getCacheKey(x: x, y: y)
        
        if let storedImage = cache.object(forKey: cacheKey) {
            DocsLogger.info("use cache key: \(cacheKey)")
            return storedImage
        }
        
        let cutRect = CGRect(x: xPoint,
                             y: yPoint,
                             width: size,
                             height: size)
        guard let imageRef = image.cgImage?.cropping(to: cutRect) else {
            return nil
        }
        
        let targetImage = UIImage(cgImage: imageRef)
        
        cache.setObject(targetImage, forKey: cacheKey)
        
        return targetImage
    }
    
    func clearResources() {
        do {
            try storeImageFolder().removeItem()
        } catch {
            DocsLogger.info("\(error.localizedDescription)")
        }
        
    }
    
    func cancel() {
        isCancelled = true
    }
    
    
    private func storeImageFolder() -> SKFilePath {
        let folderName = "crop"
        let folderPath = SKFilePath.globalSandboxWithTemporary.appendingRelativePath(folderName)
        let exists = folderPath.exists
        if !exists {
            do {
                try folderPath.createDirectory(withIntermediateDirectories: true)
            } catch {
                DocsLogger.info("create folder failed \(error.localizedDescription)")
            }
        }
        return folderPath
    }
    
    private func imagePath(_ imageY: Int) -> SKFilePath {
        return storeImageFolder().appendingRelativePath("temp__image_\(imageY).png")
    }
}

extension UIImage {
    static func imageWithPixelsRGBA8(_ pixels: UnsafeMutablePointer<UInt8>, width: Int, height: Int) -> UIImage? {
        let dataSize = width * height * 4
        var image: UIImage?
        autoreleasepool {
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let data = NSData(bytes: pixels, length: dataSize) as CFData
            guard let provider = CGDataProvider(data: data) else {
                return
            }
            if let imageRef = CGImage(width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bitsPerPixel: 32,
                    bytesPerRow: 4 * width,
                    space: colorSpace,
                    bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                    provider: provider,
                    decode: nil,
                    shouldInterpolate: true,
                    intent: .defaultIntent) {
                image = UIImage(cgImage: imageRef)
            }
        }
        return image
    }
}
