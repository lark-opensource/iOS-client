//
//  TabBarView.swift
//  Calendar
//
//  Created by zhouyuan on 2018/11/30.
//  Copyright © 2018 EE. All rights reserved.
//

import UniverseDesignIcon
import Foundation
import CalendarFoundation
import LarkResource
import UniverseDesignColor
import UniverseDesignTheme
import UIKit
import LarkUIKit
import LKCommonsLogging

enum ArrowDirection {
    /// 左右箭头
    case horizontal
    /// 上下箭头
    case vertical
}

protocol TabBarView {
    func control() -> UIControl
    func jumpToProgress(_ progress: CGFloat)
    func endAnimation()
    func shouldChangeDateImage(uiCurrentDate: Date)
    func animation(with progress: CGFloat, shouldGradual: Bool, direction: ArrowDirection)
}

final class TabBarViewImpl: UIControl, TabBarView {
    static let logger = Logger.log(TabBarViewImpl.self, category: "Calendar.tab")

    /// 日期
    private lazy var dateImageSelectedView: UIImageView = {
        let image = UIImage.cd.currentTabSelectedImage()
        let dateImageSelectedView = UIImageView(image: image)
        self.dateSelectedView.addSubview(dateImageSelectedView)
        dateImageSelectedView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        return dateImageSelectedView
    }()

    private lazy var dateSelectedView: UIView = {
        let view = UIView()
        view.addSubview(self.bgSelectView)
        self.wrapper.addSubview(view)
        view.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.height.width.equalToSuperview()
        }
        self.bgSelectView.snp.makeConstraints({ (make) in
            make.center.equalToSuperview()
            make.height.width.equalTo(15)
        })
        return view
    }()

    private lazy var dateImageUnselectedView: UIImageView = {
        let image = UIImage.cd.currentTabUnSelectedImage().renderColor(with: .n3)
        let unSelectImageView = UIImageView(image: image)
        return unSelectImageView
    }()

    private var direction: ArrowDirection = .horizontal
    /// 箭头
    private lazy var rightArrowImagwView: UIImageView = {
        let icon: UIImage
        if TabBarViewImpl.isVIColor {
            icon = UDIcon.calendarRightFilled.ud.withTintColor(TabBarViewImpl.selectedColor)
        } else {
            icon = UDIcon.calendarRightColorful
        }
        return TabBarViewImpl.getArrorImageView(icon)
    }()

    private lazy var leftArrowImagwView: UIImageView = {
        let icon: UIImage
        if TabBarViewImpl.isVIColor {
            icon = UDIcon.calendarLeftFilled.ud.withTintColor(TabBarViewImpl.selectedColor)
        } else {
            icon = UDIcon.calendarLeftColorful
        }
        return TabBarViewImpl.getArrorImageView(icon)
    }()

    private lazy var upArrowImagwView: UIImageView = {
        let icon: UIImage
        if TabBarViewImpl.isVIColor {
            icon = UDIcon.calendarUpFilled.ud.withTintColor(TabBarViewImpl.selectedColor)
        } else {
            icon = UDIcon.calendarUpColorful
        }
        return TabBarViewImpl.getArrorImageView(icon)
    }()

    private lazy var downArrowImagwView: UIImageView = {
        let icon: UIImage
        if TabBarViewImpl.isVIColor {
            icon = UDIcon.calendarDownFilled.ud.withTintColor(TabBarViewImpl.selectedColor)
        } else {
            icon = UDIcon.calendarDownColorful
        }
        return TabBarViewImpl.getArrorImageView(icon)
    }()

    private lazy var bgSelectView: UIView = {
        var view = UIView()
        view.backgroundColor = UIColor.ud.bgBody
        return view
    }()

    private lazy var bgArrowView: UIView = {
        var view = UIView()
        view.backgroundColor = UIColor.ud.bgBody
        return view
    }()

    static func getArrorImageView(_ image: UIImage) -> UIImageView {
        let image = image.antiAlias()
        let imageView = UIImageView(image: image)
        imageView.layer.contentsScale = UIScreen.main.scale
        imageView.isHidden = true
        return imageView
    }

    private static let image = UIImage.cd.image(named: "icon_calendar-bg_filled")
        .withRenderingMode(.alwaysTemplate)

    private static var selectedColor: UIColor {
        if let vic = TabBarViewImpl.viColor {
            // dark mode下不使用vi染色
            return vic & UIColor.ud.primaryContentDefault
        }
        return UIColor.ud.primaryContentDefault
    }

    private static var isVIColor: Bool {
        if let _ = TabBarViewImpl.viColor {
            return true
        }
        return false
    }

    private static var viColor: UIColor? {
        return ResourceManager.get(key: "suite_skin_vi_icon_color", type: "color")
    }

    private var bgImageWidth: CGFloat {
        return Display.pad ? 18 : 20 // iPad 箭头图标无法盖住 bgImage，在这里做简单适配。不影响显示效果
    }

    private lazy var imageView1: UIImageView = {
        let imageView1 = UIImageView(image: TabBarViewImpl.image)
        self.wrapper.addSubview(imageView1)
        imageView1.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.height.width.equalTo(self.bgImageWidth)
        }
        return imageView1
    }()
    private lazy var imageView2: UIImageView = {
        let imageView2 = UIImageView(image: TabBarViewImpl.image)
        self.wrapper.addSubview(imageView2)
        imageView2.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.height.width.equalTo(self.bgImageWidth)
        }
        return imageView2
    }()
    private lazy var imageView3: UIImageView = {
        let imageView3 = UIImageView(image: TabBarViewImpl.image)
        self.wrapper.addSubview(imageView3)
        imageView3.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.height.width.equalTo(self.bgImageWidth)
        }
        return imageView3
    }()
    private lazy var wrapper: UIView = {
        let wrapper = UIView()
        wrapper.isHidden = true
        self.addSubview(wrapper)
        wrapper.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        return wrapper
    }()
    init() {
        super.init(frame: .zero)
        self.accessibilityIdentifier = "CalendarTabBarView"
        self.dateImageUnselectedView.isHidden = false
        self.addSubview(dateImageUnselectedView)
        dateImageUnselectedView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    func control() -> UIControl { return self }

    private func layoutArrowViewIfNeeded(wrapper: UIView) {
        guard rightArrowImagwView.superview == nil else { return }
        wrapper.addSubview(bgArrowView)
        bgArrowView.snp.makeConstraints({ (make) in
            make.center.equalToSuperview()
            make.height.width.equalTo(15)
        })
        wrapper.addSubview(rightArrowImagwView)
        rightArrowImagwView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        wrapper.addSubview(leftArrowImagwView)
        leftArrowImagwView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        wrapper.addSubview(upArrowImagwView)
        upArrowImagwView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        wrapper.addSubview(downArrowImagwView)
        downArrowImagwView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    private var animator: UIViewPropertyAnimator?

    override var isSelected: Bool {
        didSet {
            if isSelected == oldValue {
                return
            }
            if !isSelected {
                animator = UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.15, delay: 0, options: UIView.AnimationOptions.curveLinear, animations: {
                    self.resetTransform()
                }) { (position) in
                    if position == .end {
                        self.wrapper.isHidden = true
                        self.dateImageUnselectedView.isHidden = false
                    }
                }
            } else {
                if let animator = animator, animator.isInterruptible {
                    animator.stopAnimation(true)
                } else {
                    normalErrorLog("tabbarView animator isInterruptible is false, cannot stop!")
                }
                DispatchQueue.main.async {
                    self.layer.lu.bounceAnimation(duration: 0.25) {
                        UIView.animate(withDuration: 0.2) {
                            if self.isSelected {
                                self.wrapper.isHidden = false
                                self.dateImageUnselectedView.isHidden = true
                            } else {
                                Self.logger.info("isSelected error")
                            }
                            self.startAnimationIfNeeded(progress: self.currentProgress, direction: self.direction)
                        }
                    }
                }
            }
        }
    }

    func shouldChangeDateImage(uiCurrentDate: Date) {
        Self.logger.info("shouldChangeDateImage executed")
        let selectImage: UIImage
        if TabBarViewImpl.isVIColor {
            // 由于选中态是彩色不能染，KA 用 UnSelectedImage + viColor 染色
            selectImage = UIImage.cd.currentTabUnSelectedImage(uiCurrentDate: uiCurrentDate).ud.withTintColor(TabBarViewImpl.selectedColor)
        } else {
            selectImage = UIImage.cd.currentTabSelectedImage(uiCurrentDate: uiCurrentDate)
        }
        let unselectImage = UIImage.cd.currentTabUnSelectedImage(uiCurrentDate: uiCurrentDate)
        .renderColor(with: .n3)
        self.dateImageSelectedView.image = selectImage
        self.dateImageUnselectedView.image = unselectImage
    }

    func animation(with progress: CGFloat, shouldGradual: Bool = true, direction: ArrowDirection) {
        var progress = progress
        if progress >= CGFloat(Int.max) || progress <= CGFloat(Int.min) {
            progress = 0
        }
        if isEndingAnimation { return }
        self.currentProgress = progress
        self.direction = direction
        startAnimationIfNeeded(progress: progress, shouldGradual: shouldGradual, direction: direction)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        startAnimationIfNeeded(progress: currentProgress,
                               forceRefresh: true,
                               direction: direction)
    }

    private func startAnimationIfNeeded(progress: CGFloat,
                                        shouldGradual: Bool = false,
                                        forceRefresh: Bool = false,
                                        direction: ArrowDirection) {
        guard (abs(oldProgress - progress) > 0.0001) || forceRefresh  else { return }
        self.layoutArrowViewIfNeeded(wrapper: self.wrapper)
        setDateImageViewAlpha(with: progress, shouldGradual: shouldGradual)
        setArrowAnimation(progress: progress, direction: direction)
        backGroundImageViewAnimation(progress: progress)
        bringIconViewToFront()
    }

    private func backGroundImageViewAnimation(progress: CGFloat) {
        let baseSign: CGFloat = progress > 0 ? -1 : 1
        if progress < 1.0 && progress > -1.0 {
            stage0(progress: progress, baseSign: baseSign)
            return
        }
        var stage: Int
        if progress >= 1.0 {
            let intProgress = Int(exactly: progress.rounded(.down)) ?? 0
            stage = Int(intProgress) % 3
        } else { /// progress <= -1.0
            let intProgress = Int(exactly: progress.rounded(.up)) ?? 0
            stage = abs(intProgress) % 3
        }

        var progress = progress
        progress.formTruncatingRemainder(dividingBy: 1.0)
        switch stage {
        case 0:
            wrapper.bringSubviewToFront(imageView3)
            wrapper.bringSubviewToFront(imageView1)
            wrapper.bringSubviewToFront(imageView2)
            stage1(imageView: imageView2, progress: progress, baseSign: baseSign)
            stage2(imageView: imageView1, progress: progress, baseSign: baseSign)
            stage3(imageView: imageView3, progress: progress, baseSign: baseSign)
        case 1:
            wrapper.bringSubviewToFront(imageView1)
            wrapper.bringSubviewToFront(imageView2)
            wrapper.bringSubviewToFront(imageView3)
            stage1(imageView: imageView3, progress: progress, baseSign: baseSign)
            stage2(imageView: imageView2, progress: progress, baseSign: baseSign)
            stage3(imageView: imageView1, progress: progress, baseSign: baseSign)
        case 2:
            wrapper.bringSubviewToFront(imageView2)
            wrapper.bringSubviewToFront(imageView3)
            wrapper.bringSubviewToFront(imageView1)
            stage1(imageView: imageView1, progress: progress, baseSign: baseSign)
            stage2(imageView: imageView3, progress: progress, baseSign: baseSign)
            stage3(imageView: imageView2, progress: progress, baseSign: baseSign)
        default:
            return
        }
    }

    private func setDateImageViewAlpha(with progress: CGFloat, shouldGradual: Bool) {
        let progress = abs(progress)
        if !shouldGradual {
            self.dateSelectedView.alpha = (progress < 0.05) ? 1 : 0
            return
        }
        if progress > 1.0 {
            self.dateSelectedView.alpha = 0
            return
        }
        self.dateSelectedView.alpha = 1 - progress
    }

    private func setArrowAnimation(progress: CGFloat, direction: ArrowDirection) {
        let arrowProgress: CGFloat
        if progress < -1.0 {
            arrowProgress = -1
        } else if progress > 1.0 {
            arrowProgress = 1
        } else {
            arrowProgress = progress
        }
        let transform = CGAffineTransform(rotationAngle: getAngle(by: 5 * arrowProgress))
        switch direction {
        case .horizontal:
            rightArrowImagwView.isHidden = arrowProgress >= 0
            leftArrowImagwView.isHidden = arrowProgress <= 0
            upArrowImagwView.isHidden = true
            downArrowImagwView.isHidden = true
        case .vertical:
            rightArrowImagwView.isHidden = true
            leftArrowImagwView.isHidden = true
            upArrowImagwView.isHidden = arrowProgress <= 0
            downArrowImagwView.isHidden = arrowProgress >= 0
        }
        rightArrowImagwView.transform = transform
        leftArrowImagwView.transform = transform
        upArrowImagwView.transform = transform
        downArrowImagwView.transform = transform
    }

    private func getAngle(by degrees: CGFloat) -> CGFloat {
        return CGFloat(Double.pi) * (degrees) / 180.0
    }

    // 颜色渐变过程
    // 101 167 252 | 78 131 253
    // 159 198 254 | 149 180 252
    // 208 228 255 | 186 206 253
    // 232 240 250 | 225 234 255
    private func stage0(progress: CGFloat, baseSign: CGFloat) {
        let absProgress = abs(progress)
        var transform1 = CGAffineTransform.identity
        transform1 = transform1
            .translatedBy(x: -9.6 * progress, y: 0.1 * absProgress)
            .scaledBy(x: (1 - 0.4 * absProgress), y: (1 - 0.4 * absProgress))
            .rotated(by: getAngle(by: -25 * progress))

        imageView1.transform = transform1

        var transform2 = CGAffineTransform.identity
        transform2 = transform2
            .translatedBy(x: -4.9 * progress, y: -0.6 * absProgress)
            .scaledBy(x: (1 - 0.2 * absProgress), y: (1 - 0.2 * absProgress))
            .rotated(by: getAngle(by: -10 * progress))

        imageView2.transform = transform2

        let transform3 = CGAffineTransform(rotationAngle: getAngle(by: 5 * progress))
        imageView3.transform = transform3

        // 101 167 252 | 78 131 253
        // 159 198 254 | 149 180 252
        // 208 228 255 | 186 206 253
        // 232 240 250 | 225 234 255
        if TabBarViewImpl.isVIColor {
            imageView1.tintColor = TabBarViewImpl.selectedColor.withAlphaComponent(0.5 * absProgress)
            imageView2.tintColor = TabBarViewImpl.selectedColor.withAlphaComponent(0.4 * absProgress)
        } else {
            imageView1.tintColor = color(from: flag0, to: flag2, progress: absProgress)
            imageView2.tintColor = color(from: flag0, to: flag1, progress: absProgress)
        }
    }

    private func stage1(imageView: UIImageView, progress: CGFloat, baseSign: CGFloat) {
        imageView.alpha = 1
        let absProgress = abs(progress)
        var transform = CGAffineTransform.identity
        transform = transform.translatedBy(x: -4.9 * progress, y: -0.6 * absProgress)
        transform = transform.scaledBy(x: (1 - 0.2 * absProgress), y: (1 - 0.2 * absProgress))
        transform = transform.rotated(by: getAngle(by: -5 * baseSign))
        transform = transform.rotated(by: getAngle(by: -15 * progress))

        imageView.transform = transform
        // 78 131 253
        // 149 180 252
        // 186 206 253
        // 225 234 255
        if TabBarViewImpl.isVIColor {
            imageView.tintColor = TabBarViewImpl.selectedColor.withAlphaComponent(0.5 - 0.1 * absProgress)
        } else {
//            imageView.tintColor = UIColorRGB(78 + 71 * absProgress,
//                                              131 + 49 * absProgress,
//                                              253 + -1 * absProgress)
            imageView.tintColor = color(from: flag0, to: flag1, progress: absProgress)
        }
    }

    private func stage2(imageView: UIImageView, progress: CGFloat, baseSign: CGFloat) {
        imageView.alpha = 1
        let absProgress = abs(progress)
        var transform = CGAffineTransform.identity
        transform = transform.translatedBy(x: 4.9 * baseSign, y: -0.6)
        transform = transform.translatedBy(x: -4.7 * progress, y: 0.7 * absProgress)

        transform = transform.scaledBy(x: 0.8, y: 0.8)
        transform = transform.scaledBy(x: (1 - 0.25 * absProgress), y: (1 - 0.25 * absProgress))

        transform = transform.rotated(by: getAngle(by: 10 * baseSign))
        transform = transform.rotated(by: getAngle(by: -15 * progress))

        imageView.transform = transform
        // 78 131 253
        // 149 180 252
        // 186 206 253
        // 225 234 255
        if TabBarViewImpl.isVIColor {
            imageView.tintColor = TabBarViewImpl.selectedColor.withAlphaComponent(0.4 - 0.25 * progress)
        } else {
//            imageView.tintColor = UIColorRGB(149 + 37 * absProgress,
//                                             180 + 26 * absProgress,
//                                             252 + 1 * absProgress)
            imageView.tintColor = color(from: flag1, to: flag2, progress: absProgress)
        }
    }

    private func stage3(imageView: UIImageView, progress: CGFloat, baseSign: CGFloat) {
        let absProgress = abs(progress)

        var transform = CGAffineTransform.identity
        transform = transform.translatedBy(x: 9.6 * baseSign, y: 0.1)
        transform = transform.translatedBy(x: -3.9 * progress, y: 1.4 * absProgress)

        transform = transform.scaledBy(x: 0.6, y: 0.6)
        transform = transform.scaledBy(x: (1 - 0.25 * absProgress), y: (1 - 0.25 * absProgress))

        transform = transform.rotated(by: getAngle(by: 25 * baseSign))
        transform = transform.rotated(by: getAngle(by: -20 * progress))

        imageView.transform = transform
        // 78 131 253
        // 149 180 252
        // 186 206 253
        // 225 234 255
        if TabBarViewImpl.isVIColor {
            imageView.tintColor = TabBarViewImpl.selectedColor.withAlphaComponent(0.15 - 0.15 * absProgress)
        } else {
//            imageView.tintColor = UIColorRGB(186 + 39 * absProgress,
//                                             206 + 28 * absProgress,
//                                             253 + 2 * absProgress)
            imageView.tintColor = color(from: flag2, to: flag3, progress: absProgress)
        }
        imageView.alpha = 1 - absProgress
    }
    /// 上一次的动画进度，用于判断是否需要执行动画
    private var oldProgress: CGFloat = 0

    /// 保存当前动画的进度，用于结束动画的调用
    private var currentProgress: CGFloat = 0 {
        didSet {
            oldProgress = oldValue
            if currentProgress == 0 && oldValue != 0 {
                resetTransform()
            }
        }
    }
    /// 结束动画的步长
    private var step: CGFloat = 0
    private var displayLink: CADisplayLink?
    /// 结束动画的过程中 不接收外部的动画调用
    private var isEndingAnimation = false
    /// 跳跃日期的动画控制
    private var jumpToProgress: CGFloat = 0

    @objc
    private func displayLinkHandler() {
        self.currentProgress -= step
        let state = abs(self.currentProgress - jumpToProgress)
        if abs(state) < abs(step) || state == 0 {
            self.currentProgress = jumpToProgress
            startAnimationIfNeeded(progress: self.currentProgress, direction: self.direction)
            isEndingAnimation = false
            displayLink?.isPaused = true
            displayLink?.invalidate()
            return
        }
        startAnimationIfNeeded(progress: self.currentProgress, direction: self.direction)
    }

    func endAnimation() {
        jumpToProgress(0.0)
    }

    func jumpToProgress(_ progress: CGFloat) {
        isEndingAnimation = true
        jumpToProgress = progress
        resetDisplayLink()
        /// 12.3 避免step为整数 导致看不出动画效果，大约为0.2秒动画
        step = (self.currentProgress - progress) / 12.3
        displayLink?.isPaused = false
    }

    private func resetDisplayLink() {
        displayLink?.invalidate()
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkHandler))
        displayLink?.add(to: RunLoop.main, forMode: .common)
    }

    private func resetTransform() {
        let originTrasform = CGAffineTransform.identity
        self.dateSelectedView.alpha = 1
        self.rightArrowImagwView.transform = originTrasform
        self.leftArrowImagwView.transform = originTrasform
        self.upArrowImagwView.transform = originTrasform
        self.downArrowImagwView.transform = originTrasform
        self.imageView1.transform = originTrasform
        self.imageView2.transform = originTrasform
        self.imageView3.transform = originTrasform

        wrapper.bringSubviewToFront(imageView1)
        wrapper.bringSubviewToFront(imageView2)
        wrapper.bringSubviewToFront(imageView3)
        self.bringIconViewToFront()
    }

    private func bringIconViewToFront() {
        wrapper.bringSubviewToFront(bgArrowView)
        wrapper.bringSubviewToFront(rightArrowImagwView)
        wrapper.bringSubviewToFront(leftArrowImagwView)
        wrapper.bringSubviewToFront(upArrowImagwView)
        wrapper.bringSubviewToFront(downArrowImagwView)
        wrapper.bringSubviewToFront(dateSelectedView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension TabBarViewImpl {

    typealias RGBComponent = (red: CGFloat, green: CGFloat, blue: CGFloat)

    enum UDTheme {
        case light
        case dark

        static var mode: Self {
            if #available(iOS 13.0, *) {
                return UDThemeManager.getRealUserInterfaceStyle() == .light ? UDTheme.light : UDTheme.dark
            } else {
                return .light
            }
        }
    }

    private var mode: TabBarViewImpl.UDTheme {
        return TabBarViewImpl.UDTheme.mode
    }

    // Light
    // 0: 78  131 253
    // 1: 149 180 252
    // 2: 186 206 253
    // 3: 225 234 255

    // Dark
    // 0: 46 101 209
    // 1: 40 81  163
    // 2: 32 62  120
    // 3: 25 42  76

    private func color(from: RGBComponent, to: RGBComponent, progress: CGFloat) -> UIColor {
        return UIColorRGB(from.red + (to.red - from.red) * progress,
                          from.green + (to.green - from.green) * progress,
                          from.blue + (to.blue - from.blue) * progress)
    }

    private var flag0: RGBComponent {
        return mode == .light ? (78, 131, 253) : (46, 101, 209)
    }

    private var flag1: RGBComponent {
        return mode == .light ? (149, 180, 252) : (40, 81, 163)
    }

    private var flag2: RGBComponent {
        return mode == .light ? (186, 206, 253) : (32, 62, 120)
    }

    private var flag3: RGBComponent {
        return mode == .light ? (225, 234, 255) : (25, 42, 76)
    }
}
