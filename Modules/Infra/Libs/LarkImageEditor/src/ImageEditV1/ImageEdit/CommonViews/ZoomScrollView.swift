//
//  ZoomScrollView.swift
//  LarkUIKit
//
//  Created by ChalrieSu on 2018/7/30.
//  Copyright © 2018 liuwanlin. All rights reserved.
//

import Foundation
import UIKit

public final class ZoomScrollView: UIScrollView {
    var zoomView: UIView

    public var originSize: CGSize {
        didSet {
            relayoutZoomView()
        }
    }

    /// 如果zoomView发现点击事件在view内
    /// 则在hitTest方法中会优先返回这个view
    public var priorityView: UIView?

    /// 传入需要缩放的view，以及需要缩放view的originSize，生成scrollView
    ///
    /// - Parameters:
    ///   - zoomView: 需要缩放的view
    ///   - originSize: 需要缩放view的原始大小
    public init(zoomView: UIView, originSize: CGSize) {
        self.zoomView = zoomView
        self.originSize = originSize

        super.init(frame: CGRect.zero)

        zoomView.frame = CGRect.zero
        addSubview(zoomView)

        zoomScale = 1
        maximumZoomScale = 2
        minimumZoomScale = 1
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        contentInsetAdjustmentBehavior = .never
        backgroundColor = UIColor.black
        self.delegate = self
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        if zoomView.frame == CGRect.zero {
            zoomView.frame = fit(width: originSize.width, height: originSize.height, inBounds: bounds)
            contentSize = zoomView.bounds.size
        }
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func fit(width: CGFloat, height: CGFloat) -> CGRect {
        return fit(width: width, height: height, inBounds: bounds)
    }

    private func fit(width: CGFloat, height: CGFloat, inBounds bounds: CGRect) -> CGRect {
        guard width > 0, height > 0 else { return .zero }
        let ratio = bounds.width / bounds.height
        let zoomRatio = width / height
        if ratio >= zoomRatio {
            let height = bounds.height
            let width = height * zoomRatio
            if bounds.width / width > 2 {
                maximumZoomScale = bounds.width / width
            }
            return CGRect(x: (bounds.width - width) / 2, y: 0, width: width, height: height)
        } else {
            let width = bounds.width
            let height = width / zoomRatio
            if bounds.height / height > 2 {
                maximumZoomScale = bounds.height / height
            }
            return CGRect(x: 0, y: (bounds.height - height) / 2, width: width, height: height)
        }
    }

    func reset(zoomView: UIView, originSize: CGSize) {
        self.zoomView.removeFromSuperview()
        self.zoomView = zoomView
        addSubview(zoomView)
        self.originSize = originSize
    }

    public func relayoutZoomView(animated: Bool = false) {
        self.setZoomScale(1.0, animated: animated)
        zoomView.frame = CGRect.zero
        setNeedsLayout()
        layoutIfNeeded()
    }

    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let view = priorityView {
            let convertedPoint = convert(point, to: view)
            if view.bounds.contains(convertedPoint) {
                return view.hitTest(convertedPoint, with: event)
            }
        }
        return super.hitTest(point, with: event)
    }
}

extension ZoomScrollView: UIScrollViewDelegate {
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        zoomView.center = contentCenter(forBoundingSize: bounds.size, contentSize: contentSize)
    }

    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return zoomView
    }

    private func contentCenter(forBoundingSize boundingSize: CGSize, contentSize: CGSize) -> CGPoint {
        let horizontalOffest = (boundingSize.width > contentSize.width)
            ? ((boundingSize.width - contentSize.width) * 0.5) : 0.0
        let verticalOffset = (boundingSize.height > contentSize.height)
            ? ((boundingSize.height - contentSize.height) * 0.5) : 0.0

        return CGPoint(x: contentSize.width * 0.5 + horizontalOffest, y: contentSize.height * 0.5 + verticalOffset)
    }
}
