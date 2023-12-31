//
//  WebViewExportPNGHelper.swift
//  TestLongPic
//
//  Created by 吴珂 on 2020/8/21.
//  Copyright © 2020 bytedance. All rights reserved.
//  swiftlint:disable cyclomatic_complexity line_length

import Foundation
import UIKit
import WebKit
import Photos
import SKFoundation
import libpng

protocol WebViewExportPNGHelperDelegate: AnyObject {
    func helperDidDrawImage(_: WebViewExportPNGHelper, context: CGContext, size: CGSize)
    func helperDidFinishExport(_: WebViewExportPNGHelper, isFinished: Bool, imagePath: SKFilePath)
    func exportFailed(_: WebViewExportPNGHelper)
}

class WebViewExportPNGHelper {
    let maxHeight: UInt32 = UInt32.max
    let scale: UInt32 = 2
    weak var webView: WKWebView?
    
    private var widthPerImage: UInt32 = 0
    private var heightPerImage: UInt32 = 0
    private var imageWidth: UInt32 = 0
    private var imageHeight: UInt32 = 0

    private var compressLevel: Int32 = 3 {
        didSet {
            compressLevel = min(max(1, compressLevel), 9)
        }
    }
    private var pngHelper = PNGHelper()
    private let millisecondsPerPage: MillisecondsPerPage
    
    private var originalImages: [(UInt32, UIImage, Bool, UnsafeMutablePointer<UInt8>?)] = []
    private var pixels: [(UInt32, UnsafeMutablePointer<UInt8>)] = []
    
    private var imagesLock: os_unfair_lock = os_unfair_lock()
    private var pixelsLock: os_unfair_lock = os_unfair_lock()
//    private var didCancelLock: os_unfair_lock = os_unfair_lock()
    private var isCancellingLock: os_unfair_lock = os_unfair_lock()
    private var snapIsFinishedLock: os_unfair_lock = os_unfair_lock()
    
    private var snapshotSemaphore: DispatchSemaphore = DispatchSemaphore(value: 1)
    private var scaleImageSemaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
    private var writePixelesSemaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
    lazy private var maxSnapshotPixelesSemaphore: DispatchSemaphore = DispatchSemaphore(value: 3)
    lazy private var cancelSemaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
    
    private lazy var snapshotQueue = DispatchQueue(label: "sk.longpic.generateImage.queue", qos: .default, attributes: .init(), autoreleaseFrequency: .never, target: nil)
    private lazy var writePixelsQueue = DispatchQueue(label: "sk.longpic.exportPixeles.queue", qos: .default, attributes: .init(), autoreleaseFrequency: .never, target: nil)
    private lazy var detectImageQueue = DispatchQueue(label: "sk.longpic.detectImage.queue", qos: .default, attributes: .init(), autoreleaseFrequency: .never, target: nil)
    
    private var maxRetryCount: UInt32 = 3
    private var detectValidColor: UInt32 = 0xFFFFFFFF
    
    private var snapShotTask = DispatchWorkItem {}
    
    lazy private var writePixelsTask = DispatchWorkItem {[weak self] in
        guard let self = self else {
            return
        }
        while !self.isCancelling {
            let writeTimeout = self.writePixelesSemaphore.wait(timeout: .now() + 10)
            guard writeTimeout == .success else {
                continue
            }
            os_unfair_lock_lock(&self.pixelsLock)
            let elaspedTime = Date.measure(prefix: "write elasped time ") {
                if let rowPointers = self.pixels.first {
                    self.pixels.removeFirst()
                    os_unfair_lock_unlock(&self.pixelsLock)
                    DocsLogger.info("longPic write index \(rowPointers.0)")
                    let bytesPerRow = self.widthPerImage * 4
                    for i in 0..<Int(self.heightPerImage) {
                        self.writeRow(rowPointers.1 + i * Int(bytesPerRow))
                    }
                    rowPointers.1.deallocate()
                    self.flush()
                } else {
                    os_unfair_lock_unlock(&self.pixelsLock)
                }
            }
            
            self.trackParams.insertWriteElaspedTime(elaspedTime)
            
            _ = self.maxSnapshotPixelesSemaphore.signal() //可以在加入一个
            let currentPixelsCount = self.pixels.count
            DocsLogger.info("longPic current pixels count in writePixelsItem: \(self.pixels.count)")
            os_unfair_lock_lock(&self.snapIsFinishedLock)
            var shouldBreak = false
            if self.isFinishedSnap == true && currentPixelsCount == 0 {
                self.writeIsFinished = true
                shouldBreak = true
                DocsLogger.info("longPic isFinishedWrite")
            }
            os_unfair_lock_unlock(&self.snapIsFinishedLock)
            if shouldBreak {
                break
            }
        }
        DocsLogger.info("longPic leave write")
        self.dispatchGroup.leave()
    }
    
    //状态控制
    private var isFinishedSnap = false
    private var isFinishedScale = false
    private var writeIsFinished = false
    private var isCancelling = false
    private var didCancelled = false
    private var isExporting = false
    
    public weak var delegate: WebViewExportPNGHelperDelegate?
    //埋点
    private var trackParams = LongPicMakeTracksParams()
    private(set) var imageCount = 0 // 用于埋点统计
    
    let dispatchGroup: DispatchGroup = DispatchGroup()
    
    lazy var decoratePerImageBlock: ((_ context: CGContext, _ in: CGSize) -> Void) = { (context, size) in
        self.delegate?.helperDidDrawImage(self, context: context, size: size)
    }
    
    init(compressLevel: Int32, millisecondsPerPage: MillisecondsPerPage = ._50) {
        self.detectValidColor = 0xFFFFFFFF
        self.compressLevel = compressLevel
        self.millisecondsPerPage = millisecondsPerPage
    }

    deinit {
        snapshotSemaphore.signal()
        writePixelesSemaphore.signal()
        maxSnapshotPixelesSemaphore.signal()
        cancelSemaphore.signal()
    }

    func exportPNGImage(webView: WKWebView, fileName: String?) {
        self.webView = webView
        if self.isExporting || self.didCancelled {//不可重用
            DocsLogger.info("longPic is exproting please try later")
            return
        }
        self.isExporting = true
        
        guard prepare(webView: webView, fileName: fileName) else {
            delegate?.exportFailed(self)
            return
        }
        generateImage(webView: webView)
        
        return
    }
    
    private func generateImage(webView: WKWebView) {
        let startDate = Date()
        let size = webView.bounds.size
        var imageCount = UInt32(CGFloat(imageHeight) / size.height)
        let heightPerPage = UInt32(size.height)
        imageCount = max(1, imageCount)
        let configuration = WKSnapshotConfiguration()
        configuration.snapshotWidth = NSNumber(value: getWebContentSnapshotWidth(webView))
        if #available(iOS 13, *) {
            configuration.afterScreenUpdates = true
        }
        
        //scrollToBottom
        for i in 0..<imageCount {
            let nextTop = CGFloat(i) * webView.bounds.size.height
            let nextRect = CGRect(x: 0, y: nextTop, width: size.width, height: size.height)
            webView.scrollView.scrollRectToVisible(nextRect, animated: false)
        }
        webView.scrollView.scrollRectToVisible(CGRect(x: 0, y: 0, width: size.width, height: size.height), animated: false)
        //restore image count
        imageCount = UInt32(ceil(webView.scrollView.contentSize.height / size.height))
        imageCount = max(1, imageCount)
        
        self.dispatchGroup.enter()
        writePixelsQueue.async(execute: writePixelsTask)
        
        dispatchGroup.notify(queue: DispatchQueue.main) {[weak self] in
            guard let self = self else {
                return
            }
            os_unfair_lock_lock(&self.isCancellingLock)
            if self.isCancelling {
                self.cancelSemaphore.signal()
                os_unfair_lock_unlock(&self.isCancellingLock)
                return
            }
            os_unfair_lock_unlock(&self.isCancellingLock)
            let totalElapsedTime = (Date().timeIntervalSince1970 - startDate.timeIntervalSince1970) * 1000
            let elaspedTimePerImage = totalElapsedTime / Double(imageCount)
            DocsLogger.info("longPic end elapsed time: \(totalElapsedTime)ms")
            DocsLogger.info("longPic elapsed time per image: \(elaspedTimePerImage)ms")
            DocsLogger.info("longPic 结束生成图片, 图片数：\(imageCount)")
            self.trackParams.imageCount = imageCount
            self.imageCount = Int(imageCount)
            self.trackParams.totalElaspedTime = totalElapsedTime
            self.finishWriteImage()
        }
        
        
        
        let snapShotItem = DispatchWorkItem {[weak self] in
            guard let self = self else {
                return
            }
            
            var i: UInt32 = 0
            
            var retryInfo: [UInt32: UInt32] = [:]
            for i in 0..<imageCount {
                retryInfo[i] = 0
            }
            
            while i < imageCount {
                if self.isCancelling {
                    DocsLogger.info("longPic snapshot Item cancelled befor take snapshot")
                    return
                }
                _ = self.snapshotSemaphore.wait(timeout: .now() + 10)
                let maxSnapshotResult = self.maxSnapshotPixelesSemaphore.wait(timeout: .now() + 10)
                
                guard maxSnapshotResult == .success else {
                    continue
                }
                
                if self.isCancelling {
                    DocsLogger.info("longPic snapshot Item cancelled before take snapshot")
                    return
                }
                
                if self.isFinishedSnap {
                    break
                }
                
                let useconds: Double = Double(self.millisecondsPerPage.rawValue) * 1000
                usleep(useconds_t(useconds))
                
                DispatchQueue.main.async {
                    DocsLogger.info("longPic inner\(i)")
                    if self.isCancelling {
                        DocsLogger.info("longPic snapshot Item cancelled before take snapshot")
                        return
                    }
                    
                    webView.takeSnapshot(with: configuration) { [self] (image, _) in
                        guard let image = image else {
                            return
                        }
                        
                        if self.isCancelling {
                            return
                        }
                        
                        self.detectImageQueue.async {
                            let isValid = self.imageIsValid(image)
                            
                            if !isValid.0, let retryCount = retryInfo[i], retryCount < self.maxRetryCount {
                                isValid.1?.deallocate()
                                DocsLogger.info("longPic retry \(i)")
                                retryInfo[i] = retryCount + 1
                                self.trackParams.increaseRetryCount()
                                DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_500) {
                                    self.snapshotSemaphore.signal()
                                    self.maxSnapshotPixelesSemaphore.signal()
                                }
                            } else {
                                
                                os_unfair_lock_lock(&self.pixelsLock)
                                if let pixels = isValid.1 {
                                    self.pixels.append((UInt32(i), pixels))
                                }
                                os_unfair_lock_unlock(&self.pixelsLock)
                                
                                
                                let targetOffsetY = (i + 1) * heightPerPage
                                let offset = CGPoint(x: 0, y: Int(targetOffsetY))
                                
                                DispatchQueue.main.async {
                                    webView.scrollView.contentOffset = offset
                                    os_unfair_lock_lock(&self.snapIsFinishedLock)
                                    i += 1
                                    self.isFinishedSnap = i - 1 == imageCount
                                    os_unfair_lock_unlock(&self.snapIsFinishedLock)
                                    self.snapshotSemaphore.signal()
                                    self.writePixelesSemaphore.signal()
                                }
                            }
                        }
                    }
                }
            }
        }
        snapShotTask = snapShotItem
        snapshotQueue.async(execute: snapShotTask)
    }
    
    var testCount: Int = 0
    func imageIsValid(_ image: UIImage) -> (Bool, UnsafeMutablePointer<UInt8>?) {
        var pixels: UnsafeMutablePointer<UInt8>?
        let elaspedTime = Date.measure(prefix: "longpic scale") { [weak self] in
            guard let self = self else { return }
            pixels = image.wk.scaleAndGetPixels(Int(scale), decorateBlock: self.decoratePerImageBlock, shouldDoDecorate: { _ in
                return true // 参考Android, 不检测白屏
            })
        }
        trackParams.insertExportPixelsElaspedTime(elaspedTime)
        
        return (true, pixels)
    }
    
    private func prepare(webView: WKWebView, fileName: String?) -> Bool {
        widthPerImage = getWebContentSnapshotWidth(webView) * scale
        heightPerImage = UInt32(webView.scrollView.bounds.size.height) * scale
        
        imageWidth = UInt32(webView.scrollView.contentSize.width) * scale
        imageHeight = min(UInt32(webView.scrollView.contentSize.height) * scale, maxHeight)
        DocsLogger.info("longPic image width: \(imageWidth) height: \(imageHeight) pixel size: \(imageWidth * imageHeight * 4 / 1024 / 1024 * scale)m, \(imageWidth * imageHeight * 4 / 1024 * scale ) kb ")
        return pngHelper.initialize(width: imageWidth, height: imageHeight, compressLevel: compressLevel, fileName: fileName)
    }
    
    private func getWebContentSnapshotWidth(_ webView: WKWebView) -> UInt32 {
        return UInt32(webView.scrollView.bounds.size.width)
    }
    
    private func writeRow(_ rowPtr: UnsafeMutablePointer<UInt8>) {
        pngHelper.writeRow(rowPtr)
    }
    
    private func flush() {
        pngHelper.flush()
    }
    
    private func freeResource() {
        self.originalImages.removeAll()
        
        for pixel in self.pixels {
            DocsLogger.info("longPic clear pixels")
            pixel.1.deallocate()
        }
        
        DocsLogger.info("longPic free resource")
    }
    
    private func finishWriteImage() {
        pngHelper.finish()
        
        trackParams.widthPerImage = widthPerImage
        trackParams.heightPerImage = heightPerImage
        trackParams.imageWidth = imageWidth
        trackParams.imageHeight = imageHeight
        trackParams.fileSize = pngHelper.getFileSize()

        self.isExporting = false
        self.webView?.scrollView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: false)
        self.delegate?.helperDidFinishExport(self, isFinished: !self.didCancelled, imagePath: pngHelper.filePath)
        // Deprecated, 现对齐Android端使用client_long_image_info
        DocsTracker.log(enumEvent: .clientGenerateLongImageV2, parameters: self.trackParams.params)
    }
    
    func cancel() {
        
        guard self.isExporting else {
            return
        }
        
        //cancel
        os_unfair_lock_lock(&self.isCancellingLock)
        guard !self.isCancelling, self.isExporting else {
            DocsLogger.info("longPic is cancelling or is not exporting, do not need cancel")
            os_unfair_lock_unlock(&self.isCancellingLock)
            return
        }
        DocsLogger.info("longPic cancelling...")
        self.isCancelling = true
        os_unfair_lock_unlock(&self.isCancellingLock)
        
        
        for _ in 0..<1 {
            snapshotSemaphore.signal()
            scaleImageSemaphore.signal()
            writePixelesSemaphore.signal()
        }
        
        DispatchQueue.global().async {
            let result = self.cancelSemaphore.wait(timeout: .now() + 3)
            
            if result == .timedOut {
                DocsLogger.info("取消超时")
                return
            }
            self.freeResource()
            DocsLogger.info("longPic cancel success.")
        }
    }
}

extension WebViewExportPNGHelper {
    /// 导出的图片尺寸，总的宽高
    var imageSize: CGSize {
        .init(width: CGFloat(imageWidth), height: CGFloat(imageHeight))
    }
    /// 导出的图片大小KB
    var imageFileSizeKB: Int {
        Int(pngHelper.getFileSize())
    }
}

extension WebViewExportPNGHelper {
    enum MillisecondsPerPage: Int {
        case _50 = 50
        case _300 = 300
    }
}
