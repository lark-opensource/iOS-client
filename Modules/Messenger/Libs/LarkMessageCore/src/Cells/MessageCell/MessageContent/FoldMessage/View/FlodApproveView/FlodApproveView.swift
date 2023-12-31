//
//  FlodApproveView.swift
//  LarkMessageCore
//
//  Created by Bytedance on 2022/9/23.
//

import UIKit
import Foundation
import LarkUIKit
import Lottie
import LarkContainer
import LarkMessengerInterface
import LarkStorage

/// 回调给业务方点击事件
public protocol FlodApproveViewDelegate: AnyObject {
    /// 长按结束、连点结束、单击完成后，number：产生的最终数量，长按/连点未结束不会回调
    func didFinishApprove(_ flodApproveView: FlodApproveView, number: UInt)
    /// 开始点击、长按，触发连续点击不会持续回调，可以理解为didTapApprove和didFinishApprove肯定是配对出现的
    func didStartApprove(_ flodApproveView: FlodApproveView)

    func animationFilePath() -> IsoPath?
}

/// "加一个"按钮
public final class FlodApproveView: UIControl {
    deinit {
        /// iOS 10之后，系统已经优化了这个问题，Block回调方式 可以deinit 但是timer不会销毁
        if self.longPressNumberAnimationTimer != nil {
            self.longPressNumberAnimationTimer?.invalidate()
        }
    }
    /// 一些控制点击/长按行为、UI等的配置
    struct Config {
        /// 单击/长按间隔x内识别为连续点击，这个时间和数字动画Zoom时间一致，可以做到下降动画前点击/长按都会触发连续
        let intervalTimeForTap: CGFloat = 0.24 + 0.28
        /// 长按时，间隔多少时间数字+1
        let intervalTimeForLongPress: CGFloat = 0.16
        /// 按住多久算长按
        let longPressMinimumPressDuration: CGFloat = 0.17

        /// 烟花动画的size
        let fireworksAnimationViewSize: CGSize = CGSize(width: 264, height: 264)
        /// 烟花动画时长
        let fireworksAnimation: CGFloat = 1.0
        /// 烟花动画频控，如果上一个播放在xms内，则不放新的烟花
        let intervalTimeForIgnoreFireworksAnimation: CGFloat = 0.4

        /// 数字第一阶段放大动画时长
        let numberAnimationZoomUp: CGFloat = 0.24
        /// 数字第二阶段略微缩小动画时长
        let numberAnimationZoomDown: CGFloat = 0.28
        /// 数字第三阶段下降动画时长
        let numberAnimationMoveDown: CGFloat = 0.48
    }
    private let config = FlodApproveView.Config()
    /// 回调给业务方点击事件
    weak var delegate: FlodApproveViewDelegate?
    /// 当前的连续数量已经累计到多少了，触发回调后需要清空
    private var currContinuousTriggerNumber: UInt = 0
    /// 烟花动画视图缓存，Lottie动画解码耗时很长，所以短时间内连续触发则可复用
    private var fireworksAnimationCacheViews: [LOTAnimationView] = []
    /// 长按时的蒙层，实现按压态
    private lazy var pressMaskView: UIView = {
        let pressMaskView = UIView(frame: CGRect(origin: .zero, size: self.frame.size))
        pressMaskView.backgroundColor = UIColor.ud.udtokenBtnSeBgPriFocus
        pressMaskView.layer.cornerRadius = 18
        pressMaskView.isUserInteractionEnabled = false
        pressMaskView.isHidden = true
        return pressMaskView
    }()
    /// 一个空的视图，用来让烟花展示在数字动画后面
    private lazy var placeholderView = UIView(frame: self.bounds)
    private let touchEdgeInsets = UIEdgeInsets(top: -8, left: -12, bottom: -8, right: -12)

    // MARK: - 初始化

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.hitTestEdgeInsets = touchEdgeInsets
        self.isUserInteractionEnabled = true
        // 蒙层放底部，和UD规范对齐
        self.addSubview(self.pressMaskView)

        // layer的边框会被BorderStyleRender根据border复写，而我们没设置border，所以得自己加一个视图来做圆角
        // self.layer.borderColor = UIColor.ud.primaryContentDefault.cgColor
        // self.layer.borderWidth = 1
        // self.layer.cornerRadius = 18
        let view = UIView(frame: self.bounds)
        view.layer.borderColor = UIColor.ud.primaryContentDefault.cgColor
        view.layer.borderWidth = 1
        view.layer.cornerRadius = 18
        self.addSubview(view)

        // "+1"图片
        let imageView = UIImageView(image: BundleResources.foldApproveButton)
        imageView.frame = CGRect(origin: CGPoint(x: 24, y: 7), size: CGSize(width: 22, height: 22))
        self.addSubview(imageView)
        // "加一个"文本
        let label = UILabel(frame: CGRect(
            origin: CGPoint(x: imageView.frame.maxX + 4, y: 0),
            size: CGSize(width: frame.size.width - imageView.frame.maxX - 4 - 24, height: frame.size.height)
        ))
        label.numberOfLines = 1
        label.textColor = UIColor.ud.primaryContentDefault
        label.font = UIFont.systemFont(ofSize: 16)
        label.text = BundleI18n.LarkMessageCore.Lark_IM_StackMessage_MeToo_Button
        self.addSubview(label)
        // 占位
        self.addSubview(self.placeholderView)

        // 添加tap手势
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapFlodApproveView(tapGestureRecognizer:)))
        self.addGestureRecognizer(tapGestureRecognizer)
        // minimumPressDuration目前的值，是自己测试后发现的一个合理的值，没啥其他的原因
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressFlodApproveView(longPressGestureRecognizer:)))
        longPressGestureRecognizer.minimumPressDuration = self.config.longPressMinimumPressDuration
        self.addGestureRecognizer(longPressGestureRecognizer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - 单击手势处理
    @objc
    private func tapFlodApproveView(tapGestureRecognizer: UITapGestureRecognizer) {
        self.currContinuousTriggerNumber += 1
        self.showNumberAnimationWhenNumberChange(number: self.currContinuousTriggerNumber)
        self.showFireworksAnimationWhenNumberChangeIfNeeded()

        if self.currContinuousTriggerNumber == 1 { self.delegate?.didStartApprove(self) }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.triggerFlodApproveViewDelegate), object: nil)
        self.perform(#selector(self.triggerFlodApproveViewDelegate), with: nil, afterDelay: self.config.intervalTimeForTap)
    }

    // MARK: - 长按手势处理

    /// 长按时，启动的数字动画定时器，用于在长按结束时取消
    private var longPressNumberAnimationTimer: Timer?
    @objc
    private func longPressFlodApproveView(longPressGestureRecognizer: UILongPressGestureRecognizer) {
        let status = longPressGestureRecognizer.state
        // 开始长按
        if status == .began {
            self.pressMaskView.isHidden = false
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.triggerFlodApproveViewDelegate), object: nil)

            // 此时需要进行+1操作，因为识别长按需要一定时间，此时认为用户已经触发了连续
            self.currContinuousTriggerNumber += 1
            self.showNumberAnimationWhenNumberChange(number: self.currContinuousTriggerNumber)
            self.showFireworksAnimationWhenNumberChangeIfNeeded()
            if self.currContinuousTriggerNumber == 1 { self.delegate?.didStartApprove(self) }
            // 启动一个数字定时器，每隔一定时间执行一次数字动画
            self.longPressNumberAnimationTimer = Timer.scheduledTimer(withTimeInterval: self.config.intervalTimeForLongPress, repeats: true) { [weak self] _ in
                guard let self = self else {
                    return
                }
                self.currContinuousTriggerNumber += 1
                self.showNumberAnimationWhenNumberChange(number: self.currContinuousTriggerNumber ?? 0)
                self.showFireworksAnimationWhenNumberChangeIfNeeded()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            return
        }
        /// status 状态改变的是否 计算一下手势的偏移
        if status == .changed {
            let point = longPressGestureRecognizer.location(in: self)
            if point.x < touchEdgeInsets.left
                || point.x > (self.bounds.width - touchEdgeInsets.right)
                || point.y < touchEdgeInsets.top
                || point.y > self.bounds.height - touchEdgeInsets.bottom {
                self.removeGestureRecognizer(longPressGestureRecognizer)
                self.addGestureRecognizer(longPressGestureRecognizer)
            }
            return
        }
        // 长按结束
        if status == .ended || status == .cancelled || status == .failed {
            self.pressMaskView.isHidden = true
            self.longPressNumberAnimationTimer?.invalidate()
            self.longPressNumberAnimationTimer = nil
            self.perform(#selector(self.triggerFlodApproveViewDelegate), with: nil, afterDelay: self.config.intervalTimeForTap)
        }
    }

    // MARK: - 烟花动画

    /// 循环播放的两个烟花动画视图，取消连续点击时回收
    private var lastFireworksAnimationTime: TimeInterval = 0
    private func showFireworksAnimationWhenNumberChangeIfNeeded() {
        guard let path = self.delegate?.animationFilePath() else {
            return
        }
        let currTime = NSDate().timeIntervalSince1970
        // 忽略400s内的烟花动画，控频
        guard currTime - self.lastFireworksAnimationTime >= self.config.intervalTimeForIgnoreFireworksAnimation else { return }
        self.lastFireworksAnimationTime = currTime

        func createFireworksAnimationView() -> LOTAnimationView? {
            let fireworksAnimationView = LOTAnimationView(filePath: path.absoluteString)
            fireworksAnimationView.isUserInteractionEnabled = false
            fireworksAnimationView.frame = CGRect(origin: .zero, size: self.config.fireworksAnimationViewSize)
            fireworksAnimationView.frame.origin.x = (self.frame.width - fireworksAnimationView.frame.size.width) / 2
            fireworksAnimationView.frame.origin.y = 66 - fireworksAnimationView.frame.size.height
            return fireworksAnimationView
        }

        if let fireworksAnimationView = self.fireworksAnimationCacheViews.isEmpty ? createFireworksAnimationView() : self.fireworksAnimationCacheViews.remove(at: 0) {
            self.insertSubview(fireworksAnimationView, belowSubview: self.placeholderView)
            fireworksAnimationView.play()
            fireworksAnimationView.completionBlock = { [weak self] _ in
                fireworksAnimationView.stop()
                fireworksAnimationView.removeFromSuperview()
                self?.fireworksAnimationCacheViews.append(fireworksAnimationView)
            }
        }
    }

    // MARK: - 数字动画

    /// 缓存上一个数字动画视图，如果在zoom动画时间内用户触发连续，则复用此视图
    private var numberAnimationCacheView: UIView?
    /// 执行一次数字动画
    private func showNumberAnimationWhenNumberChange(number: UInt) {
        // 如果存在上一个数字动画，则直接复用
        if let previousView = self.numberAnimationCacheView {
            self.configNumberAnimationView(number: number, numberAnimationView: previousView)
            // 为了和烟花动画同步，这里重新等待缩放动画完成再执行下降动画
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.execMoveDownAnimation), object: nil)
            self.perform(#selector(self.execMoveDownAnimation), with: nil, afterDelay: self.config.numberAnimationZoomUp + self.config.numberAnimationZoomDown)
        } else {
            // 创建一个新的数字动画，放入复用池
            let numberAnimationView = UIView()
            self.numberAnimationCacheView = numberAnimationView
            self.configNumberAnimationView(number: number, numberAnimationView: numberAnimationView)
            self.insertSubview(numberAnimationView, aboveSubview: self.placeholderView)
            // 执行缩放动画
            numberAnimationView.transform = CGAffineTransform(scaleX: 0, y: 0)
            UIView.animate(withDuration: self.config.numberAnimationZoomUp) {
                numberAnimationView.transform = CGAffineTransformIdentity
            } completion: { _ in
                UIView.animate(withDuration: self.config.numberAnimationZoomDown) {
                    numberAnimationView.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
                }
            }
            // 等待缩放动画完成执行下降动画
            self.perform(#selector(self.execMoveDownAnimation), with: nil, afterDelay: self.config.numberAnimationZoomUp + self.config.numberAnimationZoomDown)
        }

        // 如果烟花动画完成后用户没有触发连续，我们就移除烟花动画复用池；x2是为了保证清除时机是在动画completionBlock回调执行后
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.clearFireworksAnimationCacheViews), object: nil)
        self.perform(#selector(self.clearFireworksAnimationCacheViews), with: nil, afterDelay: self.config.fireworksAnimation * 2)
    }

    /// 执行下降动画
    @objc
    private func execMoveDownAnimation() {
        let numberAnimationView = self.numberAnimationCacheView
        // 清空，表明后续数字动画不能再复用，需要新建一个数字动画视图
        self.numberAnimationCacheView = nil
        UIView.animate(withDuration: self.config.numberAnimationMoveDown) {
            numberAnimationView?.transform = CGAffineTransform(translationX: 0, y: 48 - (96 - 68) / 2 * 0.48).concatenating(CGAffineTransform(scaleX: 0.68, y: 0.68))
            numberAnimationView?.alpha = 0
        } completion: { _ in
            // 记得移除视图
            numberAnimationView?.removeFromSuperview()
        }
    }

    /// 配置数字动画视图的内容
    private func configNumberAnimationView(number: UInt, numberAnimationView: UIView) {
        // 配置当前应该展示的+、数字图片
        var numberAnimationViews: [UIImageView] = []
        var number = number
        while number > 0 {
            numberAnimationViews.insert(UIImageView(image: self.getFlodApproveImage(number: number % 10)), at: 0)
            number /= 10
        }
        numberAnimationViews.insert(UIImageView(image: BundleResources.flodAppprovePlus), at: 0)
        // 计算这些图片的总宽、高
        var allWidthForNumberAnimationViews: CGFloat = 0; var maxHeigthForNumberAnimationViews: CGFloat = 0
        numberAnimationViews.forEach { imageView in
            // +和后面的数字间隔为5
            if allWidthForNumberAnimationViews == 0 { allWidthForNumberAnimationViews += 5 }
            allWidthForNumberAnimationViews += imageView.frame.size.width
            maxHeigthForNumberAnimationViews = max(maxHeigthForNumberAnimationViews, imageView.frame.size.height)
        }
        // 调整numberAnimationView的frame
        numberAnimationView.frame.size = CGSize(width: allWidthForNumberAnimationViews, height: maxHeigthForNumberAnimationViews)
        numberAnimationView.center = CGPoint(x: self.frame.width / 2, y: -70 - numberAnimationView.frame.size.height / 2)

        // 把numberAnimationViews添加到numberAnimationView中
        numberAnimationView.subviews.forEach { $0.removeFromSuperview() }
        var currImageViewOffsetX: CGFloat = 0
        numberAnimationViews.forEach { imageView in
            imageView.frame.origin.x = currImageViewOffsetX
            imageView.frame.origin.y = (maxHeigthForNumberAnimationViews - imageView.frame.size.height) / 2
            numberAnimationView.addSubview(imageView)

            // +和后面的数字间隔为5
            if currImageViewOffsetX == 0 { currImageViewOffsetX += 5 }
            currImageViewOffsetX += imageView.frame.size.width
        }
    }

    /// 根据数字得到对应的图片
    private func getFlodApproveImage(number: UInt) -> UIImage {
        switch number {
        case 0:
            return BundleResources.flodAppprove0
        case 1:
            return BundleResources.flodAppprove1
        case 2:
            return BundleResources.flodAppprove2
        case 3:
            return BundleResources.flodAppprove3
        case 4:
            return BundleResources.flodAppprove4
        case 5:
            return BundleResources.flodAppprove5
        case 6:
            return BundleResources.flodAppprove6
        case 7:
            return BundleResources.flodAppprove7
        case 8:
            return BundleResources.flodAppprove8
        case 9:
            return BundleResources.flodAppprove9
        default:
            return BundleResources.flodAppprove0
        }
    }

    // MARK: - 其他事件

    /// 执行回调，传回最后一次触发连续的数字
    @objc
    private func triggerFlodApproveViewDelegate() {
        self.delegate?.didFinishApprove(self, number: self.currContinuousTriggerNumber)
        self.currContinuousTriggerNumber = 0
    }

    @objc
    private func clearFireworksAnimationCacheViews() {
        self.fireworksAnimationCacheViews.removeAll()
    }
}
