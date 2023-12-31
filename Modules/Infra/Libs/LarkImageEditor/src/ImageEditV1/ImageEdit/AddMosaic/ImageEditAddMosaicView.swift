//
//  ImageEditAddMosaicView.swift
//  LarkUIKit
//
//  Created by ChalrieSu on 2018/8/5.
//  Copyright © 2018 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import ServerPB
import UniverseDesignToast

// swiftlint:disable identifier_name

protocol ImageEditAddMosaicViewDelegate: AnyObject {
    func addMosaicViewDidTapped(_ addMosaicView: ImageEditAddMosaicView)
    func addMosaicViewDidBeginToDraw(_ addMosaicView: ImageEditAddMosaicView)
    func addMosaicViewDrawing(_ addMosaicView: ImageEditAddMosaicView)
    func addMosaicViewDidFinishDrawing(_ addMosaicView: ImageEditAddMosaicView)
}

final class ImageEditAddMosaicView: ImageEditBaseView {
    weak var delegate: ImageEditAddMosaicViewDelegate?

    var smartMosaicResponse: SmartMosaicResponse? {
        didSet {
            DispatchQueue.global().async { [weak self] in
                guard let self = self else {
                    return
                }
                while !self.hasMosaicImage {}
                while !self.hasGaussanImage {}
                guard let gaussanImage = self.GaussanImage,
                      let mosaicImage = self.mosaicImage,
                      let polygons = self.smartMosaicResponse?.polygons else {
                    return
                }

                self.ocrGuassanImage = UIImage()
                self.ocrMosaicImage = UIImage()
                // No mosaic area is detected, do not generate the mosaic image to save resources
                if !polygons.isEmpty {
                    let path = UIBezierPath()
                    let targetSize = gaussanImage.size
                    for polygon in polygons {
                        // It's quadrilateral
                        let textArea = OcrTextArea(polygon: polygon,
                                                   originalSize: self.image.pixelSize(),
                                                   scaledTo: targetSize)
                        path.append(textArea.getBezierPath())
                    }
                    self.ocrGuassanImage = UIImage.shapeImageWithBezierPath(bezierPath: path,
                                                                            size: gaussanImage.size,
                                                                            fillColor: UIColor(patternImage:
                                                                                                gaussanImage))
                    self.ocrMosaicImage = UIImage.shapeImageWithBezierPath(bezierPath: path,
                                                                           size: mosaicImage.size,
                                                                           fillColor: UIColor(patternImage:
                                                                                                mosaicImage))
                }
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else {
                        return
                    }
                    self.stopScanAnimation()
                    self.showNoTextHintIfNeeded()
                }
            }
        }
    }

    private(set) var paths: [ImageEditMosaicBezierPath] = [] {
        didSet {
            if !paths.isEmpty {
                hasEverOperated = true
            }
        }
    }

    private var removeMosaicButton: UIButton = {
        let button = UIButton()
        button.setImage(Resources.edit_mosaic_close, for: .normal)
        button.isHidden = true
        return button
    }()

    private var mosaicType: MosaicType
    private var selectionType: SelectionType
    private var smartMosaicState = SmartMosaicState.loading
    private var lineWidth: Float
    private var image: UIImage
    private var currentPath: ImageEditMosaicBezierPath?

    var externScale: CGFloat = 1
    private var currentScale: CGFloat { return transform.a }

    private let disposeBag = DisposeBag()

    init(image: UIImage, lineWidth: Float, smartMosaicStateObservable: Observable<SmartMosaicState>) {
        self.image = image.lu.fixOrientation()
        self.mosaicType = MosaicType.default
        self.selectionType = SelectionType.default
        self.lineWidth = lineWidth
        super.init(frame: CGRect.zero)
        addSubview(removeMosaicButton)
        removeMosaicButton.addTarget(self, action: #selector(closeButtonDidTap), for: .touchUpInside)
        backgroundColor = .clear
        let panGesture = ImageEditPanGestureRecognizer(target: self, action: #selector(panDidInvoked))
        panGesture.maximumNumberOfTouches = 1
        addGestureRecognizer(panGesture)
        lu.addTapGestureRecognizer(action: #selector(tapGestureDidInvoke(gesture:)), target: self)

        smartMosaicStateObservable.observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (state) in
            self?.updateSmartMosaicState(state)
        }).disposed(by: disposeBag)
    }

    private var currentBounds: CGRect = .zero
    override var bounds: CGRect {
        didSet {
            currentBounds = bounds
        }
    }

    override var frame: CGRect {
        didSet {
            currentBounds = bounds

            // 当mosaicview布局好了以后，异步线程触发一下生成蒙层的方法
            if frame != .zero {
                DispatchQueue.global().async {
                    _ = self.mosaicImage
                    _ = self.GaussanImage
                }
            }
        }
    }

    private var thumNailImage: UIImage? {
        if _thumNailImage == nil {
            _thumNailImage = image.lu.scale(toSize: currentBounds.size)
        }
        return _thumNailImage
    }

    private var _thumNailImage: UIImage?

    private lazy var mosaicImage: UIImage? = {
        defer {
            hasMosaicImage = true
        }
        if let thumbnailImage = thumNailImage,
            let pixelFilter = CIFilter(name: "CIPixellate"),
            let inputImage = CIImage(image: thumbnailImage) {
            pixelFilter.setValue(inputImage, forKey: kCIInputImageKey)
            pixelFilter.setValue(25, forKey: kCIInputScaleKey)

            // Image are not perfectly filled, see: https://stackoverflow.com/questions/15425437/cipixellate-image-output-size-varies
            if let pixelImage = pixelFilter.outputImage {
                let context = CIContext(options: nil)
                if let cgImage = context.createCGImage(pixelImage, from: inputImage.extent) {
                    let size = CGSize(width: currentBounds.size.width, height: currentBounds.size.height)
                    return UIImage(cgImage: cgImage).lu.scale(toSize: currentBounds.size)
                }
            }
        }
        return nil
    }()

    private var hasMosaicImage: Bool = false

    lazy var GaussanImage: UIImage? = {
        defer {
            hasGaussanImage = true
        }
        if let thumbnailImage = thumNailImage,
            let clampFilter = CIFilter(name: "CIAffineClamp"),
            let inputImage = CIImage(image: thumbnailImage) {
            clampFilter.setDefaults()
            clampFilter.setValue(inputImage, forKey: kCIInputImageKey)

            let blur = CIFilter(name: "CIGaussianBlur")!
            blur.setValue(clampFilter.outputImage, forKey: kCIInputImageKey)
            blur.setValue(25, forKey: kCIInputRadiusKey)

            if let blurImage = blur.outputImage {
                let context = CIContext(options: nil)
                if let cgImage = context.createCGImage(blurImage, from: inputImage.extent) {
                    return UIImage(cgImage: cgImage).lu.scale(toSize: currentBounds.size)
                }
            }
        }
        return nil
    }()

    private var hasGaussanImage: Bool = false
    private var ocrGuassanImage: UIImage?
    private var ocrMosaicImage: UIImage?

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        var paths = self.paths
        if let currentPath = currentPath {
            paths.append(currentPath)
        }

        paths.forEach { (path) in
            getMosaicFillColor(mosaicType: path.mosaicType, selectionType: path.selectionType).set()
            path.lineJoinStyle = .round
            path.lineCapStyle = .round
            path.selectionType == .point ? path.stroke() : path.fill()
        }

        // Draw highlighted
        removeMosaicButton.isHidden = true
        if let path = paths.first(where: { $0.isHighlighted }) {
            path.scale = externScale * currentScale
            path.drawHighlightedBox()
            removeMosaicButton.isHidden = false
            removeMosaicButton.frame = path.getRemoveButtonFrame()
            removeMosaicButton.imageEdgeInsets = path.getRemoveButtonEdgeInsets()
        }
    }

    private func unHighlightAll() {
        paths.forEach { $0.isHighlighted = false }
        removeMosaicButton.isHidden = true
    }

    @objc
    private func closeButtonDidTap() {
        removeMosaicButton.isHidden = true
        if let path = paths.first(where: { $0.isHighlighted }) {
            removePath(path)
        }
        setNeedsDisplay()
    }

    @objc
    private func tapGestureDidInvoke(gesture: UITapGestureRecognizer) {
        // Highlight tapped rect
        var isRectFound = false
        self.unHighlightAll()
        let tapLocation = gesture.location(in: self)
        for path in paths.reversed() {
            if path.selectionType == .area,
               let rect = path.getRect(),
               rect.contains(tapLocation) {
                isRectFound = true
                path.isHighlighted = true
                break
            }
        }
        setNeedsDisplay()

        // Pass through tap event if no rect is found
        if !isRectFound {
            delegate?.addMosaicViewDidTapped(self)
        }
    }

    @objc
    func panDidInvoked(_ panGesture: UIPanGestureRecognizer) {
        guard let panGesture = panGesture as? ImageEditPanGestureRecognizer else {
            return
        }

        switch mosaicType {
        case .mosaic:
            while !hasMosaicImage {}
        case .Gaussan:
            while !hasGaussanImage {}
        }

        switch panGesture.state {
        case .began:
            self.unHighlightAll()
            currentPath = ImageEditMosaicBezierPath(mosaicType: mosaicType,
                                                    selectionType: selectionType,
                                                    scale: externScale * currentScale)
            currentPath?.lineWidth = CGFloat(lineWidth) / externScale / currentScale
            currentPath?.add(point: panGesture.initialTouchLocation ?? panGesture.location(in: self))
            delegate?.addMosaicViewDidBeginToDraw(self)
        case .changed:
            var location = panGesture.location(in: self)
            // make sure location is inside the view
            location.x = min(max(location.x, bounds.minX), bounds.maxX)
            location.y = min(max(location.y, bounds.minY), bounds.maxY)
            currentPath?.add(point: location)
            setNeedsDisplay()
            delegate?.addMosaicViewDrawing(self)
        case .possible:
            break
        case .cancelled, .ended, .failed:
            if let newPath = currentPath {
                currentPath = nil
                addPath(newPath)
                delegate?.addMosaicViewDidFinishDrawing(self)
            }
        @unknown default:
            break
        }
    }

    func updateLineWidth(_ lineWidth: CGFloat) {
        self.lineWidth = Float(lineWidth)
    }

    func updateMosaicType(_ type: MosaicType) {
        self.mosaicType = type
    }

    func updateSelectionType(_ type: SelectionType) {
        self.selectionType = type
        type == .point ? stopScanAnimation() : startScanAnimationIfNeeded()
        self.showNoTextHintIfNeeded()
    }

    private func updateSmartMosaicState(_ state: SmartMosaicState) {
        smartMosaicState = state
        switch state {
        case .loading:
            startScanAnimationIfNeeded()
        case .fail:
            if selectionType == .area && isActive {
                UDToast.showFailure(with: BundleI18n.LarkImageEditor.Lark_ASL_OCRFail,
                                       on: self.superview ?? self)
            }
            stopScanAnimation()
        case .ready:
            // Do not stop scan animation before ocrMosaicImage is ready
            break
        }
    }

    private func showNoTextHintIfNeeded() {
        if selectionType != .area || !isActive {
            return
        }

        if let polygons = self.smartMosaicResponse?.polygons,
           polygons.isEmpty {
            UDToast.showFailure(with: BundleI18n.LarkImageEditor.Lark_ASL_NoTextOrPhotoRecognized,
                                   on: self.superview ?? self)
        }
    }

    private func startScanAnimationIfNeeded() {
        if selectionType != .area || !isActive {
            return
        }
        if smartMosaicState == .loading ||
            (smartMosaicState == .ready && (ocrGuassanImage == nil || ocrMosaicImage == nil)) {
            isUserInteractionEnabled = false
            startImageScanAnimation()
        }
    }

    private func stopScanAnimation() {
        isUserInteractionEnabled = true
        stopImageScanAnimation()
    }

    private func getMosaicFillColor(mosaicType: MosaicType, selectionType: SelectionType) -> UIColor {
        var image: UIImage?
        if mosaicType == .mosaic {
            image = (selectionType == .point) ? mosaicImage : ocrMosaicImage
        } else {
            image = (selectionType == .point) ? GaussanImage : ocrGuassanImage
        }
        return image.flatMap { UIColor(patternImage: $0) } ?? UIColor.clear
    }

    @objc
    private func addPath(_ line: ImageEditMosaicBezierPath) {
        paths.append(line)
        setNeedsDisplay()
        imageUndoManager()?.registerAndNotifyUndo(withTarget: self, handler: { (target) in
            target.removePath(line)
        })
    }

    @objc
    private func removePath(_ line: ImageEditMosaicBezierPath) {
        paths.removeAll(where: { $0 === line })
        setNeedsDisplay()
        imageUndoManager()?.registerAndNotifyUndo(withTarget: self, handler: { (target) in
            target.addPath(line)
        })
    }

    override func becomeActive() {
        super.becomeActive()
        startScanAnimationIfNeeded()
    }

    override func becomeDeactive() {
        super.becomeDeactive()
        stopScanAnimation()
        unHighlightAll()
        setNeedsDisplay()
    }
}
// swiftlint:enable identifier_name

extension UIImage {
    class func shapeImageWithBezierPath(bezierPath: UIBezierPath, size: CGSize, fillColor: UIColor) -> UIImage {
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()
        var image = UIImage()
        if let context = context {
            context.saveGState()
            context.addPath(bezierPath.cgPath)
            fillColor.setFill()
            context.setStrokeColor(UIColor.clear.cgColor)
            context.drawPath(using: .fillStroke)
            if let generatedImage = UIGraphicsGetImageFromCurrentImageContext() {
                image = generatedImage
            }
            context.restoreGState()
            UIGraphicsEndImageContext()
        }
        return image
    }

    func pixelSize() -> CGSize {
        return CGSize(width: size.width * scale, height: size.height * scale)
    }
}
