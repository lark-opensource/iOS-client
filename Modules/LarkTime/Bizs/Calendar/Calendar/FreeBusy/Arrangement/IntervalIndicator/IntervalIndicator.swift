//
//  IntervalIndicator.swift
//  Calendar
//
//  Created by zhuchao on 2019/3/20.
//

import Foundation
import CalendarFoundation
import UIKit

protocol IntervalIndicatorDelegate: AnyObject {
    func inticator(_ inticator: IntervalIndicator,
                   originFrame: CGRect,
                   didMoveTo newFrame: CGRect,
                   frameChangeKind: FrameChangeKind)
    func inticator(_ inticator: IntervalIndicator, moveEnded newFrame: CGRect)
    func inticatorLimitedRect(_ inticator: IntervalIndicator) -> CGRect
}

enum FrameChangeKind {
    case resizeUp
    case resizeDown
}

final class IntervalIndicator: UIView {

    enum BorderType {
        case dottedLine
        case solidLine

        func border() -> CAShapeLayer {
            let border = CAShapeLayer()
            border.lineWidth = 1.0
            if self == .dottedLine {
                border.lineDashPattern = [4, 2.5]
            }
            return border
        }
    }

    private let draggable: Bool
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.cd.semiboldFont(ofSize: 14)
        label.textColor = UIColor.ud.primaryContentDefault
        return label
    }()
    private let border: CAShapeLayer
    var clicked: (() -> Void)?

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        border.fillColor = UIColor.ud.primaryFillSolid01.withAlphaComponent(0.85).cgColor
        border.strokeColor = UIColor.ud.primaryContentDefault.cgColor
    }

    init(minHeight: CGFloat = 25.0,
         title: String? = nil,
         draggable: Bool,
         borderType: BorderType) {
        self.minHeight = minHeight
        self.draggable = draggable
        self.border = borderType.border()
        // 暂时取375作为屏幕宽度
        let width: CGFloat = 375
        let initFrame = CGRect(x: 0, y: 100, width: width, height: minHeight)
        super.init(frame: initFrame)
        layout(leftHandle: bottomleftHandle, rightHandle: topRightHandle)
        setupTitleLabel(titleLabel, title: title)
        layer.insertSublayer(border, at: 0)
        border.ud.setFillColor(UIColor.ud.primaryFillSolid01.withAlphaComponent(0.85), bindTo: self)
        border.ud.setStrokeColor(UIColor.ud.primaryContentDefault, bindTo: self)
        let gestureView = UIView()
        addSubview(gestureView)
        gestureView.frame = self.bounds
        gestureView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        addTap(gestureView)
        addPanGesture(gestureView)
    }

    private func addTap(_ view: UIView) {
        let tap = UITapGestureRecognizer(target: self, action: #selector(taped))
        view.addGestureRecognizer(tap)
    }

    @objc
    private func taped() {
        clicked?()
    }

    weak var delegate: IntervalIndicatorDelegate?
    private let minHeight: CGFloat
    private let topRightHandle = IntervalIndicator.handleView()
    private let bottomleftHandle = IntervalIndicator.handleView()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        border.path = UIBezierPath(rect: CGRect(origin: .zero, size: frame.size)).cgPath
        border.frame = bounds
    }

    private func addPanGesture(_ view: UIView) {
        let pan = UIPanGestureRecognizer(target: self,
                                         action: #selector(panPiece(_:)))
        view.addGestureRecognizer(pan)
    }

    @objc
    private func panPiece(_ panGesture: UIPanGestureRecognizer) {
        let translation = panGesture.translation(in: self)
        panGesture.setTranslation(.zero, in: self)
        if panGesture.state == .changed {
            move(distance: translation.y)
            return
        }
        if panGesture.state == .ended {
            self.delegate?.inticator(self, moveEnded: self.frame)
            return
        }
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if topRightHandle.extendRect.contains(point) {
            return topRightHandle
        }
        if bottomleftHandle.extendRect.contains(point) {
            return bottomleftHandle
        }
        if draggable {
            return super.hitTest(point, with: event)
        }
        return nil
    }

    private func setupTitleLabel(_ label: UILabel, title: String?) {
        guard let title = title else { return }
        label.text = title
        self.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
    }

    private func layout(leftHandle: RangeHandelView, rightHandle: RangeHandelView) {
        let margin: CGFloat = 25
        self.addSubview(leftHandle)
        leftHandle.center = CGPoint(x: margin, y: self.bounds.height)
        leftHandle.autoresizingMask = [.flexibleTopMargin, .flexibleRightMargin]
        leftHandle.move = { [weak self] (translation: CGFloat) in
            guard let `self` = self else { return }
            self.moveBottom(distance: translation)
        }
        leftHandle.ended = { [weak self] in
            guard let `self` = self else { return }
            self.delegate?.inticator(self, moveEnded: self.frame)
        }

        self.addSubview(rightHandle)
        rightHandle.center = CGPoint(x: self.bounds.width - margin, y: 0)
        rightHandle.move = { [weak self] (translation: CGFloat) in
            guard let `self` = self else { return }
            self.moveTop(distance: translation)
        }
        rightHandle.ended = { [weak self] in
            guard let `self` = self else { return }
            let originFrame = self.frame
            let newFrame = self.rationalizeFrame(self.frame, originFrame: originFrame)
            self.delegate?.inticator(self, moveEnded: newFrame)
        }
        rightHandle.autoresizingMask = [.flexibleBottomMargin, .flexibleLeftMargin]
    }

    private func move(distance: CGFloat) {
        // distance > 0 往下走, < 0 往上走
        var frame = self.frame
        frame.origin.y += distance
        let frameChangeKind: FrameChangeKind = distance > 0 ? .resizeDown : .resizeUp
        updateFrame(frame, frameChangeKind: frameChangeKind)
    }

    private func moveTop(distance: CGFloat) {
        // distance > 0 往下走, < 0 往上走
        var frame = self.frame
        frame.size.height -= distance
        if frame.height < minHeight { return }
        frame.origin.y += distance
        updateFrame(frame, frameChangeKind: .resizeUp)
    }

    private func moveBottom(distance: CGFloat) {
        // distance > 0 往下走, < 0 往上走
        var frame = self.frame
        frame.size.height += distance
        if frame.height < minHeight { frame.size.height = minHeight }
        updateFrame(frame, frameChangeKind: .resizeDown)
    }

    private func updateFrame(_ frame: CGRect, frameChangeKind: FrameChangeKind) {
        guard let delegate = self.delegate else {
            self.frame = frame
            return
        }
        let originFrame = self.frame
        let newFrame = rationalizeFrame(frame, originFrame: originFrame)
        self.frame = newFrame
        delegate.inticator(self,
                           originFrame: originFrame,
                           didMoveTo: newFrame,
                           frameChangeKind: frameChangeKind)
    }

    private func rationalizeFrame(_ frame: CGRect, originFrame: CGRect) -> CGRect {
        guard let delegate = self.delegate else {
            return frame
        }
        let limitedFrame = delegate.inticatorLimitedRect(self)
        var frame = frame
        if frame.minY < limitedFrame.minY {
            frame.origin.y = limitedFrame.minY
            frame.size.height = originFrame.maxY - limitedFrame.minY
        }
        if frame.maxY > limitedFrame.maxY {
            frame.origin.y = originFrame.minY
            frame.size.height = limitedFrame.maxY - originFrame.minY
        }
        return frame
    }

    private static func handleView() -> RangeHandelView {
        let width: CGFloat = 20.0
        let view = RangeHandelView(frame: CGRect(x: 0, y: 0, width: width, height: width))
        view.backgroundColor = UIColor.clear

        let circleRadius: CGFloat = 4.5
        let circleLayer = CALayer()
        view.layer.addSublayer(circleLayer)
        circleLayer.frame = CGRect(x: width / 2 - circleRadius, y: width / 2 - circleRadius, width: circleRadius * 2, height: circleRadius * 2)
        circleLayer.cornerRadius = circleRadius
        circleLayer.ud.setBorderColor(UIColor.ud.primaryContentDefault)
        circleLayer.ud.setBackgroundColor(UIColor.ud.primaryOnPrimaryFill)
        circleLayer.borderWidth = 2

        return view
    }
}

private final class RangeHandelView: UIView {

    var move: ((CGFloat) -> Void)?
    var ended: (() -> Void)?
    var extendRect = CGRect.zero
    private let extentDeltaX: CGFloat = 15.0

    var lastPositionY: CGFloat = 0

    override var frame: CGRect {
        didSet {
            extendRect = frame.insetBy(dx: -extentDeltaX, dy: -extentDeltaX)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(gesture:)))
        addGestureRecognizer(gesture)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func handlePan(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            lastPositionY = 0
        case .ended, .cancelled:
            ended?()
        case .changed:
            let translationY = gesture.translation(in: window).y
            defer { lastPositionY = translationY }
            let deltaY = translationY - lastPositionY
            move?(deltaY)
        default:
            break
        }
    }

}
