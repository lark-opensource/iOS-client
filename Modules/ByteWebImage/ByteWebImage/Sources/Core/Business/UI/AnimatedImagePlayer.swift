//
//  AnimatedImagePlayer.swift
//  ByteWebImage
//
//  Created by bytedance on 2021/3/23.
//

import UIKit

public enum AnimatedImageAnimationType {
    /// 正序播放
    case order
    /// 往复播放
    case reciprocating
}

protocol AnimatedImagePlayerDelegate: AnyObject {

    func imagePlayer(_ player: AnimatedImagePlayer, didUpdateImage image: UIImage, at index: Int)

    func imagePlayer(_ player: AnimatedImagePlayer, didPlayAnimationRepeatCount repeatCount: UInt)

    func imagePlayerDidStartPlaying(_ player: AnimatedImagePlayer)

    func imagePlayerDidStopPlaying(_ player: AnimatedImagePlayer)

    func imagePlayerDidReachEnd(_ player: AnimatedImagePlayer)
}

extension AnimatedImagePlayerDelegate {

    func imagePlayerDidStartPlaying(_ player: AnimatedImagePlayer) {}

    func imagePlayerDidStopPlaying(_ player: AnimatedImagePlayer) {}

    func imagePlayerDidReachEnd(_ player: AnimatedImagePlayer) {}
}

private class AnimatedImagePlayerWeakProxy {

    weak var target: AnimatedImagePlayer?

    init(_ target: AnimatedImagePlayer?) {
        self.target = target
    }

    @objc func nextFrame() {
        target?.nextFrame()
    }
}

/**
 player不会预先批量取帧缓存，仅保证提前取下一帧的缓存，如果循环次数大于一且当前条件能保证缓存全部帧，则不释放已播放帧，否则每播放一帧释放当前帧并异步预加载下一帧
 为什么：
 1.动图基本都是顺序播放的，播放器永远关心的都是下一帧，如果不能保证所有帧都缓存下来，则永远不能命中缓存，缓存越多越浪费性能
 2.异步加载下一帧仅保证主线程的性能和时间戳的准确性，动图一般帧率不高，基本能边解码边播放，如果手机性能不能保证边解码边播放预加载只会让性能更差，不如降低帧率，不影响主线程性能。
 */
class AnimatedImagePlayer {

    weak var delegate: AnimatedImagePlayerDelegate?

    /// 是否自动处理内存缓存，默认为YES，仅在cacheAllFrame == false时生效
    var automaticallyCacheFrames: Bool = true
    /// 强制缓存所有帧，默认为false
    var cacheAllFrame: Bool = false
    /// 循环次数，超过循环次数停留在最后一帧
    var loopCount: UInt = 1
    var runLoopMode: RunLoop.Mode = .common
    var animationType: AnimatedImageAnimationType = .order

    private(set) var image: ByteImage?
    private(set) var isPlaying: Bool = false
    private(set) var currentFrame: AnimateImageFrame?

    private var currentLoop: UInt = 0
    private var displayLink: CADisplayLink?
    private let framePrefetchQueue = DispatchSafeQueue(label: "com.bt.image.frame.fetch")

    /// 缓存任务
    private var frameCache: [Int: AnimateImageFrame] = [:]
    private var cachedIndexes = IndexSet()
    private var cacheLock = pthread_mutex_t()

    /// 解码任务
    private var taskIndexes = IndexSet()
    private var taskLock = pthread_mutex_t()

    /// 正逆序(往复播放)标识
    /// true: 正序; false: 逆序
    private var reciprocatingFlag = true

    private static let supportFormats: [ImageFileFormat] = [.webp, .heif]

    required init?(_ image: ByteImage?) {
        guard let image, image.isAnimatedImage else { return nil }

        if Self.supportFormats.contains(image.imageFileFormat), image.animatedImageData != nil, !image.bt.loading {
            self.image = try? ByteImage(image.animatedImageData, scale: image.scale, enableAnimatedDownsample: image.enableAnimatedDownsample)
            self.image?.bt.loading = image.bt.loading
            self.image?.bt.requestKey = image.bt.requestKey
            self.image?.bt.webURL = image.bt.webURL
            self.image?.bt.isDidScaleDown = image.bt.isDidScaleDown
        } else {
            self.image = image
        }

        if self.image?.bt.loading ?? false {
            self.loopCount = 1
        } else {
            self.loopCount = image.loopCount ?? 1
        }

        pthread_mutex_init(&cacheLock, nil)
        pthread_mutex_init(&taskLock, nil)

        addNotifications()
    }

    deinit {
        removeNotifications()
        delegate = nil
        stopPlaying()
        pthread_mutex_destroy(&cacheLock)
        pthread_mutex_destroy(&taskLock)
    }

    // MARK: - Actions

    func startPlaying(from index: Int = 0) {
        if index == 0 {
            _startPlaying()
            return
        }

        framePrefetchQueue.async { [weak self] in
            guard let self else { return }
            self.currentFrame = self.image?.frame(at: index)

            DispatchMainQueue.async { [weak self] in
                guard let self else { return }
                if let delay = self.currentFrame?.delay, delay > 0 {
                    // ToDo: 这里为什么要延迟开始播放，可能存在问题
                    DispatchMainQueue.asyncAfter(deadline: .now() + delay) { [weak self] in
                        self?._startPlaying()
                    }
                } else {
                    self._startPlaying()
                }
            }
        }
    }

    private func _startPlaying() {
        if isPlaying { return }
        isPlaying = true

        if displayLink == nil {
            displayLink = CADisplayLink(target: AnimatedImagePlayerWeakProxy(self), selector: #selector(AnimatedImagePlayerWeakProxy.nextFrame))
        }
        displayLink?.add(to: .main, forMode: runLoopMode)
        displayLink?.isPaused = false

        delegate?.imagePlayerDidStartPlaying(self)

        if automaticallyCacheFrames {
            calculateMaxCacheFrameCount()
        } else {
            maxCacheFrameCount = 1
        }

        prefetchNextFrameIfNeeded()
    }

    func pausePlaying() {
        isPlaying = false
        displayLink?.isPaused = true
    }

    func stopPlaying() {
        displayLink?.invalidate()
        displayLink = nil
        if isPlaying {
            isPlaying = false
            delegate?.imagePlayerDidStopPlaying(self)
        }
        if !(image?.bt.loading ?? false) {
            currentFrame = nil
            currentLoop = 0
            resetFrameCache()
        }
    }

    /// 渐进式图片加载
    func updateProgressImage(_ image: ByteImage?) {
        guard let image, image.bt.requestKey != self.image?.bt.requestKey,
              image != self.image, Self.supportFormats.contains(image.imageFileFormat) else {
            return
        }
        self.image?.changeImage(with: image.animatedImageData)
        self.image?.bt.loading = false
        self.loopCount = self.image?.loopCount ?? 0
    }

    // MARK: - Private Function

    fileprivate func nextFrame() {
        guard let displayLink, let image, isPlaying, displayLink.timestamp > (currentFrame?.nextFrameTime ?? 0) else {
            return
        }
        var nextFrameIndex = 0
        let frameCount = Int(image.frameCount)
        switch animationType {
        case .order:
            if let currentIndex = currentFrame?.index {
                nextFrameIndex = Int(currentIndex) + 1
                if nextFrameIndex >= frameCount {
                    if !image.bt.loading {
                        delegate?.imagePlayerDidReachEnd(self)
                    }
                    if loopCount == 0 || currentLoop + 1 < loopCount {
                        nextFrameIndex = 0
                        currentLoop += 1
                        delegate?.imagePlayer(self, didPlayAnimationRepeatCount: currentLoop)
                    } else {
                        stopPlaying()
                        return
                    }
                }
            } else {
                nextFrameIndex = 0
            }
        case .reciprocating:
            if let cIndex = currentFrame?.index {
                let currentIndex = Int(cIndex)
                if currentIndex == 0 {
                    reciprocatingFlag = true
                } else if currentIndex == frameCount - 1 {
                    reciprocatingFlag = false
                }
                nextFrameIndex = reciprocatingFlag ? currentIndex + 1 : currentIndex - 1
            } else {
                reciprocatingFlag = true
                nextFrameIndex = 0
            }
        }

        if pthread_mutex_trylock(&cacheLock) != 0 {
            return
        }
        let frame = frameCache[nextFrameIndex]
        let mustCacheFrame = animationType == .reciprocating && Self.supportFormats.contains(image.imageFileFormat)
        if (!mustCacheFrame && !cacheAllFrame && frame != nil && frameCount > maxCacheFrameCount) || image.bt.loading {
            frameCache.removeValue(forKey: nextFrameIndex)
            cachedIndexes.remove(nextFrameIndex)
        }
        pthread_mutex_unlock(&cacheLock)

        if let frame {
            var preFrameTime = currentFrame?.nextFrameTime ?? 0
            if preFrameTime < frame.delay || preFrameTime + frame.delay < displayLink.timestamp {
                // 第一帧没有上一帧的时间，用当前时间
                // 上一帧的时候与当时时间差太多，用当前时间
                preFrameTime = displayLink.timestamp
            }
            currentFrame = frame
            currentFrame?.nextFrameTime = preFrameTime + frame.delay
            delegate?.imagePlayer(self, didUpdateImage: frame.image, at: nextFrameIndex)
        }
        prefetchNextFrameIfNeeded()
    }

    private func resetFrameCache() {
        cancelPrefetch = true
        needCalculateMaxCacheFrameCount = true
        if pthread_mutex_trylock(&cacheLock) != 0 {
            return
        }
        if isPlaying, let frameCount = image?.frameCount, frameCount > 1, let (nextFrameIndex, _) = getNextFrameIndex(Int(frameCount)) {
            let reverse = .reciprocating == animationType && !reciprocatingFlag
            frameCache.keys.forEach { key in
                guard (reverse && key > nextFrameIndex) || (!reverse && key < nextFrameIndex) else {
                    return
                }
                frameCache.removeValue(forKey: key)
                cachedIndexes.remove(key)
            }
        } else {
            frameCache.removeAll()
            cachedIndexes.removeAll()
        }
        pthread_mutex_unlock(&cacheLock)
    }

    /// 获取下一帧位置
    /// - Parameter frameCount: 总帧数
    /// - Returns: (下一帧位置, 循环数变化量)；返回 nil 代表无下一帧(即已播放完成)
    private func getNextFrameIndex(_ frameCount: Int) -> (nextFrameIndex: Int, loopCountDlt: UInt)? {
        switch animationType {
        case .order:
            // 1. 获取当前帧(无当前帧，则下一帧为第0帧)
            guard let currentIndex = currentFrame?.index else {
                return (0, 0)
            }
            // 2. 如果下一帧已经超出最大帧数
            var index = Int(currentIndex) + 1
            var dlt: UInt = 0
            if index >= frameCount {
                // 无限循环 / 循环次数未达到，则下一帧为第0帧
                if loopCount == 0 || currentLoop + 1 < loopCount {
                    index = 0
                    dlt = 1
                } else {
                    return nil
                }
            }
            return (index, dlt)
        case .reciprocating:
            // 1. 获取当前帧(无当前帧，则下一帧为第0帧)
            guard let cIndex = currentFrame?.index else {
                reciprocatingFlag = true
                return (0, 0)
            }
            let currentIndex = Int(cIndex)
            // 2. 检查边界，修正正逆序
            if currentIndex == 0 {
                reciprocatingFlag = true
            } else if currentIndex == frameCount - 1 {
                reciprocatingFlag = false
            }
            let index = reciprocatingFlag ? currentIndex + 1 : currentIndex - 1
            return (index, 0)
        }
    }

    // MARK: - Prefetch Frame

    private var cancelPrefetch = false

    private func prefetchNextFrameIfNeeded() {
        guard let image else { return }
        if needCalculateMaxCacheFrameCount, automaticallyCacheFrames {
            calculateMaxCacheFrameCount()
        }
        cancelPrefetch = false

        guard let (nextFrameIndex, _) = getNextFrameIndex(Int(image.frameCount)) else {
            return
        }

        // 通过 taskIndexes 对解码的Task进行限制，保证不会重复发起同一个解码Task
        pthread_mutex_lock(&taskLock)
        if taskIndexes.contains(nextFrameIndex) {
            pthread_mutex_unlock(&taskLock)
            return
        }
        taskIndexes.insert(nextFrameIndex)
        pthread_mutex_unlock(&taskLock)

        framePrefetchQueue.async { [weak self] in
            guard let self else { return }

            pthread_mutex_lock(&self.cacheLock)
            let needDecode = !self.cachedIndexes.contains(nextFrameIndex) && self.frameCache.count < (self.image?.frameCount ?? 0)
            if !needDecode || self.cancelPrefetch {
                pthread_mutex_lock(&self.taskLock)
                self.taskIndexes.remove(nextFrameIndex)
                pthread_mutex_unlock(&self.taskLock)
                pthread_mutex_unlock(&self.cacheLock)
                return
            }

            var frame = self.image?.frame(at: nextFrameIndex)
            frame?.index = UInt(nextFrameIndex)
            if frame != nil {
                self.frameCache[nextFrameIndex] = frame
                self.cachedIndexes.insert(nextFrameIndex)
            }
            pthread_mutex_lock(&self.taskLock)
            self.taskIndexes.remove(nextFrameIndex)
            pthread_mutex_unlock(&self.taskLock)
            pthread_mutex_unlock(&self.cacheLock)
        }
    }

    // MARK: - Cache Frame Count

    private var needCalculateMaxCacheFrameCount = false
    private var maxCacheFrameCount = 0

    private func calculateMaxCacheFrameCount() {
        guard let cgImage = image?.cgImage else {
            return
        }

        let total = Double(DeviceMemory.totalSize)
        let free = Double(DeviceMemory.availableSize)
        guard total > 0, free > 0 else {
            maxCacheFrameCount = 1
            return
        }

        var bytesPerRow = Double(cgImage.bytesPerRow)
        if bytesPerRow == 0 {
            bytesPerRow = 4 * Double(cgImage.width)
        }

        let bytes = bytesPerRow * Double(cgImage.height)
        guard bytes > 0 else {
            maxCacheFrameCount = 1
            needCalculateMaxCacheFrameCount = false
            return
        }

        let maxRatio = 0.2
        let ratio = max(maxRatio, free / total)
        let minAvailableMB: Double = 20
        let available = min(minAvailableMB * 1024 * 1024, free * ratio)
        let maxCount = max(1, available / bytes)
        maxCacheFrameCount = Int(maxCount)
        needCalculateMaxCacheFrameCount = false
    }

    // MARK: - Notification

    private func addNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveMemoryWarning(_:)), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    private func removeNotifications() {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func didReceiveMemoryWarning(_ notification: Notification) {
        self.resetFrameCache()
    }

    @objc func applicationDidEnterBackground(_ notification: Notification) {
        displayLink?.isPaused = true
    }

    @objc func applicationDidBecomeActive(_ notification: Notification) {
        displayLink?.isPaused = false

        needCalculateMaxCacheFrameCount = true
    }
}

extension AnimatedImagePlayer: Hashable {

    static func == (lhs: AnimatedImagePlayer, rhs: AnimatedImagePlayer) -> Bool {
        lhs === rhs
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(Unmanaged.passUnretained(self).toOpaque())
    }
}
