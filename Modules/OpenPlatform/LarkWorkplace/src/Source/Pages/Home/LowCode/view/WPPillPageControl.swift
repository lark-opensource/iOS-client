//
//  WPPillPageControl.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2021/4/28.
//

import LarkUIKit

final class WPPillPageControl: UIView {

    // MARK: - PageControl

    var pageCount: Int = 0 {
        didSet {
            updateNumberOfPages(pageCount)
        }
    }
    var progress: CGFloat = 0 {
        didSet {
            layoutActivePageIndicator(progress)
        }
    }
    var currentPage: Int {
        return Int(round(progress))
    }

    // MARK: - Appearance

    var pillSize: CGSize = CGSize(width: 10, height: 2)
    var activeTint: UIColor = UIColor.ud.primaryContentDefault {
        didSet {
            if activeLayer.superlayer != nil {
                activeLayer.ud.setBackgroundColor(activeTint)
            }
        }
    }
    var inactiveTint: UIColor = UIColor.ud.iconDisable {
        didSet {
            inactiveLayers.forEach {
                if $0.superlayer != nil {
                    $0.ud.setBackgroundColor(inactiveTint)
                }
            }
        }
    }
    var indicatorPadding: CGFloat = 6 {
        didSet {
            layoutInactivePageIndicators(inactiveLayers)
        }
    }

    fileprivate var inactiveLayers = [CALayer]()

    fileprivate lazy var activeLayer: CALayer = { [unowned self] in
        let layer = CALayer()
        layer.frame = CGRect(
            origin: CGPoint.zero,
            size: CGSize(width: self.pillSize.width, height: self.pillSize.height)
        )
        layer.cornerRadius = self.pillSize.height / 2
        layer.actions = [
            "bounds": NSNull(),
            "frame": NSNull(),
            "position": NSNull()
        ]
        return layer
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        pageCount = 0
        progress = 0
        indicatorPadding = 6
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - State Update

    fileprivate func updateNumberOfPages(_ count: Int) {
        // no need to update
        guard count != inactiveLayers.count else { return }
        // reset current layout
        inactiveLayers.forEach { $0.removeFromSuperlayer() }
        inactiveLayers = [CALayer]()
        // add layers for new page count
        inactiveLayers = stride(from: 0, to: count, by: 1).map { _ in
            let layer = CALayer()
            self.layer.addSublayer(layer)
            layer.ud.setBackgroundColor(self.inactiveTint)
            return layer
        }
        layoutInactivePageIndicators(inactiveLayers)
        // ensure active page indicator is on top
        self.layer.addSublayer(activeLayer)
        activeLayer.ud.setBackgroundColor(self.activeTint)
        layoutActivePageIndicator(progress)
        self.invalidateIntrinsicContentSize()
    }

    // MARK: - Layout

    fileprivate func layoutActivePageIndicator(_ progress: CGFloat) {
        // ignore if progress is outside of page indicators' bounds
        guard progress >= 0 && progress <= CGFloat(pageCount - 1) else { return }
        let denormalizedProgress = progress * (pillSize.width + indicatorPadding)
        activeLayer.frame.origin.x = denormalizedProgress
    }

    fileprivate func layoutInactivePageIndicators(_ layers: [CALayer]) {
        var layerFrame = CGRect(origin: CGPoint.zero, size: pillSize)
        layers.forEach { layer in
            layer.cornerRadius = layerFrame.size.height / 2
            layer.frame = layerFrame
            layerFrame.origin.x += layerFrame.width + indicatorPadding
        }
        // 布局
        let oldFrame = self.frame
        let width = CGFloat(inactiveLayers.count) * pillSize.width
            + CGFloat(inactiveLayers.count - 1) * indicatorPadding
        let superViewWidth = superview?.WP_w ?? UIScreen.main.bounds.width
        self.frame = CGRect(
            x: superViewWidth / 2 - width / 2,
            y: oldFrame.origin.y,
            width: width,
            height: oldFrame.size.height
        )
    }

    override var intrinsicContentSize: CGSize {
        return sizeThatFits(CGSize.zero)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(
            width: CGFloat(inactiveLayers.count) * pillSize.width
                + CGFloat(inactiveLayers.count - 1) * indicatorPadding,
            height: pillSize.height
        )
    }
}
