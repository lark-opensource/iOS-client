//
//  MagicShareDirectionView.swift
//  ByteView
//
//  Created by liurundong.henry on 2020/5/18.
//

import Foundation
import RxSwift
import Action
import ByteViewCommon
import ByteViewUI

class MagicShareDirectionView: UIView {

    private var disposeBag = DisposeBag()

    private struct Layout {
        static let backgroundSideLength: CGFloat = 36.0
        static let avatarSideLength: CGFloat = 32.0
        static let sideLength: CGFloat = 50.0
    }

    lazy var backgroundView: UIView = {
        let view = UIView()
        directionGradientLayer.mask = directionShapeLayer
        view.layer.insertSublayer(directionGradientLayer, at: 0)
        view.layer.ud.setShadowColor(UIColor.ud.N1000.withAlphaComponent(0.2))
        view.layer.shadowOpacity = 1.0
        view.layer.shadowRadius = 4.0
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        return view
    }()

    let directionShapeLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        let bezier = UIBezierPath()
        bezier.addArc(withCenter: CGPoint(x: Layout.sideLength / 2.0,
                                          y: Layout.sideLength / 2.0),
                      radius: Layout.backgroundSideLength / 2.0,
                      startAngle: 0,
                      endAngle: CGFloat.pi * 2,
                      clockwise: true)
        layer.path = bezier.cgPath
        return layer
    }()

    let directionGradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.frame = CGRect(x: 0, y: 0, width: Layout.sideLength, height: Layout.sideLength)
        layer.locations = [0, 0.5, 1.0]
        layer.startPoint = CGPoint(x: 0, y: 1)
        layer.endPoint = CGPoint(x: 1, y: 0)
        return layer
    }()

    let avatarView = AvatarView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupSubviews()
        autoLayoutSubviews()
        addInteraction(type: .lift)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        addSubview(backgroundView)
        addSubview(avatarView)

        directionGradientLayer.ud.setColors([UIColor.ud.colorfulViolet,
                                             UIColor.ud.R400,
                                             UIColor.ud.colorfulYellow])
    }

    private func autoLayoutSubviews() {
        backgroundView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        let insetLength = (Layout.sideLength - Layout.avatarSideLength) / 2
        avatarView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(insetLength)
        }
    }

    /// 设置指引方向
    /// - Parameter direction: 方向枚举
    private func setDirection(_ direction: MagicShareDirectionViewModel.Direction) {
        switch direction {
        case .left:
            setDirectionWithRadian(CGFloat.pi)
        case .top:
            setDirectionWithRadian(CGFloat.pi * 3 / 2.0)
        case .right:
            setDirectionWithRadian(0)
        case .bottom:
            setDirectionWithRadian(CGFloat.pi * 1 / 2.0)
        case .free:
            setFree()
        }
    }

    /// 设置指引方向
    /// - Parameter radian: 以右侧为 0 或 2*CGFloat.pi 顺时针旋转到指引方向的值，单位是弧度，有效范围是 0 <= radian < CGFloat.pi * 2
    private func setDirectionWithRadian(_ radian: CGFloat) {
        guard radian >= 0 && radian < CGFloat.pi * 2 else { return }
        /// 弧线的起始位置
        var curveStartRadian = radian + CGFloat.pi * 1 / 8.0
        if curveStartRadian > CGFloat.pi * 2 {
            curveStartRadian -= CGFloat.pi * 2
        }
        /// 弧线的终止位置
        var curveEndRadian = radian - CGFloat.pi * 1 / 8.0
        if curveEndRadian < 0 {
            curveEndRadian += CGFloat.pi * 2
        }
        /// 计算箭头顶点位置
        let xPos = Layout.sideLength / 2.0 + sin(radian + CGFloat.pi * 1 / 2.0) * Layout.sideLength / 2.0
        let yPos = Layout.sideLength / 2.0 - cos(radian + CGFloat.pi * 1 / 2.0) * Layout.sideLength / 2.0
        let vertex = CGPoint(x: xPos, y: yPos)
        /// 画图 vertex -> curveStartRadian -> 顺时针圆弧 -> curveEndRadian -> vertex
        let bezier = UIBezierPath()
        bezier.move(to: vertex)
        bezier.addArc(withCenter: CGPoint(x: Layout.sideLength / 2.0,
                                          y: Layout.sideLength / 2.0),
                      radius: Layout.backgroundSideLength / 2.0,
                      startAngle: curveStartRadian,
                      endAngle: curveEndRadian,
                      clockwise: true)
        bezier.addLine(to: vertex)
        directionShapeLayer.path = bezier.cgPath
    }

    private func setFree() {
        let bezier = UIBezierPath()
        bezier.addArc(withCenter: CGPoint(x: Layout.sideLength / 2.0,
                                          y: Layout.sideLength / 2.0),
                      radius: Layout.backgroundSideLength / 2.0,
                      startAngle: 0,
                      endAngle: CGFloat.pi * 2,
                      clockwise: true)
        directionShapeLayer.path = bezier.cgPath
    }

    private var attachmentEdge: AttachmentEdge = .both
    private var attachmentEdgeInsets: UIEdgeInsets = .zero
    private var excludesSafeAreaToAttach: Bool = true
    private var attachmentPan: UIPanGestureRecognizer?
    private var attachmentDisposeBag: DisposeBag = DisposeBag()
    private var hasRemovedConstraints: Bool = false
    var moveSafeArea: CGRect = .zero
    var excludedRegion: (() -> CGRect?)?
    var defaultPosition: (() -> CGPoint?)?
}

extension MagicShareDirectionView {

    func bindViewModel(_ viewModel: MagicShareDirectionViewModel) {
        disposeBag = DisposeBag()

        avatarView.setTapAction {
            InMeetFollowViewModel.logger.debug("tapped direction view")
            viewModel.tapPresenterIconAction.execute()
        }

        viewModel.avatarInfoObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (avatarInfo: AvatarInfo) in
                self?.avatarView.setTinyAvatar(avatarInfo)
            })
            .disposed(by: disposeBag)

        Observable.combineLatest(viewModel.directionObservable, viewModel.isRemoteEqualLocalObservable)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (direction: MagicShareDirectionViewModel.Direction, isEqual: Bool) in
                if isEqual {
                    self?.setDirection(direction)
                } else {
                    self?.setDirection(.free)
                }
            })
            .disposed(by: disposeBag)
    }

}

extension MagicShareDirectionView {
    struct AttachmentEdge: OptionSet {
        let rawValue: Int

        static let left = AttachmentEdge(rawValue: 1 << 0)
        static let right = AttachmentEdge(rawValue: 1 << 1)
        static let both: AttachmentEdge = [.left, .right]
    }

    private var movableRegion: CGRect? {
        guard let superview = self.superview else {
            return nil
        }
        let edgeInsets = attachmentEdgeInsets
        var region = superview.bounds
        if excludesSafeAreaToAttach {
            // Assumes bounds.origin == (0, 0)
            let safeAreaInsets = superview.safeAreaInsets
            region = region.inset(by: safeAreaInsets)
        }
        region = region.inset(by: edgeInsets)
        return region
    }

    func enableAttachment(within edgeInsets: UIEdgeInsets,
                          attachesToEdge edge: AttachmentEdge = .both,
                          excludesSafeArea: Bool = true) {
        attachmentDisposeBag = DisposeBag()
        attachmentEdgeInsets = edgeInsets
        attachmentEdge = edge
        excludesSafeAreaToAttach = excludesSafeArea
        let pan: UIPanGestureRecognizer
        if let thePan = attachmentPan {
            pan = thePan
        } else {
            pan = UIPanGestureRecognizer()
            addGestureRecognizer(pan)
            attachmentPan = pan
        }
        handlePan(pan)
        handleOrientationChanged()
    }

    private func handlePan(_ pan: UIPanGestureRecognizer) {
        var lastLocation: CGPoint = .zero
        pan.rx.event
            .bind(onNext: { [weak self] gr in
                guard let self = self else {
                    return
                }

                let newLocation = gr.location(in: gr.view)
                switch gr.state {
                case .possible:
                    break
                case .began:
                    self.removeMyselfConstraintsIfNeeded()
                    lastLocation = newLocation
                case .changed:
                    guard let view = gr.view else {
                        return
                    }

                    let dx = newLocation.x - lastLocation.x
                    let dy = newLocation.y - lastLocation.y
                    var newFrame = view.frame
                    newFrame.origin.x += dx
                    newFrame.origin.y += dy
                    if self.moveSafeArea != .zero {
                        let minY = abs(self.attachmentEdgeInsets.top)
                        let maxY = self.moveSafeArea.height - self.bounds.height - abs(self.attachmentEdgeInsets.bottom)
                        newFrame.origin.y = newFrame.origin.y < minY ? minY : newFrame.origin.y
                        newFrame.origin.y = newFrame.origin.y > maxY ? maxY : newFrame.origin.y
                    }

                    view.frame = newFrame
                case .ended, .cancelled, .failed:
                    self.attachToEdge()
                @unknown default:
                    break
                }
            })
            .disposed(by: attachmentDisposeBag)
    }

    func removeMyselfConstraintsIfNeeded() {
        guard !hasRemovedConstraints else {
            return
        }
        hasRemovedConstraints = true

        // clear all constraints excepts subviews
        var superview = self.superview
        while let view = superview {
            let constraints = view.constraints.filter {
                $0.firstItem === self || $0.secondItem === self
            }
            view.removeConstraints(constraints)
            superview = view.superview
        }
        let constraints = self.constraints.filter {
            $0.firstItem == nil || $0.secondItem == nil || ($0.firstItem === self && $0.secondItem === self)
        }
        removeConstraints(constraints)
        translatesAutoresizingMaskIntoConstraints = true
    }

    func attachToEdge(animated: Bool = true) {
        guard let movableRegion = self.movableRegion else {
            return
        }

        let newX = self.newX(from: movableRegion, to: movableRegion)

        var newY = frame.origin.y
        if frame.minY < movableRegion.minY {
            newY = movableRegion.minY
        }
        if frame.maxY > movableRegion.maxY {
            newY = movableRegion.maxY - bounds.height
        }

        let origin = CGPoint(x: newX, y: newY)
        var newFrame = frame
        newFrame.origin = origin
        let isConflicted = excludeRegionIfNeeded(frame: &newFrame, in: movableRegion)
        if !isConflicted, !hasRemovedConstraints {
            return
        }

        if animated {
            // nolint-next-line: magic number
            UIView.animate(withDuration: 0.2,
                           delay: 0.0,
                           usingSpringWithDamping: 1.0,
                           initialSpringVelocity: 0.0,
                           options: [],
                           animations: {
                self.frame = newFrame
            })
        } else {
            frame = newFrame
        }
    }

    @discardableResult
    private func excludeRegionIfNeeded(frame: inout CGRect, in movableRegion: CGRect) -> Bool {
        if let excludedRegion = excludedRegion?(),
           excludedRegion.intersects(frame) { // Conflicts
            removeMyselfConstraintsIfNeeded()

            let minY = movableRegion.minY
            let maxY = movableRegion.maxY - bounds.height

            let below: Bool
            if frame.center.y > excludedRegion.center.y { // 偏向于下
                if maxY > excludedRegion.maxY {
                    below = true
                } else {
                    below = false
                }
            } else { // 偏向于上
                if excludedRegion.minY - minY >= bounds.height {
                    below = false
                } else {
                    below = true
                }
            }

            if below {
                frame.origin.y = excludedRegion.maxY
            } else {
                frame.origin.y = excludedRegion.minY - bounds.height
            }
            return true
        } else {
            return false
        }
    }

    private func newX(from fromRegion: CGRect, to toRegion: CGRect) -> CGFloat {
        let isLeft: Bool?
        switch attachmentEdge {
        case .left:
            isLeft = true
        case .right:
            isLeft = false
        case .both:
            isLeft = center.x < fromRegion.midX
        default:
            isLeft = nil
        }
        if let isLeft = isLeft {
            return isLeft ? toRegion.minX : toRegion.maxX - bounds.width
        } else {
            return frame.origin.x
        }
    }

    private func handleOrientationChanged() {
        let fromRegionObservable = NotificationCenter.default.rx
            .notification(UIApplication.willChangeStatusBarOrientationNotification)
            .map { [weak self] _ in self?.movableRegion }
        NotificationCenter.default.rx
            .notification(UIApplication.didChangeStatusBarOrientationNotification)
            .map({ _ in UIApplication.shared.statusBarOrientation })
            .distinctUntilChanged()
            .withLatestFrom(fromRegionObservable)
            .delay(.nanoseconds(1), scheduler: MainScheduler.asyncInstance)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] fromRegion in
                guard let self = self,
                      self.attachmentPan?.state != .changed,
                      self.hasRemovedConstraints == true else {
                    return
                }

                self.superview?.layoutIfNeeded()
                // must use async, don't ask me why!
                if let origin = self.defaultPosition?() {
                    let block = {
                        self.frame.origin = origin
                    }
                    if self is UIWindow {
                        // must use async, don't ask me why!
                        DispatchQueue.main.async(execute: block)
                    } else {
                        block()
                    }
                } else if let fromRegion = fromRegion {
                    self.updatePositionProportionally(fromRegion: fromRegion)
                }
            })
            .disposed(by: attachmentDisposeBag)
    }

    private func updatePositionProportionally(fromRegion: CGRect) {
        guard let movableRegion = self.movableRegion,
              fromRegion != movableRegion else {
            return
        }

        let newX = self.newX(from: fromRegion, to: movableRegion)

        var newY: CGFloat
        if center.y < fromRegion.midY {
            let yRatio = max(frame.minY - fromRegion.minY, 0.0) / fromRegion.height
            newY = movableRegion.minY + yRatio * movableRegion.height
            newY = min(newY, movableRegion.maxY - bounds.height)
        } else {
            let yRatio = max(fromRegion.maxY - frame.maxY, 0.0) / fromRegion.height
            newY = movableRegion.maxY - yRatio * movableRegion.height - bounds.height
            newY = max(newY, movableRegion.minY)
        }

        let origin = CGPoint(x: newX, y: newY)
        var newFrame = frame
        newFrame.origin = origin
        excludeRegionIfNeeded(frame: &newFrame, in: movableRegion)

        let block = {
            self.frame = newFrame
        }
        if self is UIWindow {
            // must use async, don't ask me why!
            DispatchQueue.main.async(execute: block)
        } else {
            block()
        }
    }
}
