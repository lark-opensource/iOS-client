//
//  SelectionLKLabel.swift
//  LarkUIKit
//
//  Created by qihongye on 2018/12/5.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import CoreText

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

open class LKSelectionLabel: LKLabel {
    public var pointerInteractionEnable: Bool = true

    public var seletionDebugOptions: LKSelectionLabelDebugOptions?

    public var options: SelectionLKLabelOptions

    public var inSelectionMode: Bool = false {
        didSet {
            guard inSelectionMode != oldValue else {
                return
            }
            startCursor.location = kCFNotFound
            startCursor.lineNo = kCFNotFound
            endCursor.location = kCFNotFound
            endCursor.lineNo = kCFNotFound
            selectRange = nil
            selectRangeLayer = nil
            if inSelectionMode, displayLink == nil {
                displayLink = CADisplayLink(target: DisplayLinkProxy(self), selector: #selector(initSelection))
                displayLink?.add(to: RunLoop.main, forMode: .default)
            }
            if !inSelectionMode {
                selectEnding()
            }
            processHitTest()
            displayLink?.isPaused = !inSelectionMode
            needUpdateSelection = true

            /// selectionLabel 进入选中态的时候需要 becomeFirstResponder 用以响应快捷键操作
            /// 退出选中态的时候 resignFirstResponder
            if inSelectionMode && !self.isFirstResponder {
                self.becomeFirstResponder()
            } else if !inSelectionMode && self.isFirstResponder {
                self.resignFirstResponder()
            }

            /// 当退出选中态的时候
            if !inSelectionMode {
                resetSelectionView()
            }
        }
    }

    /// 用于标记当前 selectionLabel 选中态是否已经完成初始化，避免重复初始化
    private var selectionDidInit: Bool = false

    public var initSelectedRange: NSRange? {
        didSet {
            guard initSelectedRange != oldValue else {
                return
            }
            startCursor.location = kCFNotFound
            startCursor.lineNo = kCFNotFound
            endCursor.location = kCFNotFound
            endCursor.lineNo = kCFNotFound
            if inSelectionMode {
                needUpdateSelection = true
            }
        }
    }

    public weak var selectionDelegate: LKSelectionLabelDelegate?

    public override init(frame: CGRect) {
        self.options = DefaultSelectionLKLabelOptions
        super.init(frame: frame)
        self.setupInteractions()
    }

    public init(options: SelectionLKLabelOptions? = nil) {
        self.options = options ?? DefaultSelectionLKLabelOptions
        super.init(frame: .zero)
        self.setupInteractions()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func drawText(in rect: CGRect) {
        super.drawText(in: rect)
        needUpdateSelectionLineRects = true
        needUpdateSelection = true
    }

    /// 成为第一响应者用来响应快捷键
    public override var canBecomeFirstResponder: Bool {
        return true
    }

    @discardableResult
    public override func resignFirstResponder() -> Bool {
        /// 失去第一响应时 同时退出选中态
        if self.inSelectionMode {
            self.inSelectionMode = false
        }
        return super.resignFirstResponder()
    }

    /// 支持复制快捷键
    public override var keyCommands: [UIKeyCommand]? {
        if #available(iOS 13.0, *) {
            return [UIKeyCommand(action: #selector(copyTextCommand), input: "c", modifierFlags: .command)]
        } else {
            return [UIKeyCommand(input: "c", modifierFlags: .command, action: #selector(copyTextCommand), discoverabilityTitle: "Copy")]
        }
    }

    /// 复制快捷键响应函数
    @objc
    func copyTextCommand() {
        if let selectedText = self.selectedText() {
            if let selectionDelegate = self.selectionDelegate,
               !selectionDelegate.selectionRangeHandleCopy(selectedText: selectedText) {
                return
            }
            UIPasteboard.general.string = selectedText
        }
    }
    /// 用于标记本次触摸是否触发了鼠标拖选行为
    private var isPointerDragTouch: Bool = false
    /// 是否需要检测当前 touch 是否是鼠标拖拽事件
    private var needCheckPointerDrag: Bool = false
    /// 用于检测鼠标拖拽，标记开始触摸位置
    private var pointerBeginLocation: CGPoint = .zero
    /// 最小鼠标位移，用于检测鼠标拖拽行为
    private let minPointerDragDistance: CGFloat = 5

    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        /// 判断是否是 pointer hover 事件
        let isPointerHover = event?.isPointerHover() ?? false
        /// 判断是否是 pointer 点击操作
        let isPointerTouch = event?.isPointerTouch() ?? false
        /// 当在选中态或者 hover 状态时， 判断 hittest
        if inSelectionMode || isPointerHover {
            if self.render.textRect.inset(by: touchInsets).contains(point) {
                return self
            }
            for cursor in [startCursor, endCursor] where cursor.hitTest(point) {
                return self
            }
        }
        /// 在非选中态优先判断父类是否响应, 如果父类不响应则判断是否可以响应鼠标触摸拖拽
        if let hitView = super.hitTest(point, with: event) {
            return hitView
        } else if isPointerTouch && self.frame.contains(point) {
            return self
        }
        return nil
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        /// 判断当前触摸是否是鼠标触摸
        let isPointerTouch = event?.isPointerTouch() ?? false
        /// 判断是否需要检测 是否是鼠标拖拽事件
        /// 判断条件 1. 父类没有响应 2. 是鼠标事件 3. 不在选中 mode
        self.needCheckPointerDrag = isPointerTouch &&
            super.hitTest(touches.first?.location(in: self) ?? .zero, with: event) == nil
            && !inSelectionMode
        activeCursorType = nil
        if inSelectionMode {
            let touchPoint = touches.first!.location(in: self)
            for cursor in [startCursor, endCursor] where cursor.hitTest(touchPoint) {
                activeCursorType = cursor.type
                break
            }

            if activeCursorType != nil {
                self.window?.addSubview(textRangeMagnifier.magifierView)
                textRangeMagnifier.targetView = self
                isInDragMode = true
                // 拖选 cursor 则不再检测鼠标拖拽
                needCheckPointerDrag = false
                updateTextRangeMagnifier()
            }
            // 已经在 selectionMode 状态中，需要判断是否对非选中区域进行再次拖拽
            // 判断当前是鼠标拖拽 且点击区域不再选中范围
            else if isPointerTouch,
                let path = self.selectedBezierPath(),
                !path.contains(touchPoint) {
                // 标记选中态 开始拖选位置
                pointerBeginLocation = touchPoint
                // 标记是否需要检测鼠标拖拽行为
                needCheckPointerDrag = true
            }
            DEBUG(true: {
                if seletionDebugOptions?.contains(.printTouchEvent) == true {
                    print("TouchStart => touchPoint: \(touchPoint), activeCursorType: \(String(describing: activeCursorType))")
                }
            })
            return
        }
        // 在非选中态中, 如果需要检测鼠标拖拽，则标记开始位置，并且把点击事件向下触底
        else if needCheckPointerDrag && isPointerTouch {
            let touchPoint = touches.first?.location(in: self) ?? .zero
            pointerBeginLocation = touchPoint
            self.next?.touchesBegan(touches, with: event)
            return
        }
        super.touchesBegan(touches, with: event)
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // 标记是否是鼠标点击事件
        let isPointerTouch = event?.isPointerTouch() ?? false
        if touches.count > 1 {
            return
        }
        // 非选中态且不需要检测鼠标拖拽，则有父类响应
        if !inSelectionMode && !(needCheckPointerDrag && isPointerTouch) {
            super.touchesMoved(touches, with: event)
            return
        }
        // 需要检测鼠标拖拽行为的话, 则判断鼠标位移
        else if needCheckPointerDrag && isPointerTouch {
            let touchPoint = touches.first?.location(in: self) ?? .zero
            let distance = sqrt(
                pow(touchPoint.x - pointerBeginLocation.x, 2) +
                pow(touchPoint.y - pointerBeginLocation.y, 2)
            )
            if distance > minPointerDragDistance {
                // 鼠标位移满足拖拽范围，进入鼠标拖拽
                needCheckPointerDrag = false
                // 如果没有在选中态, 则立刻进入选中态并完成初始化
                if !self.inSelectionMode {
                    self.inSelectionMode = true
                    self.initSelection()
                    self.isPointerDragTouch = true
                }
                self.isInDragMode = true
                startCursor.location = kCFNotFound
                startCursor.lineNo = kCFNotFound
                endCursor.location = kCFNotFound
                endCursor.lineNo = kCFNotFound
                // 根据拖拽位置初始化选中区域
                var startInfo: (CFIndex, LKTextLine, CFIndex)?
                var currentInfo: (CFIndex, LKTextLine, CFIndex)?

                if let lineIdx = pointAtLineIndex(point: touchPoint) {
                    let line = render.lines[lineIdx]
                    let idx = LKTextLineGetStringIndexForPosition(line, CGPoint(x: touchPoint.x, y: line.frame.midY), { $0 })
                    currentInfo = (lineIdx, line, idx)
                }
                if let lineIdx = pointAtLineIndex(point: pointerBeginLocation) {
                    let line = render.lines[lineIdx]
                    let idx = LKTextLineGetStringIndexForPosition(line, CGPoint(x: pointerBeginLocation.x, y: line.frame.midY), { $0 })
                    startInfo = (lineIdx, line, idx)
                }
                guard let startPointInfo = startInfo,
                    let currentPointInfo = currentInfo else {
                    return
                }
                // 根据拖动起始位置以及当前位置初始化 range
                if startPointInfo.2 < currentPointInfo.2 ||
                    (startPointInfo.2 == currentPointInfo.2 && touchPoint.x > pointerBeginLocation.x) {
                    self.activeCursorType = .end
                    updateActiveCursor(endCursor, lineNo: currentPointInfo.0, line: currentPointInfo.1, location: currentPointInfo.2)
                    updateActiveCursor(startCursor, lineNo: startPointInfo.0, line: startPointInfo.1, location: startPointInfo.2)
                } else {
                    self.activeCursorType = .start
                    updateActiveCursor(endCursor, lineNo: startPointInfo.0, line: startPointInfo.1, location: startPointInfo.2)
                    updateActiveCursor(startCursor, lineNo: currentPointInfo.0, line: currentPointInfo.1, location: currentPointInfo.2)
                }
                drawShadowFromStartToEnd()
                /// 取消事件传递
                self.next?.touchesCancelled(touches, with: event)
            }
            return
        }
        guard let activeCursor = self.getActiveCursor() else {
            return
        }
        let touchPoint = touches.first!.location(in: self)

        if let lineIdx = pointAtLineIndex(point: touchPoint) {
            let line = render.lines[lineIdx]
            let idx = LKTextLineGetStringIndexForPosition(line, CGPoint(x: touchPoint.x, y: line.frame.midY), { $0 })

            DEBUG(true: {
                if seletionDebugOptions?.contains(.printTouchEvent) == true {
                    print("TouchMove => activeCursor: \(activeCursor.type), lineNo: \(lineIdx), location: \(idx)")
                }
            })
            updateActiveCursor(activeCursor, lineNo: lineIdx, line: line, location: idx)
            updateTextRangeMagnifier()
            drawShadowFromStartToEnd()
        }
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // 如果本次触摸触发鼠标拖选 则通知 delegate，并重置状态
        if isPointerDragTouch {
            self.selectionDelegate?.selectionLabelWillEnterSelectionModeByPointerDrag(label: self)
            isPointerDragTouch = false
        }

        if inSelectionMode {
            selectEnding()
            let range = selectionRangeDidSelected()
            DEBUG(true: {
                if seletionDebugOptions?.contains(.printTouchEvent) == true {
                    print("TouchEnd => originSelectRange: \(String(describing: range))")
                }
            })
            // 选中态触摸结束 重置检测拖选标记
            self.needCheckPointerDrag = false
            return
        } else if needCheckPointerDrag {
            // 非选中态触摸，且需要检测拖选，则重置标记，且继续向下传递触摸事件
            self.needCheckPointerDrag = false
            self.next?.touchesEnded(touches, with: event)
            return
        }
        super.touchesEnded(touches, with: event)
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        // 如果本次触摸触发鼠标拖选 则通知 delegate，并重置状态
        if isPointerDragTouch {
            self.selectionDelegate?.selectionLabelWillEnterSelectionModeByPointerDrag(label: self)
            isPointerDragTouch = false
        }

        if inSelectionMode {
            selectEnding()
            let range = selectionRangeDidSelected()
            DEBUG(true: {
                if seletionDebugOptions?.contains(.printTouchEvent) == true {
                    print("TouchCancelled => originSelecteRange: \(String(describing: range))")
                }
            })
            // 选中态触摸结束 重置检测拖选标记
            self.needCheckPointerDrag = false
            return
        } else if needCheckPointerDrag {
            // 非选中态触摸，且需要检测拖选，则重置标记，且继续向下传递触摸事件
            self.needCheckPointerDrag = false
            self.next?.touchesEnded(touches, with: event)
            return
        }
        super.touchesCancelled(touches, with: event)
    }

    deinit {
        displayLink?.invalidate()
    }

    fileprivate var needUpdateSelection = false
    var isInDragMode = false {
        didSet {
            if isInDragMode != oldValue {
                self.selectionDelegate?.selectionDragModeUpdate(self.isInDragMode)
            }
        }
    }
    fileprivate var displayLink: CADisplayLink?

    fileprivate var _textRangeMagnifier: LKMagnifier?
    fileprivate var _startCursor: LKSelectionCursor?
    fileprivate var _endCursor: LKSelectionCursor?

    private var selectRange: NSRange? {
        didSet {
            if selectRange != oldValue,
                let selectRange = self.selectRange,
                let attributedTextLength = attributedText?.length {
                self.selectionDelegate?.selectionRangeDidUpdate(
                    self.textParser.parserRangeToOriginRange(selectRange, length: attributedTextLength)
                )
            }
        }
    }

    private var selectRangeLayer: CAShapeLayer? {
        didSet {
            oldValue?.removeFromSuperlayer()
            self.startCursor.layer.removeFromSuperlayer()
            self.endCursor.layer.removeFromSuperlayer()
            if let selectRangeLayer = self.selectRangeLayer {
                self.layer.addSublayer(selectRangeLayer)
                self.layer.addSublayer(self.startCursor.layer)
                self.layer.addSublayer(self.endCursor.layer)
            }
        }
    }
    private var needUpdateSelectionLineRects = true
    private var _selectionLineRects: [CGRect] = []
    private var selectionLineRects: [CGRect] {
        if needUpdateSelectionLineRects {
            needUpdateSelectionLineRects = false
            _selectionLineRects = getFixedRenderLineFrames()
        }

        return _selectionLineRects
    }
    private var activeCursorType: LKSelectionCursor.TypeEnum?

    /// 初始化 SlectionLabel 支持的 Interactions
    private func setupInteractions() {
        if UIDevice.current.userInterfaceIdiom != .pad {
            return
        }
        setupDragInteraction()
        setupPointerInteraction()
    }

    /// 重置 selection 相关 view
    private func resetSelectionView() {
        _startCursor?.layer.removeFromSuperlayer()
        _endCursor?.layer.removeFromSuperlayer()
        _textRangeMagnifier?.magifierView.removeFromSuperview()
        _startCursor = nil
        _endCursor = nil
        _textRangeMagnifier = nil
        selectRangeLayer = nil
        selectionDidInit = false
    }
}

extension LKSelectionLabel {
    public var startCursor: LKSelectionCursor {
        if let cursor = _startCursor {
            return cursor
        }
        _startCursor = options.startCursor ?? LKSelectionCursor(type: .start)
        _startCursor?.hitTestInsects = cursorTouchHitTestInsets
        _startCursor?.fillColor = cursorColor.cgColor
        return _startCursor!
    }

    public var endCursor: LKSelectionCursor {
        if let cursor = _endCursor {
            return cursor
        }
        _endCursor = options.endCursor ?? LKSelectionCursor(type: .end)
        _endCursor?.hitTestInsects = cursorTouchHitTestInsets
        _endCursor?.fillColor = cursorColor.cgColor
        return _endCursor!
    }

    var cursorTouchHitTestInsets: UIEdgeInsets {
        return self.options.cursorTouchHitTestInsets ?? UIEdgeInsets(top: -self.font.pointSize, left: -self.font.pointSize, bottom: -self.font.pointSize, right: -self.font.pointSize)
    }

    var selectionColor: UIColor {
        return options.selectionColor ?? UIColor.blue.withAlphaComponent(0.5)
    }

    var cursorColor: UIColor {
        return options.cursorColor ?? UIColor.blue
    }

    var touchInsets: UIEdgeInsets {
        return options.touchInsets ?? .zero
    }

    var textRangeMagnifier: LKMagnifier {
        if let magnifier = self._textRangeMagnifier {
            return magnifier
        }
        if let magnifier = options.textRangeMagnifier {
            self._textRangeMagnifier = magnifier
            return magnifier
        }
        let config = LKTextMagnifier.GraphicConfiguration(
            padding: 6,
            mangifierSize: CGSize(
                width: 120,
                height: 28
            ),
            radius: 6,
            arrow: 14,
            scale: 1.5
        )
        self._textRangeMagnifier = LKTextMagnifier(configuration: config)
        return self._textRangeMagnifier!
    }
}

extension LKSelectionLabel {
    func selectEnding() {
        if self.activeLink != nil {
            self.activeLink = nil
        }
        textRangeMagnifier.magifierView.removeFromSuperview()
        textRangeMagnifier.targetView = nil
        isInDragMode = false
    }

    func processHitTest() {
        if inSelectionMode {
            if let ancestor = lookupOuterParent(), let ancestorsFather = ancestor.superview {
                var labels = self.window?.selectionLabels ?? []
                labels.append(self)
                self.window?.selectionLabels = labels
                if let hittestView = self.window?.selectLabelHitTestView {
                    hittestView.delegateView = ancestor
                    ancestorsFather.insertSubview(hittestView, aboveSubview: ancestor)
                }
            }
        } else if let idx = self.window?.selectionLabels.firstIndex(where: { $0 == self }) {
            self.window?.selectionLabels.remove(at: idx)
        }
    }

    /// 寻找superview中最接近第一个恰好能装下hittest响应区域view的view
    func lookupOuterParent() -> UIView? {
        var view: UIView = self
        let startCursorHittestRect = startCursor.rect.inset(by: startCursor.hitTestInsects)
        let endCursorHittestRect = endCursor.rect.inset(by: endCursor.hitTestInsects)
        let topLeft = CGPoint(x: min(startCursorHittestRect.minX, 0), y: min(startCursorHittestRect.minY, 0))
        let bottomRight = CGPoint(x: max(endCursorHittestRect.maxX, bounds.maxX), y: max(endCursorHittestRect.maxY, bounds.maxY))
        let hittestRect = self.convert(CGRect(x: topLeft.x, y: topLeft.y, width: bottomRight.x - topLeft.x, height: bottomRight.y - topLeft.y), to: nil)
        while let superview = view.superview {
            if superview.convert(superview.bounds, to: nil).contains(hittestRect) {
                return view
            }
            view = superview
        }
        return nil
    }

    func pointAtLineIndex(point: CGPoint) -> CFIndex? {
        var start = 0
        var end = selectionLineRects.count - 1
        var lineIdx = 0
        while start < end {
            lineIdx = (start + end) / 2
            let rect = selectionLineRects[lineIdx]
            if point.y < rect.minY {
                end = lineIdx - 1
                continue
            }
            if point.y >= rect.maxY {
                start = lineIdx + 1
                continue
            }
            return lineIdx
        }
        if start == end {
            return start
        }
        return lineIdx
    }

    func findNextStringIndex(line: LKTextLine, location: CFIndex) -> CFIndex {
        let runIdx = LKTextLineGetTextRunIndexForStringIndex(line, location)
        guard runIdx != kCFNotFound, runIdx < line.runs.count else {
            return kCFNotFound
        }
        let run = line.runs[runIdx]
        let glyphIndex = LKTextRunGetGlyphIndexForStringIndex(run, location: location)
        if glyphIndex <= kCFNotFound {
            return run.range.location
        }
        if glyphIndex >= run.indices.count - 1 {
            return run.range.location + run.range.length
        }
        return run.indices[glyphIndex + 1]
    }

    func findPrevStringIndex(line: LKTextLine, location: CFIndex) -> CFIndex {
        let runIdx = LKTextLineGetTextRunIndexForStringIndex(line, location)
        guard runIdx != kCFNotFound, runIdx < line.runs.count else {
            return kCFNotFound
        }
        let run = line.runs[runIdx]
        let glyphIndex = LKTextRunGetGlyphIndexForStringIndex(run, location: location)
        if glyphIndex <= 0 {
            return run.range.location
        }
        if glyphIndex >= run.indices.count {
            return run.range.location + run.range.length
        }
        return run.indices[glyphIndex - 1]
    }

    func updateTextRangeMagnifier() {
        guard let activeCursorType = self.activeCursorType else {
            return
        }
        switch activeCursorType {
        case .start:
            textRangeMagnifier.sourceScanCenter = CGPoint(
                x: startCursor.rect.minX,
                y: startCursor.rect.minY + startCursor.rect.height / 2
            )
            textRangeMagnifier.magifierView.center = convert(CGPoint(
                x: startCursor.rect.minX,
                y: startCursor.rect.maxY
                    - startCursor.layer.frame.height
                    - textRangeMagnifier.magifierView.frame.height / 2
                    + 3
            ), to: nil)
        case .end:
            textRangeMagnifier.sourceScanCenter = CGPoint(
                x: endCursor.rect.maxX,
                y: endCursor.rect.minY + endCursor.rect.height / 2
            )
            textRangeMagnifier.magifierView.center = convert(CGPoint(
                x: endCursor.rect.maxX,
                y: endCursor.rect.maxY
                    - endCursor.layer.frame.height
                    - textRangeMagnifier.magifierView.frame.height / 2
                    + 3
            ), to: nil)
        }
        textRangeMagnifier.update()
    }

    func updateActiveCursor(_ cursor: LKSelectionCursor, lineNo: CFIndex, line: LKTextLine, location: CFIndex) {
        guard location != kCFNotFound else {
            return
        }
        let lineSelectionRect = self.selectionLineRects[lineNo]
        var offset: CGFloat = 0

        cursor.rect.origin.y = lineSelectionRect.origin.y
        cursor.rect.size.height = lineSelectionRect.height
        cursor.lineNo = lineNo

        switch cursor.type {
        case .start:
            cursor.location = location
            offset = LKTextLineGetOffsetForStringIndex(line, cursor.location)
            cursor.rect.origin.x = line.origin.x + offset
            if cursor.location >= endCursor.location {
                if cursor.location == endCursor.location {
                    cursor.location = findNextStringIndex(line: line, location: cursor.location)
                }
                self.activeCursorType = .end
                self.exchangeSelectionCursor()
            }
        case .end:
            cursor.location = findNextStringIndex(line: line, location: location)
            offset = LKTextLineGetOffsetForStringIndex(line, cursor.location)
            cursor.rect.origin.x = line.origin.x + offset
            if startCursor.location >= cursor.location {
                if cursor.location == startCursor.location {
                    cursor.location = findPrevStringIndex(line: line, location: cursor.location)
                }
                self.activeCursorType = .start
                self.exchangeSelectionCursor()
            }
        }
        selectRange = NSRange(
            location: startCursor.location,
            length: endCursor.location - startCursor.location
        )
    }

    func getActiveCursor() -> LKSelectionCursor? {
        guard let activeCursorType = self.activeCursorType else {
            return nil
        }
        switch activeCursorType {
        case .start:
            return startCursor
        case .end:
            return endCursor
        }
    }

    func exchangeSelectionCursor() {
        let rect = startCursor.rect
        let lineNo = startCursor.lineNo
        let location = startCursor.location
        startCursor.rect.origin.x = endCursor.rect.maxX
        startCursor.rect.origin.y = endCursor.rect.minY
        startCursor.lineNo = endCursor.lineNo
        startCursor.location = endCursor.location
        endCursor.rect.origin.x = rect.minX - endCursor.rect.width
        endCursor.rect.origin.y = rect.minY
        endCursor.lineNo = lineNo
        endCursor.location = location
    }

    func getFixedRenderLineFrames() -> [CGRect] {
        guard !self.render.lines.isEmpty else {
            return []
        }
        // 需要反转坐标系
        let transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: self.bounds.height)
        var lineFrames: [CGRect] = self.render.lines.map({ $0.frame.applying(transform) })

        if lineFrames.count == 1 {
            return lineFrames
        }
        for i in 1..<lineFrames.count {
            var lineSpace = lineFrames[i].minY - lineFrames[i - 1].maxY
            if lineSpace > 0 {
                lineSpace /= 2
                lineFrames[i - 1].size.height += lineSpace
                lineFrames[i].origin.y -= lineSpace
                lineFrames[i].size.height += lineSpace
            }
        }

        return lineFrames
    }

    func drawShadowFromStartToEnd() {
        guard startCursor.lineNo != kCFNotFound, endCursor.lineNo != kCFNotFound,
            startCursor.location < endCursor.location else {
                return
        }
        selectRangeLayer?.fillColor = selectionColor.cgColor
        let path = CGMutablePath()
        if startCursor.lineNo == endCursor.lineNo {
            path.addPath(CGPath(
                rect: CGRect(
                    x: startCursor.rect.origin.x,
                    y: startCursor.rect.origin.y,
                    width: endCursor.rect.maxX - startCursor.rect.minX,
                    height: selectionLineRects[startCursor.lineNo].height
                ),
                transform: nil
            ))
        } else {
            var startLineRect = selectionLineRects[startCursor.lineNo]
            startLineRect.size.width = self.render.textRect.maxX - startCursor.rect.minX
            startLineRect.origin = startCursor.rect.origin
            path.addPath(CGPath(rect: startLineRect, transform: nil))

            var endLineRect = selectionLineRects[endCursor.lineNo]
            endLineRect.size.width = endCursor.rect.maxX - self.render.textRect.minX
            endLineRect.origin.x = self.render.textRect.minX
            path.addPath(CGPath(rect: endLineRect, transform: nil))

            for var frame in selectionLineRects[startCursor.lineNo + 1..<endCursor.lineNo] {
                frame.size.width = self.render.textRect.maxX - self.render.textRect.minX
                frame.origin.x = self.render.textRect.minX
                path.addPath(CGPath(rect: frame, transform: nil))
            }
        }

        DEBUG(true: {
            if seletionDebugOptions?.contains(.drawStartEndRect) == true {
                path.addRects([startCursor.rect, endCursor.rect])
            }
            if seletionDebugOptions?.contains(.drawLineRect) == true {
                selectRangeLayer?.lineWidth = 1
                selectRangeLayer?.strokeColor = UIColor.red.cgColor
            }
        })
        selectRangeLayer?.path = path
        selectRangeLayer?.fillColor = selectionColor.cgColor
    }

    /// 返回当前选中文案的 Rect 数组
    private func selectedRects() -> [CGRect]? {
        guard startCursor.lineNo != kCFNotFound, endCursor.lineNo != kCFNotFound,
            startCursor.location < endCursor.location else {
                return nil
        }
        var rects: [CGRect] = []
        if startCursor.lineNo == endCursor.lineNo {
            rects.append(CGRect(
                x: startCursor.rect.origin.x,
                y: startCursor.rect.origin.y,
                width: endCursor.rect.maxX - startCursor.rect.minX,
                height: selectionLineRects[startCursor.lineNo].height
            ))
        } else {
            var startLineRect = selectionLineRects[startCursor.lineNo]
            startLineRect.size.width = self.render.textRect.maxX - startCursor.rect.minX
            startLineRect.origin = startCursor.rect.origin
            rects.append(startLineRect)

            var endLineRect = selectionLineRects[endCursor.lineNo]
            endLineRect.size.width = endCursor.rect.maxX - self.render.textRect.minX
            endLineRect.origin.x = self.render.textRect.minX
            rects.append(endLineRect)

            for var frame in selectionLineRects[startCursor.lineNo + 1..<endCursor.lineNo] {
                frame.size.width = self.render.textRect.maxX - self.render.textRect.minX
                frame.origin.x = self.render.textRect.minX
                rects.append(frame)
            }
        }
        return rects
    }

    /// 返回当前选中区域的 UIBezierPath
    func selectedBezierPath() -> UIBezierPath? {
        guard let selectedRects = self.selectedRects() else {
            return nil
        }
        let path: UIBezierPath = UIBezierPath()
        selectedRects.forEach { (rect) in
            path.append(.init(rect: rect))
        }
        return path
    }

    @objc
    func initSelection() {
        guard inSelectionMode else {
            selectRangeLayer = nil
            return
        }
        guard needUpdateSelection,
            !isInDragMode,
            !render.lines.isEmpty,
            !selectionLineRects.isEmpty,
            self._attributedText != nil,
            let visibleTextRange = self.render.visibleTextRange else {
                return
        }

        guard !selectionDidInit else { return }
        selectionDidInit = true

        needUpdateSelection = false
        self.selectRange = visibleTextRange
        if let initSelectedRange = self.initSelectedRange {
            let lower = self.textParser.getParserIndex(from: initSelectedRange.lowerBound)
            let upper = self.textParser.getParserIndex(from: initSelectedRange.upperBound - 1) + 1
            if lower >= 0, upper <= visibleTextRange.upperBound {
                self.selectRange = NSRange(location: lower, length: upper - lower)
            }
        }
        selectRangeLayer = CAShapeLayer()
        let selectRange = self.selectRange!

        if let lineIdx = self.render.lines.firstIndex(where: { $0.range.location <= selectRange.lowerBound && selectRange.lowerBound <= $0.range.location + $0.range.length }) {
            let line = self.render.lines[lineIdx]
            let offset: CGFloat = LKTextLineGetOffsetForStringIndex(line, selectRange.location)
            startCursor.lineNo = lineIdx
            startCursor.location = selectRange.location
            startCursor.rect = selectionLineRects[lineIdx]
            startCursor.rect.size.width = 0
            startCursor.rect.origin.x += offset
            startCursor.fillColor = cursorColor.cgColor
        }

        if let lineIdx = self.render.lines.firstIndex(where: { $0.range.location <= selectRange.upperBound && selectRange.upperBound <= $0.range.location + $0.range.length }) {
            let line = self.render.lines[lineIdx]
            let offset = LKTextLineGetOffsetForStringIndex(line, selectRange.upperBound)
            endCursor.location = selectRange.upperBound
            endCursor.lineNo = lineIdx
            endCursor.rect = selectionLineRects[lineIdx]
            endCursor.rect.origin.x += offset
            endCursor.rect.size.width = 0
            endCursor.fillColor = cursorColor.cgColor
        }

        drawShadowFromStartToEnd()
    }

    private func selectionRangeDidSelected() -> NSRange? {
        guard let attributedText = self.attributedText,
            let _attributedText = self._attributedText,
            let selectRange = self.selectRange,
            let originSelectRange = self.originSelectRange(),
            selectRange.length > 0 else {
                return nil
        }
        if originSelectRange.upperBound <= attributedText.length,
            selectRange.upperBound <= _attributedText.length {
            self.selectionDelegate?.selectionRangeDidSelected(
                originSelectRange,
                didSelectedAttrString: attributedText.attributedSubstring(from: originSelectRange),
                didSelectedRenderAttributedString: _attributedText.attributedSubstring(from: selectRange)
            )
        } else {
            assertionFailure("Range out of bounds, pls @李勇")
        }
        return originSelectRange
    }

    /// 获取当前选中文案
    func selectedText() -> String? {
        guard let attributedText = self.attributedText,
            let _attributedText = self._attributedText,
            let selectRange = self.selectRange,
            let originSelectRange = self.originSelectRange(),
            selectRange.length > 0 else {
                return nil
        }
        if originSelectRange.upperBound <= attributedText.length,
            selectRange.upperBound <= _attributedText.length {
            let didSelectedAttrString = attributedText.attributedSubstring(from: originSelectRange)
            let didSelectedRenderAttributedString = _attributedText.attributedSubstring(from: selectRange)
            let copyText = self.selectionDelegate?.selectionRangeText(
                originSelectRange,
                didSelectedAttrString: didSelectedAttrString,
                didSelectedRenderAttributedString: didSelectedRenderAttributedString
            ) ?? didSelectedAttrString.string
            return copyText
        } else {
            assertionFailure("Range out of bounds, pls @李勇")
        }
        return nil
    }

    /// 获取选中原始属性字符串的 range
    func originSelectRange() -> NSRange? {
        guard let attributedText = self.attributedText,
            let selectRange = self.selectRange,
            selectRange.length > 0 else {
                return nil
        }
        let originSelectRange = self.textParser.parserRangeToOriginRange(selectRange, length: attributedText.length)
        return originSelectRange
    }
}

extension UIEvent {
    /// check UIEvent is pointer hover
    /// - Returns: return result
    func isPointerHover() -> Bool {
        if #available(iOS 13.4, *) {
            return self.type == .hover
        } else {
            return false
        }
    }

    /// check UIEvent is pointer touch
    /// - Returns: return result
    func isPointerTouch() -> Bool {
        if #available(iOS 13.4, *) {
            return self.type == .touches && self.buttonMask.rawValue != 0
        } else {
            return false
        }
    }
}
