//
//  ByteImageView.swift
//  ByteWebImage
//
//  Created by bytedance on 2021/3/23.
//

import UIKit

public protocol AnimatedViewDelegate: AnyObject {
    /// Called after the animatedImageView has finished each animation loop.
    ///
    /// - Parameters:
    ///   - imageView: The `AnimatedImageView` that is being animated.
    ///   - count: The looped count.
    func animatedImageView(_ imageView: ByteWebImage.ByteImageView, didPlayAnimationLoops count: UInt)

    /// Called after the `AnimatedImageView` has reached the max repeat count.
    ///
    /// - Parameter imageView: The `AnimatedImageView` that is being animated.
    func animatedImageViewDidFinishAnimating(_ imageView: ByteWebImage.ByteImageView)
    /// Called after frame changed
    func animatedImageViewCurrentFrameIndex(_ imageView: ByteWebImage.ByteImageView, image: UIImage, index: Int)
    /// Called after AnimatedImagePlayerIsPrepare
    func animatedImageViewReadyToPlay(_ imageView: ByteWebImage.ByteImageView)
    /// Called after first frame has played
    func animatedImageViewHasPlayedFirstFrame(_ imageView: ByteWebImage.ByteImageView)
    /// Called after AnimatedImageView has completed
    func animatedImageViewCompleted(_ imageView: ByteWebImage.ByteImageView)
}

extension AnimatedViewDelegate {
    func animatedImageView(_ imageView: ByteWebImage.ByteImageView, didPlayAnimationLoops count: UInt) {}
    func animatedImageViewDidFinishAnimating(_ imageView: ByteWebImage.ByteImageView) {}
    func animatedImageViewReadyToPlay(_ imageView: ByteWebImage.ByteImageView) {}
    func animatedImageViewHasPlayedFirstFrame(_ imageView: ByteWebImage.ByteImageView) {}
    func animatedImageViewCompleted(_ imageView: ByteWebImage.ByteImageView) {}
    func animatedImageViewCurrentFrameIndex(_ imageView: ByteWebImage.ByteImageView, image: UIImage, index: Int) {}
}

/// 图片展示容器，对动图播放有针对性优化
///
/// 关键属性和方法：
/// * 开始播放：``play()``  或 ``startAnimating()`` 或 ``play(at:)``
/// * 暂停播放：``pause()``
/// * 停止播放：``stop()`` 或 ``startAnimating()``
/// * 播放模式：``animateRunLoopMode``
/// * 是否自动播放：``autoPlayAnimatedImage``（默认在 addToWindow 时开始播放）
open class ByteImageView: UIImageView {

    private(set) var animateEnable: Bool = true
    private(set) var animatedImage: ByteImage? {
        didSet {
            guard let animatedImage = self.animatedImage else {
                if self.player != nil {
                    self.player?.stopPlaying()
                    self.player = nil
                    self.currentAnimateFrame = nil
                }
                return
            }
            self.player = AnimatedImagePlayer(animatedImage)
            if self.loopCount > 0 {
                self.player?.loopCount = self.loopCount
            }
            self.player?.animationType = self.animationType
            self.player?.automaticallyCacheFrames = self.frameCacheAutomatically
            self.player?.cacheAllFrame = self.cacheAllFrame
            self.player?.runLoopMode = self.animateRunLoopMode
            self.player?.delegate = self
            self.animatedDelegate?.animatedImageViewReadyToPlay(self)
        }
    }

    private var player: AnimatedImagePlayer?

    public weak var animatedDelegate: AnimatedViewDelegate?
    public var animateRunLoopMode: RunLoop.Mode = RunLoop.Mode.common
    public var animationType: AnimatedImageAnimationType = .order
    /// 自动缓存动图的帧
    public var frameCacheAutomatically: Bool = true
    /// 是否缓存所有帧
    public var cacheAllFrame: Bool = false
    /// 是否自动播放（默认在 addToWindow 时开始播放）
    public var autoPlayAnimatedImage: Bool = true
    public var hightAnimationControl: Bool = true
    /// did move to nil window 时，是否保持动图播放资源(pause or stop)
    ///
    /// 默认为 false 以自动清理播放资源，节省内存。为 true 时下次可以从暂停的帧继续播放
    public var pauseOnMoveToNilWindow: Bool = false
    /// 指定起始播放帧
    public var forceStartIndex: Int = 0
    /// 指定起始播放帧图，避免黑帧
    public var forceStartFrame: UIImage?

    /// 是否正在播放
    public var isPlaying: Bool {
        return self.player?.isPlaying ?? false
    }

    /// 循环次数，默认一直循环
    public var loopCount: UInt = UInt.max {
        didSet {
            if loopCount == oldValue {
                return
            }
            self.player?.loopCount = loopCount
        }
    }

    open override var image: UIImage? {
        get {
            return self.animatedImage ?? super.image
        }
        set {
            self.setImage(newValue, new: true)
        }
    }

    public override var isHighlighted: Bool {
        // 点击 UIImageView 会调用到 setHighlighted，系统会调用 UIImageView.stopAnimating
        didSet {
            if self.hightAnimationControl {
                if self.animatedImage != nil {
                    if isHighlighted && self.highlightedImage != nil {
                        self.stopAnimating()
                    } else if self.autoPlayAnimatedImage && !self.isPlaying {
                        self.tryPlay()
                    }
                }
            }
        }
    }

    /// 当前动图展示图片, 用户 frame 变化时刷新 layer
    private var currentAnimateFrame: UIImage?

    deinit {
        self.player?.stopPlaying()
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        // frame 发生变化会触发 imageView 根据 image 重新绘制，这里判断
        // currentAnimateFrame，重新更新为当前正在展示的动画帧
        // 这里没有向 player 中直接获取是因为，player 内部 currentFrame 可能还没有完成初始化
        if self.animatedImage != nil,
           self.player != nil,
           let current = self.currentAnimateFrame {
            self.layer.contents = current.cgImage
        }
    }

    // newImage 是否是新的iamge
    func setImage(_ image: UIImage?, new newImage: Bool) {
        if #available(iOS 13.0, *) {
            self.setImage(forIOS13: image, new: newImage)
            return
        }
        super.image = image
        if newImage && image != self.animatedImage {
            // 新设置image，image为空则停止播放
            if self.animatedImage != nil {
                self.animatedImage = nil
                self.tryStop()
                self.player = nil
                self.currentAnimateFrame = nil
            }
            if let image = image as? ByteImage, image.isAnimatedImage {
                self.animatedImage = image
            }
            super.image = image
            if self.animateEnable && self.autoPlayAnimatedImage {
                self.tryPlay()
            }
        } else if !self.isHighlighted || (self.isHighlighted && self.highlightedImage == nil) {
            // 动图更新帧，如果image为空，则不处理，相当于丢一帧, player 为空，不接受动图帧更新
            if let image = image, self.player != nil {
                self.layer.contents = image.cgImage
                self.currentAnimateFrame = image
            }
        }
    }

    // MARK: - Ovrride

    /// 开始播放
    open override func startAnimating() {
        if animatedImage != nil {
            play()
            return
        }
        super.startAnimating()
    }

    /// 停止播放
    open override func stopAnimating() {
        if animatedImage != nil {
            stop()
            return
        }
        super.stopAnimating()
    }

    /// 默认在 move to non nil window 时开始播放，move to nil window 时停止播放
    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if self.autoPlayAnimatedImage {
            if self.window != nil {
                self.tryPlay()
            } else {
                if self.pauseOnMoveToNilWindow {
                    // pause 保留动图播放信息（第x帧），下次能继续在第x帧开始播放
                    self.pause()
                } else {
                    self.tryStop()
                }
            }
        }
    }

    public override var description: String {
        "\(super.description); image = \(self.image?.description ?? "nil")"
    }

    // MARK: - Func
    /// 开始播放
    public func play() {
        self.tryPlay(true)
    }
    /// 从指定帧开始播放
    public func play(at index: Int) {
        if index != 0, let newImage = self.forceStartFrame {
            self.setImage(newImage, new: false)
        }
        self.player?.startPlaying(from: index)
    }
    /// 暂停播放
    public func pause() {
        self.player?.pausePlaying()
    }
    /// 停止播放
    public func stop() {
        self.tryStop()
        self.forceStartIndex = 0
    }

    // MARK: - Private

    private func setImage(forIOS13 image: UIImage?, new newImage: Bool) {
        // 非新设置image的话，如果某一帧解码失败，那么丢弃掉，如果新设置image，相当于置空
        if newImage {
            guard let image = image else {
                self.animatedImage = nil
                self.tryStop()
                super.image = nil
                self.player = nil
                self.currentAnimateFrame = nil
                return
            }
            if image == self.animatedImage {
                return
            }
            if self.animatedImage != nil {
                self.animatedImage = nil
                self.tryStop()
                self.player = nil
                self.currentAnimateFrame = nil
            }
            if let image = image as? ByteImage, image.isAnimatedImage {
                self.animatedImage = image
            }
            super.image = image
            // 如果支持自动播放则直接 tryPlay，否则初始化 forceStartFrame
            if self.animateEnable && self.autoPlayAnimatedImage {
                self.tryPlay()
            }
        } else if !self.isHighlighted || (self.isHighlighted && self.highlightedImage == nil) {
            if let image = image, self.player != nil {
                self.layer.contents = image.cgImage
                self.currentAnimateFrame = image
            }
        }
    }

    private func tryPlay(_ forcePlay: Bool = false) {
        // 如果是外部调用的play，那么不在window上满足条件也播放
        guard (self.window != nil || forcePlay),
              self.animatedImage != nil,
              self.animateEnable
        else { return }
        self.play(at: forceStartIndex)
    }

    private func tryStop() {
        self.player?.stopPlaying()
    }
}

extension ByteImageView: AnimatedImagePlayerDelegate {

    func imagePlayer(_ player: AnimatedImagePlayer, didUpdateImage image: UIImage, at index: Int) {
        guard self.player == player else { return }

        if let transformer = bt.imageRequest?.transformer {
            setImage(transformer.transformImageBeforeStore(with: image), new: false)
        } else {
            setImage(image, new: false)
        }
        animatedDelegate?.animatedImageViewCurrentFrameIndex(self, image: image, index: index)
    }

    func imagePlayer(_ player: AnimatedImagePlayer, didPlayAnimationRepeatCount repeatCount: UInt) {
        animatedDelegate?.animatedImageView(self, didPlayAnimationLoops: repeatCount)
    }

    func imagePlayerDidStartPlaying(_ player: AnimatedImagePlayer) {
        animatedDelegate?.animatedImageViewHasPlayedFirstFrame(self)
    }

    func imagePlayerDidStopPlaying(_ player: AnimatedImagePlayer) {
        animatedDelegate?.animatedImageViewDidFinishAnimating(self)
    }

    func imagePlayerDidReachEnd(_ player: AnimatedImagePlayer) {
        animatedDelegate?.animatedImageViewCompleted(self)
    }
}
