//
//  OCRImageView.swift
//  LarkOCR
//
//  Created by 李晨 on 2022/8/29.
//

import UIKit
import Foundation
import ByteWebImage
import LKCommonsLogging

public protocol OCRImageViewDelegate: AnyObject {
    func ocrImageViewResultUpdate(boxex: [AnnotationBox], isFinish: Bool)
}

public final class OCRImageView: ByteImageView, UIGestureRecognizerDelegate {

    var tapGesture: UITapGestureRecognizer = UITapGestureRecognizer()
    var panGesture: PanGestureRecognizer = PanGestureRecognizer()

    weak var delegate: OCRImageViewDelegate?

    private var detector: AnnotationGestureDetector?

    private(set) var results: [AnnotationBox] = []

    public func showAnnotationLayer(config: AnnotationUIConfig) {
        let annotationLayer = OCRAnnotationShapeLayer(config: config)
        annotationLayer.frame = self.bounds
        annotationLayer.results = results
        self.annotationLayer = annotationLayer
        self.layer.addSublayer(annotationLayer)
    }

    public func hideAnnotationLayer() {
        self.annotationLayer?.removeFromSuperlayer()
        self.annotationLayer = nil
    }

    public var annotationLayer: OCRAnnotationShapeLayer?

    public func setResult(_ result: [AnnotationBox]) {
        self.results = result
        self.detector?.result = results
        self.updateResultIfNeeded()
    }

    public func addGestureTo(view: UIView) {
        self.detector?.addGestureTo(view: view)
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)

        detector = AnnotationGestureDetector(resultProvider: { [weak self] (boxes, finished) in
            self?.results = boxes
            self?.annotationLayer?.results = boxes
            self?.delegate?.ocrImageViewResultUpdate(boxex: boxes, isFinish: finished)
        })
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        self.annotationLayer?.frame = self.bounds
        self.updateResultIfNeeded()
    }

    private func updateResultIfNeeded() {
        guard let first = self.results.first,
            first.showImageSize != self.bounds.size else {
            return
        }
        var results = self.results
        for i in 0..<results.count {
            results[i].updatePathIfNeeded(showImageSize: self.bounds.size, radius: 2)
        }
        self.results = results
        self.detector?.result = results
    }
}
