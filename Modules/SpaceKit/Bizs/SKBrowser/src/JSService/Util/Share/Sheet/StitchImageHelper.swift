//
//  StitchImageHelper.swift
//  TestCombineImageDatas
//
//  Created by 吴珂 on 2020/11/2.
//


import Foundation
import SKFoundation

class ImageInfo: Equatable {
    private(set) var pixelPtr: UnsafeMutablePointer<UInt8>?
    var width: UInt32 //图像宽
    var height: UInt32 //图像高
    var isLastCol = false
    var isFinish = false
    
    var pixelSize: UInt64 {
        return UInt64(width * height * 4)
    }
    
    init(pixelPtr: UnsafeMutablePointer<UInt8>, width: UInt32, height: UInt32, isLastCol: Bool, isFinish: Bool) {
        self.pixelPtr = pixelPtr
        self.width = width
        self.height = height
        self.isLastCol = isLastCol
        self.isFinish = isFinish
    }
    
    static func == (lhs: ImageInfo, rhs: ImageInfo) -> Bool {
        return lhs.pixelPtr == rhs.pixelPtr
    }
    
    func free() {
        pixelPtr?.deallocate()
        pixelPtr = nil
    }
    
}

protocol StitchImageHelperDelegate: AnyObject {
    func stitchImageFinished(_ helper: StitchImageHelper)
    //内存问题暂停与恢复
    func receiveImagePause(_ helper: StitchImageHelper)
    func receiveImageResume(_ helper: StitchImageHelper)
}

class StitchImageHelper {
    
    var totalImagesBuffer: [[ImageInfo]] = []
    var imageBufferLock = os_unfair_lock()
    var imageSizeInTotalBufferLock = os_unfair_lock() //计算接收数据大小的锁
    private var imageSizeInTotalBuffer: UInt64 = 0
    private var fixImageSizeInTotalBuffer: UInt64 {
        return imageSizeInTotalBuffer * 2
    }
    var currentImagesBuffer: [ImageInfo] = []
    var height: UInt32 //总高度
    var width: UInt32 //总宽度
    var helper: PNGHelper = PNGHelper()
    
    weak var delegate: StitchImageHelperDelegate?
    //time measure
    var startDate = Date()
    
    private lazy var writeQueue = DispatchQueue(label: "sk.longpic.generateImage.queue", qos: .default, attributes: .init(), autoreleaseFrequency: .never, target: nil)
    
    private var initialized = false
    
    var imagePath: SKFilePath {
        return helper.filePath
    }

    init(width: UInt32, height: UInt32, fileName: String?) {
        self.height = height
        self.width = width
        
        initialized = helper.initialize(width: width, height: height, compressLevel: 3, fileName: fileName)
        
    }
    
    //每次写横向的数据
    func stitchImageAndWriteImages(_ images: [ImageInfo], desBuffer: UnsafeMutablePointer<UInt8>, size: UInt32) {
        
        guard initialized == true, let firstImage = images.first else {
            DocsLogger.info("stitch image PNGHelper initialize failed")
            return
        }
        let imageHeight = firstImage.height
        
        Date.measure(prefix: "stitch image 拼接测试总耗时") {
            var colOffset: Int32 = 0
            for image in images {
                //越界检测
                let maxColOffset = (image.height - 1) * width * 4
                let maxRightBoundary = (colOffset + Int32(maxColOffset) + Int32(image.width) * 4)
                guard maxRightBoundary <= size else {
                    DocsLogger.info("stitch image 图像数据越界")
                    return
                }
                
                DocsLogger.info("stitch image size: \(size) maxRightBoundary: \(maxRightBoundary)")
                
                Date.measure(prefix: "stitch image 拼接测试单张耗时") {
                    stitchImage(desBuffer, image.pixelPtr, Int32(image.width) * 4, Int32(image.height), colOffset, Int32(width) * 4)
                }
                colOffset += Int32(image.width) * 4
            }
            
            Date.measure(prefix: "stitch image 写入耗时") {
                let bitsPerRow = Int(width * 4)
                writeBuffer(buffer: desBuffer, bitsPerRow: bitsPerRow, rows: imageHeight)
            }
        }
        
    }
    
    func writeBuffer(buffer: UnsafeMutablePointer<UInt8>, bitsPerRow: Int, rows: UInt32) {
        Date.measure(prefix: "写入耗时") {
            for row in 0..<rows {
                let offsetBuffer = buffer.advanced(by: bitsPerRow * Int(row))
                helper.writeRow(offsetBuffer)
            }
        }
    }
    
    private func flush() {
        let imagesTemp = imagesOfTheFirstRow()
        guard let images = imagesTemp else {
            return
        }
        
        guard let imageInfo = images.last else {
            return
        }
        
        guard imageInfo.isLastCol else {
            return
        }
        
        let imageHeight = imageInfo.height
        let bufferSize = width * imageHeight * UInt32(4)
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(bufferSize))
        
        stitchImageAndWriteImages(images, desBuffer: buffer, size: bufferSize)
        
        for imageInfo in images {
            //修改已用空间
            lockImageSizeInBuffer()
            imageSizeInTotalBuffer -= UInt64(imageInfo.pixelSize)
            unlockImageSizeInBuffer()
            imageInfo.free()
        }
        
        buffer.deallocate()
        
        self.delegate?.receiveImageResume(self)
        if imageInfo.isFinish {
            finish()
        }
    }
    
    func receiveImageInfo(_ info: ImageInfo) {
        guard canReceiveImage() else {
            DocsLogger.info("stitch image 内存占用过大，请稍后再试")
            self.delegate?.receiveImagePause(self)//暂停
            return
        }
        lockImageBuffer()
        lockImageSizeInBuffer()
        imageSizeInTotalBuffer += UInt64(info.pixelSize)
        unlockImageSizeInBuffer()
        DocsLogger.info("stitch image stich image width: \(width) height: \(height)")
        if info.isLastCol {
            currentImagesBuffer.append(info)
            
            totalImagesBuffer.append(currentImagesBuffer)
            
            currentImagesBuffer = [ImageInfo]()
            
            //异步进行flush
            writeQueue.async {
                self.flush()
            }
        } else {
            currentImagesBuffer.append(info)
        }
        unlockImageBuffer()
    }
    
    func finish() {
        self.helper.finish()
        DocsLogger.info("stitch image \(helper.filePath)")
        DocsLogger.info("stitch image 总耗时：\(Date().timeIntervalSince(startDate) * 1000)ms width: \(width) height: \(height)")
        DispatchQueue.main.async {
            self.delegate?.stitchImageFinished(self)
        }
    }
    
    func imagesOfTheFirstRow() -> [ImageInfo]? {
        lockImageBuffer()
        defer {
            unlockImageBuffer()
        }
        guard !totalImagesBuffer.isEmpty else {
            return nil
        }
        let images = totalImagesBuffer.first
        totalImagesBuffer.removeFirst()
        return images
    }
    
    func canReceiveImage() -> Bool {
        lockImageSizeInBuffer()
        let bufferSize = fixImageSizeInTotalBuffer
        unlockImageSizeInBuffer()
        let fakePhysicalMemory = Double(ProcessInfo.processInfo.physicalMemory)
        let physicalMemory = Double(fakePhysicalMemory) / 1048576.0 //最大内存MB
        let maxBufferSize = physicalMemory * 0.3 //最大为内存的四分之一，因为接收到的所有buffer还需要用totalBuffer来装，所以实际占用的大小是两倍
        
        return (bufferSize / 1048576) <= UInt64(maxBufferSize)
    }
    
    func cancel(_ calledByDeinit: Bool = false) {
        lockImageBuffer()
        guard !totalImagesBuffer.isEmpty || !currentImagesBuffer.isEmpty else {
            DocsLogger.info("stitch image 没有需要释放的资源")
            unlockImageBuffer()
            return
        }
        //清理资源
        for images in totalImagesBuffer {
            for image in images {
                image.free()
            }
        }
        
        totalImagesBuffer.removeAll()
        
        for image in currentImagesBuffer {
            image.free()
        }
        currentImagesBuffer = []
        unlockImageBuffer()
    }
    
    func freeCache() {
        helper.freeCache()
    }
}

//锁相关
extension StitchImageHelper {
    
    func lockImageBuffer() {
        os_unfair_lock_lock(&self.imageBufferLock)
    }
    
    func unlockImageBuffer() {
        os_unfair_lock_unlock(&self.imageBufferLock)
    }
    
    func lockImageSizeInBuffer() {
        os_unfair_lock_lock(&self.imageSizeInTotalBufferLock)
    }
    
    func unlockImageSizeInBuffer() {
        os_unfair_lock_unlock(&self.imageSizeInTotalBufferLock)
    }
}
