//
//  LKRichView.swift
//  LKRichView
//
//  Created by qihongye on 2019/8/26.
//

import Foundation
import UIKit

private let MAX_CGFLOAT: CGFloat = 100_000

struct Flags {
    var needLayout = true
}

final class DisplayLinkProxy: NSObject {
    weak var target: NSObjectProtocol?

    init(_ target: NSObjectProtocol) {
        self.target = target
        super.init()
    }

    override func responds(to aSelector: Selector!) -> Bool {
        return target?.responds(to: aSelector) ?? false
    }

    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        return target
    }
}

/// LKRichView使用文档：https://bytedance.feishu.cn/wiki/wikcntJLva4oFLQhz3u7GiHFMhg
open class LKRichView: UIView, PaintInfoHostView {
    /// [UIView init]时会访问该属性，设置layer
    public override class var layerClass: AnyClass {
        return LKRichViewAsyncLayer.self
    }

    /// AttachmentRunBox中绘制视图使用：1、添加block到本数组，2、在self.didDisplay(...)中执行本数组
    var displayAttachmentTasks: [(UIView) -> Void] = []
    var configOptions: ConfigOptions?
    var flags = Flags()
    /// 选中模式是通过启动CADisplayLink，然后触发enterVisualMode方法进入的
    var modeWatcher: CADisplayLink?

    private var _coreLock = os_unfair_lock_s()
    /// 提供tag、id、className级别的touch事件监听、分发
    private let eventCore = LKRichViewEventCore()

    private var _core = LKRichViewCore()
    var core: LKRichViewCore {
        get {
            os_unfair_lock_lock(&_coreLock)
            defer {
                os_unfair_lock_unlock(&_coreLock)
            }
            return _core
        }
        set {
            assert(Thread.isMainThread, "Must in main.")
            os_unfair_lock_lock(&_coreLock)
            _core = newValue
            os_unfair_lock_unlock(&_coreLock)
        }
    }

    /// selection相关：layer构建，更新光标、放大镜frame；使用方不要修改，纯属内部使用，因为特殊原因才public
    public var selectionModule: SelectionModule

    public weak var delegate: LKRichViewDelegate?
    public weak var selectionDelegate: LKRichViewSelectionDelegate?
    /// 展示selection相关layer
    public weak var containerView: UIView?

    /// 内容最大宽度限制
    public var preferredMaxLayoutWidth: CGFloat = -1

    /// You may set this  attributed in main thread.
    public var documentElement: LKRichElement? {
        didSet {
            guard let documentElement = documentElement else {
                invalidateIntrinsicContentSize()
                return
            }
            documentElement.debugOptions = configOptions
            flags.needLayout = true
            // 得到一颗RenderObject树
            let renderer = self.core.createRenderer(documentElement)
            self.resetRenderer(renderer)
            // 调用此方法让LKRichView重新获取一次intrinsicContentSize，进而执行LKRichViewCore的layout方法
            self.invalidateIntrinsicContentSize()
            self.setNeedsLayout()
            self.setNeedsDisplay()
        }
    }

    /// 同步、异步、分片渲染
    public var displayMode: DisplayMode {
        get {
            return asyncLayer?.displayMode ?? .auto
        }
        set {
            asyncLayer?.displayMode = newValue
        }
    }

    /// 分片渲染阀值（width * height），小于阈值，直接整体渲染，default：half of screen
    public var maxTiledSize: UInt {
        get {
            return asyncLayer?.maxTiledSize ?? 0
        }
        set {
            asyncLayer?.maxTiledSize = newValue
        }
    }

    public var startCursor: Cursor? {
        return configOptions?.startCursor
    }

    public var endCursor: Cursor? {
        return configOptions?.endCursor
    }

    /// 当前是否正在拖动前后光标
    var isDraggingCursor: Bool = false {
        didSet {
            guard isDraggingCursor != oldValue else {
                return
            }
            if isDraggingCursor {
                selectionDelegate?.willDragCursor(self)
            } else {
                selectionDelegate?.didDragCursor(self)
            }
        }
    }

    var asyncLayer: LKRichViewAsyncLayer? {
        return layer as? LKRichViewAsyncLayer
    }

    open override var isOpaque: Bool {
        get {
            return asyncLayer?.isOpaque ?? false
        }
        set {
            asyncLayer?.isOpaque = newValue
        }
    }

    private var _backgroundColor: UIColor?
    open override var backgroundColor: UIColor? {
        get {
            return _backgroundColor
        }
        set {
            _backgroundColor = newValue
            asyncLayer?.backgroundColor = newValue?.cgColor
        }
    }

    open override var bounds: CGRect {
        didSet {
            if flags.needLayout, bounds.size != oldValue.size {
                _ = core.layout(frame.size)
                invalidateIntrinsicContentSize()
            }
        }
    }

    public init(frame: CGRect = .zero, options: ConfigOptions = ConfigOptions()) {
        var options = options
        let startCursor = options.startCursor
        let endCursor = options.endCursor
        self.configOptions = options
        self.selectionModule = SelectionModule(startCursor: startCursor, endCursor: endCursor)
        super.init(frame: frame)
        self.asyncLayer?.debugOptions = options
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 进入/退出选中状态
    public func switchMode(_ mode: RichViewMode) {
        if mode == selectionModule.getMode() {
            return
        }
        if mode == .visual, modeWatcher == nil {
            modeWatcher = CADisplayLink(target: DisplayLinkProxy(self), selector: #selector(enterVisualMode))
            modeWatcher?.add(to: RunLoop.main, forMode: .default)
        }
        modeWatcher?.isPaused = mode != .visual
        /// 进入选中态的时候需要 becomeFirstResponder 用以响应iPad快捷键操作
        /// 退出选中态的时候 resignFirstResponder
        if mode == .visual, !isFirstResponder {
            becomeFirstResponder()
        } else if mode != .visual, isFirstResponder {
            resignFirstResponder()
        }
        selectionModule.enter(mode: mode)
    }

    public func loadStyleSheets(_ styleSheets: [CSSStyleSheet]) {
        core.load(styleSheets: styleSheets)
    }

    /// 自定义LKRichViewCore，调用此方法前，LKRichViewCore需要自己设置renderer并layout
    public func setRichViewCore(_ core: LKRichViewCore) {
        runInMain {
            self.flags.needLayout = false
            self.core = core
            self.setNeedsDisplay()
        }
    }

    public func findElement(by tag: LKRichElementTag) -> [(element: LKRichElement, rect: CGRect)] {
        return core.findElement(by: tag).map { ($0.element, $0.rect.convertCoreText2UIViewCoordinate(bounds)) }
    }

    /// 复制选中区域的内容
    public func getCopyString() -> NSAttributedString? {
        return core.getCopyString()
    }

    public func canSelectMoreAhead() -> Bool {
        return core.canSelectMoreAhead()
    }

    public func canSelectMoreAftwards() -> Bool {
        return core.canSelectMoreAftwards()
    }

    public func isSelectAll() -> Bool {
        return core.isSelectAll()
    }

    /// 正常情况不会走到draw方法，而是执行LKRichViewAsyncLayer的display方法；依然复写draw是为了处理异常情况
    open override func draw(_ rect: CGRect) {
        let renderer = UIGraphicsImageRenderer(size: rect.size)
        renderer.image { ctx in
            paintDocument(
                paintInfo: PaintInfo(
                    context: ctx.cgContext, rect: rect, hostView: self, debugOptions: configOptions
                )
            )
        }
    }

    open override var intrinsicContentSize: CGSize {
        if preferredMaxLayoutWidth > 0 {
            return sizeThatFits(CGSize(width: preferredMaxLayoutWidth, height: CGFloat.greatestFiniteMagnitude))
        }
        return sizeThatFits(CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude))
    }

    open override func systemLayoutSizeFitting(_ targetSize: CGSize) -> CGSize {
        return sizeThatFits(targetSize)
    }

    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        guard core.isRendererReady else {
            return super.sizeThatFits(size)
        }

        var layoutSize = size
        if layoutSize.width <= 0 {
            layoutSize.width = MAX_CGFLOAT
        }
        if layoutSize.height <= 0 {
            layoutSize.height = CGFloat.greatestFiniteMagnitude
        }
        if let size = core.layout(layoutSize) {
            return size
        }

        return super.sizeThatFits(size)
    }

    open override var canBecomeFirstResponder: Bool {
        return true
    }

    @discardableResult
    open override func resignFirstResponder() -> Bool {
        // 如果需要保持选中态则不退出
        if selectionModule.getMode() == .visual, !(self.delegate?.keepVisualModeWhenResignFirstResponder(self) ?? false) {
            leaveVisualMode()
        }
        return super.resignFirstResponder()
    }

    /// 自定义快捷键
    open override var keyCommands: [UIKeyCommand]? {
        if #available(iOS 13.0, *) {
            return [UIKeyCommand(action: #selector(copyTextCommand), input: "c", modifierFlags: .command)]
        }
        return [
            UIKeyCommand(
                input: "c", modifierFlags: .command, action: #selector(copyTextCommand), discoverabilityTitle: "Copy"
            )
        ]
    }

    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if self.isHidden {
            return nil
        }
        selectionModule.hitTest(with: event)
        selectionModule.performOtherEvent(false)
        if let cursor = configOptions?.startCursor,
           selectionModule.getMode() == .visual,
           cursor.hitTest(point, with: event) {
            return self
        }
        if let cursor = configOptions?.endCursor,
           selectionModule.getMode() == .visual,
           cursor.hitTest(point, with: event) {
            return self
        }
        /// In non selection mode, return `super.hitTest()` non null result firstly, then if `isPointerTouch` is matched, return self view.
        /// 在非选中态优先判断父类是否响应, 如果父类不响应则判断是否可以响应鼠标触摸拖拽
        for subview in subviews {
            if let view = subview.hitTest(convert(point, to: subview), with: event) {
                selectionModule.performOtherEvent(true)
                return view
            }
        }
        // point所处LKRichElement存在touch事件监听
        if getFirstPropTargetByBFS(point: convertPointFromUI2CG(point)) != nil {
            return self
        }
        // iPad touch事件
        if selectionModule.getCMDMode() == .touch && self.frame.contains(point) {
            return self
        }
        return nil
    }

    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let uiPoint = touches.first?.location(in: self) else {
            return
        }

        let cgPoint = convertPointFromUI2CG(uiPoint)

        // RichView hight priority event handles.
        if selectionModule.getMode() == .visual,
           let startCursor = configOptions?.startCursor,
           let endCursor = configOptions?.endCursor,
           let magnifier = configOptions?.magnifier {
            // 选中开始光标
            if startCursor.hitTest(uiPoint, with: event) {
                selectionModule.activeCursor = startCursor
            } else if endCursor.hitTest(uiPoint, with: event) {
                // 选中结束光标
                selectionModule.activeCursor = endCursor
            } else {
                // 没有选中开始/结束光标
                selectionModule.activeCursor = nil
            }

            if selectionModule.activeCursor != nil {
                self.window?.addSubview(magnifier.magnifierView)
                magnifier.targetView = self
                isDraggingCursor = true
                selectionModule.updateTextMagnifier(magnifier, richView: self)
                return
            }
        }

        // RichView user design event handles.
        eventHandle(point: cgPoint, touches: touches, event: event) { target, touchEvent in
            delegate?.touchStart(target, event: touchEvent, view: self)
        }

        // RichView low priority event handles.
    }

    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let uiPoint = touches.first?.location(in: self) else {
            return
        }

        let cgPoint = convertPointFromUI2CG(uiPoint)

        // RichView hight priority event handles.
        if let startCursor = configOptions?.startCursor,
           let endCursor = configOptions?.endCursor,
           let magnifier = configOptions?.magnifier,
           let activeCursor = selectionModule.activeCursor {
            var selectedRects: [CGRect]
            let writingMode: WritingMode
            let needExchange: Bool
            switch activeCursor.type {
            case .start:
                (selectedRects, writingMode, needExchange) = core.getSeletedRects(
                    start: cgPoint, end: convertPointFromUI2CG(endCursor.location.point)
                )
            case .end:
                (selectedRects, writingMode, needExchange) = core.getSeletedRects(
                    start: convertPointFromUI2CG(startCursor.location.point), end: cgPoint
                )
            }

            guard !selectedRects.isEmpty else {
                return
            }

            selectedRects = selectedRects.map { $0.convertCoreText2UIViewCoordinate(frame) }

            // 开始、结束光标交换位置
            if needExchange {
                selectionModule.exchangeActiveCursor()
            }
            selectionModule.setSelectedRects(selectedRects, writingMode: writingMode)
            // 更新光标、放大镜位置
            selectionModule.updateActiveCursour(point: uiPoint)
            selectionModule.updateTextMagnifier(magnifier, richView: self)
            selectionModule.renderSelectionFromStartToEnd(
                selectionColor: configOptions?.visualConfig?.selectionColor ?? UIColor.blue.withAlphaComponent(0.5)
            )
            return
        }

        // RichView user design event handles.
        eventHandle(point: cgPoint, touches: touches, event: event) { target, touchEvent in
            delegate?.touchMove(target, event: touchEvent, view: self)
        }

        // RichView low priority event handles.
    }

    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard var point = touches.first?.location(in: self) else {
            return
        }

        point = convertPointFromUI2CG(point)

        // RichView high priority event handles.
        if selectionModule.getMode() == .visual {
            // 标记当前没有拖动光标
            isDraggingCursor = false
        }
        // 移除放大镜
        configOptions?.magnifier.magnifierView.removeFromSuperview()
        configOptions?.magnifier.targetView = nil

        // RichView user design event handles.
        eventHandle(point: point, touches: touches, event: event) { target, touchEvent in
            delegate?.touchEnd(target, event: touchEvent, view: self)
        }

        // RichView low priority event handles.
    }

    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard var point = touches.first?.location(in: self) else {
            return
        }

        point = convertPointFromUI2CG(point)

        // RichView high priority event handles.
        if selectionModule.getMode() == .visual {
            // 标记当前没有拖动光标
            isDraggingCursor = false
        }
        // 移除放大镜
        configOptions?.magnifier.magnifierView.removeFromSuperview()
        configOptions?.magnifier.targetView = nil

        // RichView user design event handles.
        eventHandle(point: point, touches: touches, event: event) { target, touchEvent in
            delegate?.touchCancel(target, event: touchEvent, view: self)
        }
        // RichView low priority event handles.
    }

    public func commitDisplayTask(task: @escaping (UIView) -> Void) {
        self.displayAttachmentTasks.append(task)
    }

    fileprivate func paintDocument(paintInfo: PaintInfo) {
        guard core.isRendererReady else {
            return
        }
        let context = paintInfo.graphicsContext
        let paintRect = paintInfo.contextRect
        context.saveGState()
        /// y = paintRect.origin.y + paintRect.height + core.size.height - paintRect.height
        context.translateBy(x: paintRect.origin.x, y: paintRect.origin.y + core.size.height)
        context.scaleBy(x: 1, y: -1)
        core.render(paintInfo)
        context.restoreGState()
    }

    private func resetRenderer(_ renderer: RenderObject?) {
        guard let renderer = renderer else {
            return
        }
        if renderer.debugOptions == nil {
            renderer.debugOptions = configOptions
        }
        if flags.needLayout {
            core.load(renderer: renderer)
            // 生成一颗RunBox树，进行布局计算
            _ = core.layout(bounds.size)
            flags.needLayout = false
        }
    }

    @inline(__always)
    private func convertPointFromUI2CG(_ point: CGPoint) -> CGPoint {
        if let boxRect = core.getRenderer({ $0.boxRect }) {
            return CGPoint(x: point.x, y: boxRect.y + boxRect.height - point.y)
        }
        return CGPoint(x: point.x, y: bounds.height - point.y)
    }
}

/// For events.
extension LKRichView {
    @inline(__always)
    func eventHandle(
        point: CGPoint,
        touches: Set<UITouch>,
        event: UIEvent?,
        delegateHandler: (LKRichElement, LKRichTouchEvent?) -> Void) {
        guard let source = getFirstPropTargetByDFS(point: point) else { return }
        let touches = touches.map({ LKRichTouch(source: source, target: source, position: $0.location(in: self)) })
        if let event = event {
            var touchEvent = LKRichTouchEvent.create(touchStart: event, source: source, target: source, touches: touches)
            delegateHandler(source, touchEvent)
            var element = source
            while delegate != nil,
                  touchEvent.isPropagation,
                  let target = getPropagationTarget(source: element) {
                if target === element {
                    break
                }
                touchEvent = LKRichTouchEvent.create(touchStart: event, source: source, target: target, touches: touches)
                delegateHandler(target, touchEvent)
                element = target
            }
        } else {
            delegateHandler(source, nil)
        }
    }

    public func getElementByPoint(_ point: CGPoint) -> LKRichElement? {
        var pointNew = convertPointFromUI2CG(point)
        return getFirstPropTargetByDFS(point: pointNew)
    }

    func getFirstPropTargetByDFS(point: CGPoint) -> LKRichElement? {
        os_unfair_lock_lock(&_coreLock)
        let propagationListeners = eventCore.propagationListeners
        os_unfair_lock_unlock(&_coreLock)
        guard !propagationListeners.isEmpty else { return nil }
        return core.findRenderObjectByDFS { renderObject in
            return match(point: point, listeners: propagationListeners, target: renderObject)
        }?.ownerElement
    }

    func getFirstPropTargetByBFS(point: CGPoint) -> LKRichElement? {
        os_unfair_lock_lock(&_coreLock)
        let propagationListeners = eventCore.propagationListeners
        os_unfair_lock_unlock(&_coreLock)
        guard !propagationListeners.isEmpty else { return nil }
        return core.findRenderObjectByBFS { renderObject in
            return match(point: point, listeners: propagationListeners, target: renderObject)
        }?.ownerElement
    }

    func match(point: CGPoint, listeners: [CSSSelectorList], target: RenderObject) -> Bool {
        guard let node = target.ownerElement else { return false }
        return target.point(inside: point) && listeners.contains(where: { $0.match(node) })
    }

    func getPropagationTarget(source: LKRichElement) -> LKRichElement? {
        os_unfair_lock_lock(&_coreLock)
        defer {
            os_unfair_lock_unlock(&_coreLock)
        }
        if eventCore.hasPropagationListeners {
            while let target = source.parent, eventCore.matchPropagationListener(target: target) {
                return target as? LKRichElement
            }
            return nil
        }
        return nil
    }

    func getCatchTarget(source: LKRichElement) -> LKRichElement? {
        os_unfair_lock_lock(&_coreLock)
        defer {
            os_unfair_lock_unlock(&_coreLock)
        }
        if eventCore.hasCatchListeners {
            var target = source
            while let parent = source.parent {
                if eventCore.matchCatchListener(target: parent) {
                    if let element = parent as? LKRichElement {
                        target = element
                    }
                }
            }
            return target
        }
        return source
    }

    public func bindEvent(selectorLists: [[CSSSelector]], isPropagation: Bool) {
        os_unfair_lock_lock(&_coreLock)
        selectorLists.forEach { selectors in
            eventCore.bindEvent(selector: CSSSelectorList(selectors: selectors), isPropagation: isPropagation)
        }
        os_unfair_lock_unlock(&_coreLock)
    }

    public func bindEvent(selectors: [CSSSelector], isPropagation: Bool) {
        os_unfair_lock_lock(&_coreLock)
        eventCore.bindEvent(selector: CSSSelectorList(selectors: selectors), isPropagation: isPropagation)
        os_unfair_lock_unlock(&_coreLock)
    }

    public func unbindEvent(selectorLists: [[CSSSelector]], isPropagation: Bool) {
        os_unfair_lock_lock(&_coreLock)
        selectorLists.forEach { selectors in
            eventCore.unbindEvent(selector: CSSSelectorList(selectors: selectors), isPropagation: isPropagation)
        }
        os_unfair_lock_unlock(&_coreLock)
    }

    public func unbindEvent(selectors: [CSSSelector], isPropagation: Bool) {
        os_unfair_lock_lock(&_coreLock)
        eventCore.unbindEvent(selector: CSSSelectorList(selectors: selectors), isPropagation: isPropagation)
        os_unfair_lock_unlock(&_coreLock)
    }

    public func unbindAllEvent(isPropagation: Bool) {
        os_unfair_lock_lock(&_coreLock)
        eventCore.unbindAllEvent(isPropagation: isPropagation)
        os_unfair_lock_unlock(&_coreLock)
    }
}

extension LKRichView: LKRichViewAsyncLayerDelegate {
    func updateTiledCache(
        tiledLayerInfos: [(CGImage, CGRect)], checksum: LKTiledCache.CheckSum, isCanceled: () -> Bool
    ) {
        if isCanceled() { return }
        let cache = LKTiledCache(
            checksum: checksum,
            tiledLayerInfos: tiledLayerInfos,
            displayTasks: displayAttachmentTasks
        )
        if cache.displayTasks.isEmpty, cache.tiledLayerInfos.isEmpty { return }
        delegate?.updateTiledCache(self, cache: cache)
    }

    func getTiledCache() -> LKTiledCache? {
        return delegate?.getTiledCache(self)
    }

    func willDisplay(layer: LKRichViewAsyncLayer, seqID: Int32) {
        layer.removeAnimation(forKey: "contents")
        // subviews支持复用，willDisplay先隐藏，在didDisplay里复用完再移除，目前就LKAttachmentElement在添加/复用
        subviews.forEach({ $0.isHidden = true })
    }

    func display(layer: LKRichViewAsyncLayer,
                 context: CGContext,
                 drawRect: CGRect,
                 seqID: Int32,
                 isCanceled: () -> Bool) {
        if isCanceled() {
            return
        }
        self.paintDocument(paintInfo: PaintInfo(
            context: context,
            rect: drawRect,
            hostView: self,
            debugOptions: configOptions
        ))
    }

    func getRenderRunBoxs() -> [RunBox] {
        return core.getRenderRunBoxs()
    }

    func didDisplay(layer: LKRichViewAsyncLayer, seqID: Int32, tiledCache: LKTiledCache?) {
        // reset layers
        let validLayers = subviews.map({ $0.layer })
        let invalidLayers = layer.sublayersExceptTiledContainer.filter({ !validLayers.contains($0) })
        invalidLayers.forEach({ $0.removeFromSuperlayer() })

        // subviews支持复用，subViews目前就LKAttachmentElement在添加/复用
        subviews.forEach { $0.isValid = false }
        let displayTask = tiledCache?.displayTasks ?? displayAttachmentTasks
        for task in displayTask {
            task(self)
        }
        displayAttachmentTasks = []

        // reset unused subviews
        subviews.forEach { subview in
            // 移除所有未被使用的subview
            if !subview.isValid {
                subview.removeFromSuperview()
            }
        }

        delegate?.shouldShowMore(self, isContentScroll: self.core.isContentScroll)
    }

    @available(iOS 13.0, *)
    func userInterfaceType() -> UIUserInterfaceStyle {
        // userInterfaceStyle会在业务侧进行设置，值一定是正确的
        return self.traitCollection.userInterfaceStyle
    }

    func isTiledCacheValid() -> Bool {
        return core.isTiledCacheValid
    }
}
