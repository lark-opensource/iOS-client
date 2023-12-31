//
//  PNGHelper.swift
//  TestTile
//
//  Created by 吴珂 on 2020/9/14.
//  Copyright © 2020 bytedance. All rights reserved.


import Foundation
import libpng
import SKFoundation

class PNGHelper {
    static let helper = PNGHelper()
    
    var pngPtr: png_structp?
    var infoPtr: png_infop?
    
    private var imageWidth: UInt32 = 0
    private var imageHeight: UInt32 = 0
    private var filePtr: UnsafeMutablePointer<FILE>?
    private(set) var filePath: SKFilePath = SKFilePath(absPath: "")
    private var didWritePixels = false
    private var compressLevel: Int32 = 3 {
        didSet {
            compressLevel = min(max(1, compressLevel), 9)
        }
    }
    var imageURL: URL {
        return URL(fileURLWithPath: filePath.pathString)
    }
    
    func initialize(width: UInt32, height: UInt32, compressLevel: Int32, fileName: String?) -> Bool {
        self.filePath = generateTempFilePath(fileName: fileName)
        self.compressLevel = compressLevel
        imageWidth = width
        imageHeight = height
        
        return prepare()
    }
}

// MARK: png写入
extension PNGHelper {
    
    func fileRootPath() -> SKFilePath {
        let temPath = SKFilePath.globalSandboxWithTemporary.appendingRelativePath("pngHelper")
        return temPath
    }
    
    private func generateTempFilePath(fileName: String?) -> SKFilePath {
        let folder = fileRootPath()
        
        do {
            try folder.createDirectoryIfNeeded(withIntermediateDirectories: true)
        } catch {
            DocsLogger.info("longPic create folder failed")
        }
        
        let uniqueId = UUID().uuidString
        if let fileName = fileName {
            return folder.appendingRelativePath(fileName + uniqueId + ".png")
        }
        return folder.appendingRelativePath(uniqueId + ".png")
    }
       
    func openFile(path: SKFilePath) -> Bool {
        filePtr = fopen(path.pathString, "wb")
        
        if filePtr == nil {
            let uniqueId = UUID().uuidString
            filePath = fileRootPath().appendingRelativePath(uniqueId + ".png")
            filePtr = fopen(filePath.pathString, "wb")
            guard filePtr != nil else {
                return false
            }
        }
        return true
    }
    
    private func prepare() -> Bool {
        if filePtr != nil {
            fclose(filePtr)
            filePtr = nil
        }
        
        guard openFile(path: filePath) else {
            DocsLogger.info("longPic 文件创建失败")
            return false
        }
        
        guard imageWidth != 0, imageHeight != 0 else {
            DocsLogger.info("longPic 图片宽高异常")
            return false
        }
        
        guard let pngPtr = png_create_write_struct(PNG_LIBPNG_VER_STRING, nil, nil, nil) else {
            DocsLogger.info("longPic pngPtr创建失败")
            return false
        }
        self.pngPtr = pngPtr
        
        guard let infoPtr = png_create_info_struct(pngPtr) else {
            DocsLogger.info("longPic pngPtr创建失败")
            return false
        }
        
        self.infoPtr = infoPtr
        
        
        png_init_io(pngPtr, filePtr)
        
        png_set_IHDR(pngPtr,
                     infoPtr,
                     imageWidth,
                     imageHeight,
                     8,
                     PNG_COLOR_TYPE_RGBA,
                     PNG_INTERLACE_NONE,
                     PNG_COMPRESSION_TYPE_BASE,
                     PNG_FILTER_TYPE_BASE)
        
        png_set_compression_level(pngPtr, self.compressLevel)
        png_set_compression_strategy(pngPtr, 0)
        
        png_set_filter(pngPtr, 0, PNG_FILTER_NONE)
        
        png_write_info(pngPtr, infoPtr)
        png_set_compression_level(self.pngPtr, Int32(compressLevel))
        
        return true
    }
    
    func writeRow(_ rowPtr: UnsafeMutablePointer<UInt8>) {
        png_write_row(self.pngPtr, rowPtr)
        didWritePixels = true
    }
    
    func flush() {
        png_write_flush(self.pngPtr)
    }
    
    func finish() {
        freeResource()
    }
    
    func getFileSize() -> UInt64 {
        var fileSize: UInt64 = 0
        do {
            fileSize = (filePath.fileSize ?? 0) / 1024
            DocsLogger.info("longPic file size: \(fileSize)kb")
        } catch {
            DocsLogger.info("longPic read file size failed")
        }
        return fileSize
    }
    
    private func freeResource() {
        DocsLogger.info("longPic free resource")
        
        if !didWritePixels {
            let fakePixels = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(imageWidth) * 4)
            writeRow(fakePixels)
            flush()
            fakePixels.deallocate()
        } else {
            png_write_end(self.pngPtr, self.infoPtr)
        }
        
        png_destroy_write_struct(&self.pngPtr, &self.infoPtr)
        if let filePtr = filePtr {
            fclose(filePtr)
        }
    }
    
    func cancel() {
        freeResource()
    }
    
    func freeCache() {
        do {
            try filePath.removeItem()
        } catch {
            DocsLogger.info("\(error.localizedDescription)")
        }
        
    }
}

// MARK: 读取png信息
extension PNGHelper {
    func readIHDR(_ path: String) -> CGSize? {
        var width: png_uint_32 = 0
        var height: png_uint_32 = 0
        var fp1: UnsafeMutablePointer<FILE>?
        
        fp1 = fopen(path.cString(using: .utf8), "rb")
        
        guard let fp = fp1 else {
            DocsLogger.info("png helper 文件读取失败")
            return nil
        }
        
        guard let pngPtr = png_create_read_struct(PNG_LIBPNG_VER_STRING,
                                                   nil, nil, nil) else {
                                                    fclose(fp)
                                                    DocsLogger.info("png helper read failed")
                                                    return nil
        }
        self.pngPtr = pngPtr
        
        guard let infoPtr = png_create_info_struct(pngPtr) else {
            fclose(fp)
            png_destroy_read_struct(&self.pngPtr, nil, nil)
            DocsLogger.info("png helper read failed")
            return nil
        }
        
        self.infoPtr = infoPtr
        png_init_io(pngPtr, fp1)
        png_read_info(pngPtr, infoPtr)
        png_get_IHDR(pngPtr, infoPtr, &width, &height, nil, nil, nil, nil, nil)
        
        png_destroy_read_struct(&self.pngPtr, &self.infoPtr, nil)
        fclose(fp)
        return CGSize(width: CGFloat(width), height: CGFloat(height))
    }
}
