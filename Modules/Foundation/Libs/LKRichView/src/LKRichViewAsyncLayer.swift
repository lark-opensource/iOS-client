//
//  LKRichViewAsyncLayer.swift
//  LKRichView
//
//  Created by qihongye on 2019/9/26.
//

import UIKit
import Foundation

protocol LKRichViewAsyncLayerDelegate: CALayerDelegate {
    func updateTiledCache(tiledLayerInfos: [(CGImage, CGRect)], checksum: LKTiledCache.CheckSum, isCanceled: () -> Bool)
    func getTiledCache() -> LKTiledCache?
    func willDisplay(layer: LKRichViewAsyncLayer, seqID: Int32)
    func display(layer: LKRichViewAsyncLayer,
                 context: CGContext,
                 drawRect: CGRect,
                 seqID: Int32,
                 isCanceled: () -> Bool)
    func getRenderRunBoxs() -> [RunBox]
    func didDisplay(layer: LKRichViewAsyncLayer, seqID: Int32, tiledCache: LKTiledCache?)
    @available(iOS 13.0, *)
    func userInterfaceType() -> UIUserInterfaceStyle
    func isTiledCacheValid() -> Bool
}

final class LKRichViewAsyncLayer: CALayer {
    static let scale = UIScreen.main.scale
    static let renderQueues: [DispatchQueue] = [DispatchQueue(label: "LKRichView.render", qos: .userInitiated),
                                               DispatchQueue(label: "LKRichView.render", qos: .userInitiated)]
    private static var i: Int32 = 0

    static func getRenderQueue() -> DispatchQueue {
        let idx = Int32.max & OSAtomicIncrement32(&i)
        return renderQueues[Int(idx % Int32(renderQueues.count))]
    }

    var displayMode: DisplayMode = .auto {
        didSet {
            if displayMode != oldValue {
                setNeedsDisplay()
            }
        }
    }

    /// 分片渲染阀值（width * height），小于阈值，直接整体渲染，default：half of screen
    var maxTiledSize: UInt
    private var guardValue: Guard

    var debugOptions: ConfigOptions?

    /// 分片渲染时，设置所有需要渲染的分片layer
    private var tiledLayers: [LKRichViewTiledLayer] {
        get {
            (tiledLayerContainer.sublayers as? [LKRichViewTiledLayer]) ?? []
        }
        set {
            tiledLayerContainer.sublayers = newValue
        }
    }
    /// 分片渲染时，使用此layer容器进行渲染
    private var tiledLayerContainer = CALayer()

    override var sublayers: [CALayer]? {
        get {
            return super.sublayers
        }
        set {
            super.sublayers = [tiledLayerContainer] + (newValue ?? [])
        }
    }

    /// 获取除了tiledLayerContainer外的所有layer
    var sublayersExceptTiledContainer: [CALayer] {
        // 下标为0表示tiledLayerContainer，需要过滤
        guard let sublayers = super.sublayers?.suffix(from: 1) else {
            return []
        }
        return Array(sublayers)
    }

    override init() {
        guardValue = Guard()
        maxTiledSize = multiplication(UIScreen.main.bounds.size) / 2
        super.init()
        contentsScale = LKRichViewAsyncLayer.scale
        addSublayer(tiledLayerContainer)
    }

    override init(layer: Any) {
        guard let layer = layer as? LKRichViewAsyncLayer else {
            guardValue = Guard()
            self.maxTiledSize = multiplication(UIScreen.main.bounds.size) / 2
            super.init(layer: layer)
            return
        }
        self.guardValue = layer.guardValue
        self.maxTiledSize = layer.maxTiledSize
        super.init(layer: layer)
        contentsScale = LKRichViewAsyncLayer.scale
        displayMode = layer.displayMode
        debugOptions = layer.debugOptions
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        cancelLastDisplay()
    }

    override func insertSublayer(_ layer: CALayer, at idx: UInt32) {
        /// first sublayer is tiled container
        let idx = idx + 1
        guard let sublayers = sublayers, sublayers.count > idx else {
            assertionFailure()
            return
        }
        layer.removeFromSuperlayer()
        super.insertSublayer(layer, at: idx)
    }

    override func insertSublayer(_ layer: CALayer, below sibling: CALayer?) {
        guard let sibling = sibling else {
            insertSublayer(layer, at: 0)
            return
        }
        guard let index = sublayers?.firstIndex(of: sibling) else {
            assertionFailure()
            return
        }
        layer.removeFromSuperlayer()
        /// first sublayer is tiled container
        super.insertSublayer(layer, at: UInt32(index + 1))
    }

    override func insertSublayer(_ layer: CALayer, above sibling: CALayer?) {
        guard let sibling = sibling else {
            insertSublayer(layer, at: 0)
            return
        }
        guard let sublayers = sublayers,
              let index = sublayers.firstIndex(of: sibling) else {
            assertionFailure()
            return
        }
        layer.removeFromSuperlayer()
        if index < sublayers.count {
            /// first sublayer is tiled container
            super.insertSublayer(layer, at: UInt32(index + 1))
        } else {
            super.addSublayer(layer)
        }
    }

    override func display() {
        cancelLastDisplay()
        // 触发contents的KVC
        super.contents = super.contents

        guard let delegate = delegate as? LKRichViewAsyncLayerDelegate else {
            assertionFailure()
            setContents(nil, for: self)
            return
        }
        // 面积小于阈值，直接渲染
        if multiplication(bounds.size) <= maxTiledSize {
            _display(delegate)
            return
        }
        // 面积大于阈值，进入瓦片渲染，先检查是否有缓存，没有则直接重新渲染
        guard let tiledCache = delegate.getTiledCache() else {
            _displayWithTiled(delegate)
            return
        }

        // 命中缓存，需要检查下缓存的 darkMode 是否和当前一致，不一致需要重新渲染
        if #available(iOS 13, *) {
            if delegate.userInterfaceType().rawValue == tiledCache.checksum.userInterfaceStyle {
                _displayWithTiledCache(delegate, cache: tiledCache)
            } else {
                _displayWithTiled(delegate)
            }
        } else {
            _displayWithTiledCache(delegate, cache: tiledCache)
        }
    }

    private func cancelLastDisplay() {
        guardValue.increase()
    }

    /// 无需分片，直接整体渲染
    private func _display(_ delegate: LKRichViewAsyncLayerDelegate) {
        // 隐藏tiledLayerContainer，tiledLayerContainer是用来分片渲染的
        // 复用其他layer时，isHidden=false -> isHidden=true会触发layer的隐式动画，需要调用setContents把隐式动画去掉
        setContents(nil, for: self)
        tiledLayerContainer.isHidden = true
        // dark mode兼容
        var traitCollection: UITraitCollection?
        var prevTraitCollection: UITraitCollection?
        if #available(iOS 13.0, *) {
            // delegate.userInterfaceType得到的一定是正确的值
            traitCollection = UITraitCollection(userInterfaceStyle: delegate.userInterfaceType())
            prevTraitCollection = UITraitCollection.current
        }

        // sync draw
        if !self.isAsyncDisplay(isTiled: false) {
            // UIColor需要用到正确的dark mode值，所以delegate.display(...)前需要设置
            if #available(iOS 13.0, *), let collection = traitCollection {
                UITraitCollection.current = collection
            }
            delegate.willDisplay(layer: self, seqID: guardValue.value)
            let bitmap = createRenderBitmap(renderRect: bounds) { context in
                delegate.display(
                    layer: self, context: context, drawRect: bounds, seqID: guardValue.value, isCanceled: { false }
                )
            }
            setContents(bitmap.cgImage, for: self)
            delegate.didDisplay(layer: self, seqID: self.guardValue.value, tiledCache: nil)
            if #available(iOS 13.0, *), let traitCollection = prevTraitCollection {
                UITraitCollection.current = traitCollection
            }
            return
        }

        // async draw
        let oldGuardValue = guardValue.value
        delegate.willDisplay(layer: self, seqID: oldGuardValue)
        // 异步绘制会出现短时内多次绘制的情况，需要cancel前面的绘制流程
        func isCanceled() -> Bool {
            return oldGuardValue != self.guardValue.value
        }
        if bounds.width < 1 || bounds.height < 1 {
            setContents(nil, for: self)
            delegate.didDisplay(layer: self, seqID: oldGuardValue, tiledCache: nil)
            return
        }
        LKRichViewAsyncLayer.getRenderQueue().async { [bounds = self.bounds] in
            if isCanceled() {
                return
            }
            if #available(iOS 13.0, *), let collection = traitCollection {
                UITraitCollection.current = collection
            }
            let bitmap = self.createRenderBitmap(renderRect: bounds) { context in
                delegate.display(
                    layer: self,
                    context: context,
                    drawRect: bounds,
                    seqID: self.guardValue.value,
                    isCanceled: isCanceled
                )
            }
            if #available(iOS 13.0, *), let traitCollection = prevTraitCollection {
                UITraitCollection.current = traitCollection
            }
            runInMain {
                if isCanceled() {
                    return
                }
                setContents(bitmap.cgImage, for: self)
                delegate.didDisplay(layer: self, seqID: self.guardValue.value, tiledCache: nil)
            }
        }
    }

    private func createRenderBitmap(renderRect: CGRect, _ block: (CGContext) -> Void) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: renderRect.size)
        return renderer.image(actions: { renderCtx in
            let context = renderCtx.cgContext
            // 直接覆盖下层视图颜色
            if isOpaque {
                context.saveGState()
                let bgColor = self.backgroundColor ?? UIColor.white.cgColor
                context.setFillColor(bgColor.alpha < 1 ? UIColor.white.cgColor : bgColor)
                context.fill(renderRect)
                context.restoreGState()
            }
            block(context)
        })
    }

    /// 分片渲染
    private func _displayWithTiled(_ delegate: LKRichViewAsyncLayerDelegate) {
        setContents(nil, for: self)
        tiledLayerContainer.isHidden = true
        // 清除tiledLayers的content，准备复用
        self.clearTiled(fromIndex: 0)
        tiledLayerContainer.frame = self.bounds
        guard let hostView = self.delegate as? PaintInfoHostView else {
            assertionFailure()
            return
        }

        // dark mode兼容
        var traitCollection: UITraitCollection?
        var prevTraitCollection: UITraitCollection?
        var checksum = LKTiledCache.CheckSum(userInterfaceStyle: 0, isTiledCacheValid: delegate.isTiledCacheValid())
        if #available(iOS 13.0, *) {
            let userInterfaceStyle = delegate.userInterfaceType()
            traitCollection = UITraitCollection(userInterfaceStyle: userInterfaceStyle)
            prevTraitCollection = UITraitCollection.current
            checksum = LKTiledCache.CheckSum(userInterfaceStyle: userInterfaceStyle.rawValue, isTiledCacheValid: delegate.isTiledCacheValid())
        }
        let oldGuardValue = guardValue.value
        // 异步绘制会出现短时内多次绘制的情况，需要cancel前面的绘制流程
        func isCanceled() -> Bool {
            return oldGuardValue != self.guardValue.value
        }
        let tiledContext = TiledContext(isOpaque: isOpaque, backgroundColor: backgroundColor, hostView: hostView, hostBounds: bounds, debugOptions: debugOptions)
        var tiledLayerInfos = [(CGImage, CGRect)]()
        if !self.isAsyncDisplay(isTiled: true) {
            if #available(iOS 13.0, *), let collection = traitCollection {
                UITraitCollection.current = collection
            }
            self.tiledLayerContainer.isHidden = false
            delegate.willDisplay(layer: self, seqID: guardValue.value)

            let runBoxs = delegate.getRenderRunBoxs()
            var index = 0
            LKRichViewTiledManager.tiled(
                runBoxs: runBoxs,
                maxTiledSize: maxTiledSize,
                tiledContext: tiledContext,
                isCanceled: isCanceled,
                displayTiled: { bitmap, frame in
                    displayTiled(index: index) { tiledLayer in
                        setContents(bitmap.cgImage, for: tiledLayer, frame: frame)
                        if let cgImage = bitmap.cgImage {
                            tiledLayerInfos.append((cgImage, frame))
                        }
                    }
                    index += 1
                },
                tiledCompletion: {
                    delegate.updateTiledCache(tiledLayerInfos: tiledLayerInfos, checksum: checksum, isCanceled: isCanceled)
                    delegate.didDisplay(layer: self, seqID: self.guardValue.value, tiledCache: nil)
                }
            )
            if #available(iOS 13.0, *), let traitCollection = prevTraitCollection {
                UITraitCollection.current = traitCollection
            }
            return
        }
        // async draw
        delegate.willDisplay(layer: self, seqID: oldGuardValue)
        if bounds.width < 1 || bounds.height < 1 {
            delegate.didDisplay(layer: self, seqID: oldGuardValue, tiledCache: nil)
            return
        }
        LKRichViewAsyncLayer.getRenderQueue().async { [weak self] in
            guard let self = self, !isCanceled() else { return }
            if #available(iOS 13.0, *), let collection = traitCollection {
                UITraitCollection.current = collection
            }
            let runBoxs = delegate.getRenderRunBoxs()
            var index = 0
            LKRichViewTiledManager.tiled(
                runBoxs: runBoxs,
                maxTiledSize: self.maxTiledSize,
                tiledContext: tiledContext,
                isCanceled: isCanceled,
                displayTiled: { bitmap, frame in
                    runInMain { [index] in
                        if isCanceled() { return }
                        self.tiledLayerContainer.isHidden = false
                        self.displayTiled(index: index) { tiledLayer in
                            setContents(bitmap.cgImage, for: tiledLayer, frame: frame)
                        }
                        if let cgImage = bitmap.cgImage {
                            tiledLayerInfos.append((cgImage, frame))
                        }
                    }
                    index += 1
                },
                tiledCompletion: {
                    runInMain {
                        delegate.updateTiledCache(tiledLayerInfos: tiledLayerInfos, checksum: checksum, isCanceled: isCanceled)
                        delegate.didDisplay(layer: self, seqID: self.guardValue.value, tiledCache: nil)
                    }
                }
            )
            if #available(iOS 13.0, *), let traitCollection = prevTraitCollection {
                UITraitCollection.current = traitCollection
            }
        }
    }

    /// 分片渲染，命中缓存
    private func _displayWithTiledCache(_ delegate: LKRichViewAsyncLayerDelegate, cache: LKTiledCache) {
        setContents(nil, for: self)
        self.clearTiled(fromIndex: 0)
        tiledLayerContainer.isHidden = false
        tiledLayerContainer.frame = self.bounds
        delegate.willDisplay(layer: self, seqID: guardValue.value)

        let tiledLayerInfos = cache.tiledLayerInfos
        for index in 0..<tiledLayerInfos.count {
            let (bitmap, frame) = tiledLayerInfos[index]
            displayTiled(index: index) { tiledLayer in
                setContents(bitmap, for: tiledLayer, frame: frame)
            }
        }
        delegate.didDisplay(layer: self, seqID: guardValue.value, tiledCache: cache)
    }

    private func clearTiled(fromIndex: Int) {
        guard fromIndex < tiledLayers.count else {
            return
        }
        for i in fromIndex..<tiledLayers.count {
            let tiledLayer = tiledLayers[i]
            tiledLayer.contents = nil
            tiledLayer.isHidden = true
        }
    }

    private func displayTiled(index: Int, _ renderBlock: (LKRichViewTiledLayer) -> Void) {
        let count = tiledLayers.count
        if index < count {
            let tiledLayer = tiledLayers[index]
            tiledLayer.isHidden = false
            renderBlock(tiledLayer)
            return
        }
        for _ in count...index {
            tiledLayerContainer.addSublayer(LKRichViewTiledLayer())
        }

        // 遇到过连续crash，加个防护
        if index < tiledLayers.count {
            renderBlock(tiledLayers[index])
        } else {
            assertionFailure("index:\(index) count:\(tiledLayers.count) @yuanping.0 @liyong.520")
        }
    }

    private func isAsyncDisplay(isTiled: Bool) -> Bool {
        switch displayMode {
        case .async: return true
        case .sync: return false
        case .auto: return isTiled
        }
    }
}

struct Guard {
    private var _value: Int32 = 0

    var value: Int32 {
        return _value
    }

    mutating func increase() {
        OSAtomicIncrement32(&_value)
    }
}

@inline(__always)
func setContents(_ contents: CGImage?, for layer: CALayer, frame: CGRect? = nil) {
    CATransaction.setDisableActions(true)
    // 此处还需要把AnimationDuration置为0，否则在Cell复用且分片时，即使清空了Layer的contents，仍然会看到旧内容的残影
    // CATransaction.setDisableActions(true) & layer.removeAllAnimations()实验下来无法移除所有动画
    CATransaction.setAnimationDuration(0)
    layer.contents = contents
    if let frame = frame {
        layer.frame = frame
    }
}
