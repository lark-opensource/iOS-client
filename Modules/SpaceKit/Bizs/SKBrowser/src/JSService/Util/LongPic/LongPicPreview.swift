//
//  LongPicPreview.swift
//  TestTile
//
//  Created by 吴珂 on 2020/9/9.
//  Copyright © 2020 bytedance. All rights reserved.


import Foundation
import UIKit
import LarkStorage
import SKFoundation

protocol TileLayerDataSource: AnyObject {
    func image(_ delegate: TileLayerDelegate) -> UIImage?
}

class TileLayerDelegate: NSObject, CALayerDelegate {
    weak var dataSource: TileLayerDataSource?
    var image: UIImage?
    var cropHelper: PNGCropHelper?
    
    func draw(_ layer: CALayer, in ctx: CGContext) {
        let bounds = ctx.boundingBoxOfClipPath
        guard let layer = layer as? CATiledLayer else {
            return
        }
        
        let x = floor(bounds.origin.x / layer.tileSize.width)
        let y = floor(bounds.origin.y / layer.tileSize.height)
        
        autoreleasepool {
            if let image = cropHelper?.getImage(x: UInt32(x), y: UInt32(y)) {
                autoreleasepool {
                    UIGraphicsPushContext(ctx)
                    image.draw(in: bounds)
                    UIGraphicsPopContext()
                }
            }
        }
    }
}


protocol LongPicAnimationViewProtocol: UIView {
    func startAnimating()
    func stopAnimating()
    func setColor(_ color: UIColor)
}

extension LongPicAnimationViewProtocol {
    func setColor(_ color: UIColor) {}
}

extension UIActivityIndicatorView: LongPicAnimationViewProtocol {
    func setColor(_ color: UIColor) {
        self.color = color
    }
}

protocol LongPicPreviewDelegate: AnyObject {
    func animationView(_ preview: LongPicPreview) -> LongPicAnimationViewProtocol
    func loadImageFailed(_ preview: LongPicPreview)
    func didLoadFirstFrame(_ preview: LongPicPreview)
}

class LongPicPreview: UIView {
    private var miniumSizeToUseTileMode: CGFloat = 10 //图像超过xx兆才使用tile的方式显示
    private var loadingView: LongPicAnimationViewProtocol?
    private let tileSize: CGFloat = 2048
    private var cropHelper: PNGCropHelper?
    private var scrollView = UIScrollView()
    private var wrapperView = UIImageView()
    private var imagePath: SKFilePath
    private var image: UIImage?
    private var tileLayer: CATiledLayer
    private var layerDelegateProxy: TileLayerDelegate?
    private var fitScale: CGFloat = 0
    private var imageSize: CGSize = .zero
    
    private var maxVisibleHeight: CGFloat {
        let baseHeight: CGFloat = 6000
        return UIDevice.current.userInterfaceIdiom == .pad ? baseHeight * 1.5 : baseHeight
    }
    
    weak var delegate: LongPicPreviewDelegate?
    
    private lazy var doubleTap: UITapGestureRecognizer = {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(gesture:)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.numberOfTouchesRequired = 1
        doubleTap.delegate = self
        return doubleTap
    }()
    
    override var frame: CGRect {
        didSet {
            super.frame = frame
            bounds = CGRect(origin: .zero, size: frame.size)
        }
    }
    //目前只支持url，避免获取图像pixel时出现oom的问题
    init(_ path: SKFilePath, delegate: LongPicPreviewDelegate?) {
        tileLayer = CATiledLayer()
        self.imagePath = path
        self.delegate = delegate
        super.init(frame: .zero)
        
        if let image = try? UIImage.read(from: path) {
            self.image = image
        } else {
            DocsLogger.error("can not get image from url")
        }
        commonInit()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setMaxMinZoomScalesForCurrentBounds()
        updateDefaultScale()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func commonInit() {
        tileLayer.contentsGravity = .resizeAspect
        wrapperView.contentMode = .scaleAspectFit
        scrollView.addGestureRecognizer(doubleTap)
        
        let path = self.imagePath.pathString
        
        var useTileLayer = true
        if let size = PNGHelper.helper.readIHDR(path) {
            imageSize = size
            let pixels = size.width * size.height * 4 / 1024.0 / 1024.0
            useTileLayer = pixels > miniumSizeToUseTileMode
            self.scrollView.delegate = self
            self.scrollView.bounces = false
            self.scrollView.bouncesZoom = false
            self.scrollView.contentSize = size
            if useTileLayer {
                cropHelper = PNGCropHelper(UInt32(tileSize))
                cropHelper?.delegate = self
                cropHelper?.cropImage(path)
                layerDelegateProxy = TileLayerDelegate()
                layerDelegateProxy?.cropHelper = cropHelper
                layerDelegateProxy?.dataSource = self
                tileLayer.tileSize = CGSize(width: tileSize, height: tileSize)
                tileLayer.delegate = layerDelegateProxy
                tileLayer.backgroundColor = UIColor.clear.cgColor
                tileLayer.frame = CGRect(origin: .zero, size: size)
            } else {
                self.wrapperView.image = image
                self.delegate?.didLoadFirstFrame(self)
            }
            wrapperView.frame = CGRect(origin: .zero, size: size)
            addSubview(scrollView)
            scrollView.addSubview(wrapperView)
            
            scrollView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
        
        self.wrapperView.layer.addSublayer(self.tileLayer)
        self.tileLayer.setNeedsDisplay()
        
        if useTileLayer {
            if let animationView = delegate?.animationView(self) {
                loadingView = animationView
            } else {
                loadingView = UIActivityIndicatorView()
            }
            
            if let loadingView = loadingView {
                loadingView.setColor(UIColor.cyan)
                loadingView.startAnimating()
                addSubview(loadingView)
                loadingView.snp.makeConstraints { (make) in
                    make.center.equalToSuperview()
                }
            }
        }
        
        createDownsample()
    }
    
    private func downsampleImage(path: SKFilePath, maxPixelSize: CGFloat) -> UIImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithURL(path.pathURL as CFURL, sourceOptions) else {
            
            return nil
        }
        
        let downsampleOptions = [kCGImageSourceCreateThumbnailFromImageAlways: true,
                                 kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
                                 kCGImageSourceShouldCacheImmediately: true,
                                 kCGImageSourceCreateThumbnailWithTransform: true] as CFDictionary
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions) else {

            return nil
        }
        return  UIImage(cgImage: downsampledImage)
    }
    
    
    private func setMaxMinZoomScalesForCurrentBounds() {
        let boundsSize = bounds.size
        
        let xScale = boundsSize.width / imageSize.width
        let yScale = boundsSize.height / imageSize.height
        var minScale = min(xScale, yScale)
        let maxScale: CGFloat = 5.0
        
        if minScale > maxScale {
            minScale = maxScale
        }
        
        scrollView.maximumZoomScale = maxScale
        scrollView.minimumZoomScale = minScale
        
        if scrollView.minimumZoomScale > scrollView.zoomScale {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: false)
        }
    }

    private func updateDefaultScale() {
        self.scrollView.zoomScale = bounds.width / imageSize.width
        fitScale = self.scrollView.zoomScale
    }
    
    private func createDownSampleCore() {
        let previewImage = self.downsampleImage(path: self.imagePath, maxPixelSize: 10000)
        if previewImage != nil {
            DispatchQueue.main.async {
                self.wrapperView.image = previewImage
            }
        }
    }
    
    private func createDownsample() {
        DispatchQueue.global().async {
            if #available(iOS 13.0, *) {
                self.createDownSampleCore()
            } else {
                //大图且内存过小时，不创建缩略图
                let isAHugeImage = self.imageSize.width * self.imageSize.height * 4 / CGFloat(150000000.0) > 1 ? true : false
                if !isAHugeImage || Double(ProcessInfo.processInfo.physicalMemory) / 1073741824.0 > 1.5 {
                    self.createDownSampleCore()
                }
            }
        }
    }
    
    deinit {
        cropHelper?.cancel()
        cropHelper?.clearResources()
    }
}

extension LongPicPreview: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return wrapperView
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        var offsetX = (scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5
        offsetX = offsetX > 0 ? offsetX : 0
        var offsetY = (scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5
        offsetY = offsetY > 0 ? offsetY : 0
        wrapperView.center = CGPoint(x: offsetX + scrollView.contentSize.width * 0.5,
                                   y: offsetY + scrollView.contentSize.height * 0.5)
        
        let imageVisibleHeight = (scrollView.bounds.size.height / scrollView.zoomScale)
        self.tileLayer.isHidden = imageVisibleHeight > maxVisibleHeight
        if imageVisibleHeight > maxVisibleHeight {
            wrapperView.backgroundColor = wrapperView.image == nil ? UIColor.ud.G50 : UIColor.ud.N00
        } else {
            wrapperView.backgroundColor = UIColor.ud.N00
        }
        self.tileLayer.layoutIfNeeded()
    }
}

extension LongPicPreview {
    override func draw(_ layer: CALayer, in ctx: CGContext) {
        if layer == self.layer {
            super.draw(layer, in: ctx)
            return
        }
        let bounds = ctx.boundingBoxOfClipPath
        if let image = self.image, let layer = layer as? CATiledLayer {
            let x = floor(bounds.origin.x / layer.tileSize.width)
            let y = floor(bounds.origin.y / layer.tileSize.height)
            let pointX = x * layer.tileSize.width
            let pointY = y * layer.tileSize.height
            let point = CGPoint(x: pointX, y: pointY)
            autoreleasepool {
                if let tileImageRef = image.cgImage?.cropping(to: CGRect(origin: point, size: layer.tileSize)) {
                    let tileImage = UIImage(cgImage: tileImageRef)
                    UIGraphicsPushContext(ctx)
                    tileImage.draw(in: bounds)
                    UIGraphicsPopContext()
                }
            }
        }
    }
}

extension LongPicPreview: TileLayerDataSource {
    func image(_ delegate: TileLayerDelegate) -> UIImage? {
        return image
    }
}


// MARK: - UIGestureRecognizerDelegate
extension LongPicPreview: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

//手势处理
extension LongPicPreview {
    @objc
    private func handleDoubleTap(gesture: UITapGestureRecognizer) {
        if scrollView.zoomScale == fitScale {
            scrollView.zoom(to: zoomRectForScale(scale: 3, center: gesture.location(in: wrapperView)), animated: true)
        } else {
            scrollView.zoom(to: zoomRectForScale(scale: fitScale, center: gesture.location(in: wrapperView)), animated: true)
        }
    }
    
    func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
       var zoomRect = CGRect.zero
       zoomRect.size.height = bounds.size.height / scale
       zoomRect.size.width = bounds.size.width / scale
       zoomRect.origin.x = center.x - (zoomRect.size.width / 2.0)
       zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0)
       return zoomRect
    }
}

extension LongPicPreview: PNGCropHelperDelegate {
    func didGenerateOneImage(_ helper: PNGCropHelper, _ y: Int32) {
        self.delegate?.didLoadFirstFrame(self)
        hideIndicatorIfNeeded()
    }
    
    func didFinishCropImage(_ helper: PNGCropHelper) {
        hideIndicatorIfNeeded()
    }
    
    func didCancelled(_ helper: PNGCropHelper) {
        
    }
    
    func cropFailed(_ helper: PNGCropHelper) {
        delegate?.loadImageFailed(self)
    }
    
    
    func hideIndicatorIfNeeded() {
        DispatchQueue.main.async {
            self.tileLayer.setNeedsDisplay()
            self.loadingView?.stopAnimating()
            self.loadingView?.isHidden = true
        }
    }
}
