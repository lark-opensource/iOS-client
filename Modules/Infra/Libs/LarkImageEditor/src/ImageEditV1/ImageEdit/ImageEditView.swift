//
//  ImageEditView.swift
//  LarkUIKit
//
//  Created by ChalrieSu on 2018/9/30.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import RxSwift
import LarkExtensions

// swiftlint:disable identifier_name
let MosaicMinLineWidth: Float = 9
let MosaicMaxLineWidth: Float = 21

let AddLineMinLineWidth: Float = 2
let AddLineMaxLineWidth: Float = 10

protocol ImageEditViewDelegate: AnyObject {
    func imageEditView(_ imageEditView: ImageEditView, didChangeTo function: BottomPanelFunction)
}

final class ImageEditView: UIView {
    weak var delegate: (ImageEditAddLineViewDelegate &
        ImageEditAddMosaicViewDelegate &
        ImageEditAddTextViewDelegate &
        ImageEditViewDelegate)? {
        didSet {
            addLineView.delegate = delegate
            addMosaicView.delegate = delegate
            addTextView.delegate = delegate
        }
    }

    override var transform: CGAffineTransform {
        didSet {
            addMosaicView.externScale = transform.a
            addLineView.externScale = transform.a
        }
    }

    weak var zoomScrollView: ZoomScrollView? {
        didSet {
            addMosaicView.zoomView = zoomScrollView
            addLineView.zoomView = zoomScrollView
            addTextView.zoomView = zoomScrollView
        }
    }

    private(set) var showRect: CGRect
    let originalImage: UIImage

    let addMosaicView: ImageEditAddMosaicView
    let addLineView: ImageEditAddLineView
    let addTextView: ImageEditAddTextView
    private let containerView: ImageEditContainerView
    private var editViews: [ImageEditBaseView] {
        return [addMosaicView, addLineView, addTextView]
    }

    private var _imageUndoManager: UndoManager?
    var imageUndoManager: UndoManager? {
        if _imageUndoManager == nil {
            _imageUndoManager = undoManager
        }
        return _imageUndoManager
    }

    init(image: UIImage,
         imageEditEventSubject: PublishSubject<ImageEditEvent>,
         smartMosaicStateObservable: Observable<SmartMosaicState>) {
        self.originalImage = image
        showRect = CGRect(origin: .zero, size: originalImage.size)

        self.addMosaicView = ImageEditAddMosaicView(image: originalImage,
                                                    lineWidth: (MosaicMinLineWidth + MosaicMaxLineWidth) / 2,
                                                    smartMosaicStateObservable: smartMosaicStateObservable)
        self.addLineView = ImageEditAddLineView(lineWidth: CGFloat((AddLineMinLineWidth + AddLineMaxLineWidth) / 2))
        self.addTextView = ImageEditAddTextView(imageEditEventSubject: imageEditEventSubject)
        self.containerView = ImageEditContainerView(image: originalImage,
                                                    editViews: [addMosaicView, addLineView, addTextView])

        super.init(frame: .zero)

        clipsToBounds = true

        addSubview(containerView)

        editViews.forEach { $0.imageUndoManager = { [weak self] in
                return self?.imageUndoManager
            }
        }
    }

    deinit {
        imageUndoManager?.removeAllActions()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // 图片是否发生过编辑
    func imageEdited() -> Bool {
        var result = false
        result = result || !self.addLineView.lines.isEmpty
        result = result || !self.addTextView.labels.isEmpty
        result = result || !self.addMosaicView.paths.isEmpty
        result = result || self.showRect != CGRect(origin: .zero, size: originalImage.size)
        return result
    }

    func compositeImage() -> UIImage? {
        if let newSize = zoomScrollView?.fit(width: originalImage.size.width, height: originalImage.size.height).size {
            let originalRect = containerView.frame
            containerView.frame = CGRect(origin: .zero, size: newSize)
            containerView.layoutIfNeeded()
            containerView.removeFromSuperview()
            // screenshot() method will trigger layoutsubview through it's superview on iOS 13.
            // To avoid this, remove containerView from superview temporarily.
            let image = containerView.lu.screenshot()
            addSubview(containerView)
            containerView.frame = originalRect
            return image
        } else {
            return containerView.lu.screenshot()
        }
    }

    func set(showRect: CGRect) {
        self.showRect = showRect
        bounds = CGRect(x: 0, y: 0, width: showRect.width, height: showRect.height)
        setNeedsLayout()
    }

    var currentFunction: BottomPanelFunction = BottomPanelFunction.default {
        didSet {
            func active(view: ImageEditBaseView, in views: [ImageEditBaseView]) {
                views.forEach { (v) in
                    if v !== view {
                        v.becomeDeactive()
                    }
                }
                view.becomeActive()
            }

            let views = [addTextView, addMosaicView, addLineView]

            switch currentFunction {
            case .line:
                active(view: addLineView, in: views)
            case .mosaic:
                active(view: addMosaicView, in: views)
            case .text:
                active(view: addTextView, in: views)
            case .trim:
                break
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let scale = bounds.width / showRect.width
        let newOrigin = CGPoint(x: -showRect.minX * scale,
                                y: -showRect.minY * scale)
        let newSize = originalImage.size * scale

        containerView.frame = CGRect(origin: newOrigin, size: newSize)
        containerView.layoutIfNeeded()
    }

    func becomeDeactive() {
        editViews.forEach { (view) in
            view.becomeDeactive()
        }
    }

    func panGestureInvoke(gesture: UIPanGestureRecognizer) {
        switch currentFunction {
        case .line:
            addLineView.panGestureDidInvoke(gesture: gesture)
        case .mosaic:
            addMosaicView.panDidInvoked(gesture)
        case .text:
            addTextView.panDidInvoked(gesture)
        case .trim:
            break
        }
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let convertedPoint = convert(point, to: addTextView)
        if !addTextView.isActive, addTextView.canHandle(point: convertedPoint) {
            currentFunction = .text
            addTextView.unhighlightAllLabels()
            delegate?.imageEditView(self, didChangeTo: .text)
            return addTextView.hitTest(point, with: event)
        }
        return super.hitTest(point, with: event)
    }
}

private class ImageEditContainerView: UIView {
    private let originalImageView = UIImageView()
    private let editViews: [ImageEditBaseView]

    init(image: UIImage?, editViews: [ImageEditBaseView]) {
        self.editViews = editViews
        super.init(frame: .zero)

        backgroundColor = .clear

        originalImageView.image = image
        originalImageView.contentMode = .scaleAspectFit
        originalImageView.isUserInteractionEnabled = true
        addSubview(originalImageView)
        originalImageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        editViews.forEach { (view) in
            addSubview(view)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        editViews.forEach { (view) in
            if view.bounds.width * view.bounds.height == 0 {
                view.frame = bounds
            } else {
                view.transform = .identity
                let scale = bounds.width / view.bounds.width
                view.transform = CGAffineTransform(scaleX: scale, y: scale)
                view.frame.origin = .zero
            }
        }
    }
}
// swiftlint:enable identifier_name
