//
//  LKCanvasView.swift
//  LarkCanvas
//
//  Created by Saafo on 2021/2/2.
//

import UIKit
import Foundation
import LarkUIKit
import LKCommonsLogging
import PencilKit
import UniverseDesignColor
import UniverseDesignTheme

/// Encapsulation of PKCanvasView, PKDrawing &  PKToolPicker
@available(iOS 13.0, *)
public final class LKCanvasView: UIView, PKCanvasViewDelegate, PKToolPickerObserver {

    // MARK: Components

    /// canvas
    public var canvasView: WrappedPKCanvasView

    /// toolPicker
    public var toolPicker: PKToolPicker?

    /// background view beneath the drawing
    /// - Note: Temporarily is pure-white, but as a todo to support more ability in the future,
    ///         see design doc of LarkCanvas
    public var backgroundView = UIView()

    /// a temperarily reference for undoManager
    private weak var _undoManagerReference: UndoManager?

    /// Logger
    static let logger = Logger.log(LKCanvasView.self, category: "Module.LarkCanvas.View")

    // MARK: Attributes

    /// canvasView allow scale
    public var canvasCanScale: Bool

    /// real size of canvasView ( won't be effected by scale )
    public var canvasViewRealSize: CGSize {
        return CGSize(
            width: canvasView.contentSize.width / canvasView.zoomScale,
            height: canvasView.contentSize.height / canvasView.zoomScale
        )
    }

    /// whether canvasView contains any drawing
    public var canvasIsNotEmpty: Bool {
        return canvasView.drawing.bounds != .null
    }

    /// tool picker obscured frame
    public func getToolPickerObscuredHeight(for traitCollection: UITraitCollection?) -> CGFloat {
        if Display.pad && traitCollection?.horizontalSizeClass == .regular {
            return 0
        } else {
            return 95 // the toolPicker dock height seems always to be 95 so far
        }
    }

    /// The drawing policy that controls the types of touches that are allowed to draw in the canvas.
    public var drawingPolicy: PKCanvasViewDrawingPolicy {
        get {
            if #available(iOS 14.0, *) {
                return canvasView.drawingPolicy
            } else {
                return canvasView.allowsFingerDrawing ? .anyInput : .pencilOnly
            }
        }
        set {
            if #available(iOS 14.0, *) {
                canvasView.drawingPolicy = newValue
            } else {
                if let visiable = toolPicker?.isVisible,
                   visiable == false && newValue == .default {
                    canvasView.allowsFingerDrawing = false
                } else {
                    canvasView.allowsFingerDrawing = newValue != .pencilOnly
                }
            }
        }
    }

    /// Delegate
    public weak var delegate: LKCanvasViewDelegate?

    // MARK: Initialization

    public override init(frame: CGRect) {
        // Initialize Components
        self.canvasView = WrappedPKCanvasView()
        self.canvasCanScale = false

        super.init(frame: frame)

        // Set up canvas view
        setupCanvasView(canvasView: canvasView, with: backgroundView)
    }

    /// set up a canvasView just after init
    private func setupCanvasView(canvasView: WrappedPKCanvasView, with backgroundView: UIView) {
        // Init with empty drawing
        canvasView.delegate = self
        canvasView.lkCanvasView = self
        // manully set empty drawing to call `didFinishRendering` when view did appear
        canvasView.drawing = PKDrawing()
        canvasView.alwaysBounceVertical = true
        canvasView.alwaysBounceHorizontal = true
        canvasView.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        canvasView.isOpaque = false
        // add subview
        addSubview(canvasView)
        canvasView.insertSubview(backgroundView, at: 0)
        backgroundView.backgroundColor = UIColor.ud.N00
        self.backgroundColor = UIColor.ud.canvasOutsideBgColor
    }

    deinit {
        // - Note: when the view deinit, records in undoManager should be delete manully
        //         see Apple's Doc below:
        //         https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/UndoArchitecture/Articles/CleaningUndoStack.html
        _undoManagerReference?.removeAllActions(withTarget: self)
    }

    // MARK: Interfaces

    /// Load from Data Model (notice: will clear current data)
    /// - Parameters:
    ///   - data: Serialzation of LKCanvasDataModel
    ///   - fullyRestore: Whether should fully restore the PKCanvasView to a new one, see discussion
    /// - Returns: whether load data successfully
    ///
    /// There is another Apple's bug that drawing some strokes, and then directly resetting  `PKCanvasView.drawing`
    /// equals to new drawing, and then modify current drawing, the strokes before resetting will come up
    /// if you check the strokes property or export the canvas as image.
    ///
    /// In this case should we totally reset PKCanvasView to a new one to temporarily solve this bug.
    public func load(from data: Data, fullyRestore: Bool = false) -> Bool {
        do {
            let decoder = PropertyListDecoder()
            let dataModel = try decoder.decode(LKCanvasDataModel.self, from: data)
            // Apply data in dataModel to canvasView
            canvasView.resignFirstResponder()

            // re init
            if fullyRestore {
                canvasView.removeFromSuperview()
                backgroundView.removeFromSuperview()
                canvasView = WrappedPKCanvasView()
                canvasView.isFirstTouch = false
                backgroundView = UIView()
                setupCanvasView(canvasView: canvasView, with: backgroundView)
                if let window = self.window {
                    setLayout(window: window, contentSize: dataModel.contentSize)
                } else {
                    Self.logger.error("Cannot find window during fully restoring.")
                }
            }

            canvasView.drawing = dataModel.drawing
            canvasView.contentSize = dataModel.contentSize
            toolPicker?.selectedTool = dataModel.currentTool
            undoManager?.removeAllActions(withTarget: self)
            canvasView.becomeFirstResponder()
            return true
        } catch {
            Self.logger.error("failed to load data in LKCanvasView: \(error)")
            return false
        }
    }

    /// Export an image contains the drawing
    /// - Parameters:
    ///   - minimum:        export whole canvas or minimum content based on PKDrawing, by default is true
    ///   - transparent:    whether the background is transparent, by default is false
    ///   - style:          export canvas in light or dark mode ,by default is light
    /// - Returns:          Returns an image object that contains the the drawing, nil when canvas is empty
    public func exportAsImage(minimum: Bool = true,
                              transparent: Bool = false,
                              style: UIUserInterfaceStyle = .light) -> UIImage? {
        guard canvasIsNotEmpty else {
            Self.logger.warn("Exported nil image because the canvas is empty")
            return nil
        }
        let rect = minimum ?
            /// PM require to cut the drawing outside the canvas
        canvasView.drawing.bounds.intersection(CGRect(origin: .zero, size: canvasViewRealSize)) :
            CGRect(origin: .zero, size: canvasViewRealSize)
        var image: UIImage?
        UITraitCollection(userInterfaceStyle: style).performAsCurrent {
            image = canvasView.drawing.image(from: rect, scale: UIScreen.main.scale).add(padding: 60)
            if transparent == false {
                image = image?.addBackground(color: UIColor.ud.canvasBgcolor)
            }
        }

        return image
    }

    /// Export the canvas drawing(strokes) data
    /// - Returns: drawing(strokes) Data, nil when canvas is empty or error happens
    public func export() -> Data? {
        guard canvasIsNotEmpty else {
            Self.logger.warn("Exported nil data because the canvas is empty")
            return nil
        }
        do {
            let dataModel = LKCanvasDataModel(
                drawing: canvasView.drawing,
                contentSize: canvasViewRealSize,
                currentTool: canvasView.tool as? PKInkingTool ?? .init(.pen, color: .black, width: 30)
            )
            let encoder = PropertyListEncoder()
            let data = try encoder.encode(dataModel)
            return data
        } catch {
            Self.logger.error("failed to export data in LKCanvasView: \(error)")
            return nil
        }
    }

    /// Clear current canvas with ability to undo
    public func clear() {
        setNewDrawingUndoable(PKDrawing())
    }

    // MARK: Set Layout

    /// set layout of LKCanvasView
    /// - Parameters:
    ///   - window:                     the window LKCanvasView will appear in, used for creating toolPicker in iOS 13
    ///   - contentSize:                contentSize for canvasView,
    ///                                 won't be set if contentSize of canvasView is alreay not .zero
    ///   - allowed:                    allow to scale canvas
    ///   - canvasBecomeFirstResponder: whether should let canvasView to become first responder
    ///                                 at the end of this method
    ///   - visiable:                   whether toolPicker should be visiable
    public func setLayout(
        window: UIWindow,
        contentSize: CGSize,
        canvasScale allowed: Bool = true,
        canvasBecomeFirstResponder: Bool = true,
        toolPicker visiable: Bool = true
    ) {
        canvasView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        // Set up the tool picker
        if #available(iOS 14.0, *) {
            toolPicker = PKToolPicker()
        } else {
            toolPicker = PKToolPicker.shared(for: window)
        }

        // Layout
        self.canvasCanScale = allowed
        canvasView.contentSize = contentSize
        Self.logger.info("canvasView contentSize is set to \(canvasView.contentSize)")

        // Properties
        canvasView.contentInsetAdjustmentBehavior = .never
        canvasView.showsVerticalScrollIndicator = false
        canvasView.showsHorizontalScrollIndicator = false
        // Reference undoManager to clear it when deinit. See comments in deinit()
        _undoManagerReference = window.undoManager
        // Remove undoManager records outside the canvas
        _undoManagerReference?.removeAllActions()

        // Set up tool picker
        toolPicker?.setVisible(visiable, forFirstResponder: canvasView)
        toolPicker?.addObserver(canvasView)
        toolPicker?.addObserver(self)

        if canvasBecomeFirstResponder {
            canvasView.becomeFirstResponder()
        }
    }

    // MARK: Actions

    /// Helper method to set a new drawing, with an undo action to go back to the old one.
    public func setNewDrawingUndoable(_ newDrawing: PKDrawing) {
        let oldDrawing = canvasView.drawing
        self.undoManager?.registerUndo(withTarget: self) {
            $0.setNewDrawingUndoable(oldDrawing)
        }
        canvasView.drawing = newDrawing
    }

    // MARK: PKCanvasView delegate

    /// Delegate method: Note that the drawing has changed.
    public func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        Self.logger.info("canvasViewDrawingDidChange")
        delegate?.canvasViewDrawingDidChangeCallback()
    }

    /// Delegate method: the canvas view finishes rendering all of the currently visible content.
    public func canvasViewDidFinishRendering(_ canvasView: PKCanvasView) {
        Self.logger.info("canvasViewDidFinishRendering")
        delegate?.canvasViewDidFinishRenderingCallback()
    }

    /// Delegate method: Called when the user starts using a tool, eg. selecting, drawing, or erasing.
    public func canvasViewDidBeginUsingTool(_ canvasView: PKCanvasView) {
        Self.logger.info("canvasViewDidBeginUsingTool")
        delegate?.canvasViewDidBeginUsingToolCallback()
    }

    /// Delegate method: Called when the user stops using a tool, eg. selecting, drawing, or erasing.
    public func canvasViewDidEndUsingTool(_ canvasView: PKCanvasView) {
        Self.logger.info("canvasViewDidEndUsingTool")
        delegate?.canvasViewDidEndUsingToolCallback()
    }

    // MARK: UIScrollView delegate

    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        // the backgroundView should zoom and moving together with drawing
        return backgroundView
    }

    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // adjust inset during zooming
        if let traitCollection = window?.traitCollection {
            delegate?.adjustCanvasInsets(traitCollection: traitCollection, viewSize: .zero)
        }
    }

    // MARK: Implement PKToolPickerObserver protocol

    /// Delegate method: Note that the tool picker has changed which part of the canvas view
    /// it obscures, if any.
    public func toolPickerFramesObscuredDidChange(_ toolPicker: PKToolPicker) {
        Self.logger.info("toolPickerFramesObscuredDidChange")
        delegate?.toolPickerFramesObscuredDidChangeCallback()
    }

    /// Delegate method: Note that the tool picker has become visible or hidden.
    public func toolPickerVisibilityDidChange(_ toolPicker: PKToolPicker) {
        Self.logger.info("toolPickerVisibilityDidChange")
        delegate?.toolPickerVisibilityDidChangeCallback()
    }

    /// Tells the delegate that the selected tool was changed by the user.
    ///
    /// @param toolPicker  The tool picker that changed.
    public func toolPickerSelectedToolDidChange(_ toolPicker: PKToolPicker) {
        Self.logger.info("toolPickerSelectedToolDidChange")
        delegate?.toolPickerSelectedToolDidChangeCallback()
    }

    /// Tells the delegate that the ruler active state was changed by the user.
    ///
    /// @param toolPicker  The tool picker that changed.
    public func toolPickerIsRulerActiveDidChange(_ toolPicker: PKToolPicker) {
        Self.logger.info("toolPickerIsRulerActiveDidChange")
        delegate?.toolPickerIsRulerActiveDidChangeCallback()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension UIImage {

    /// init pure color image
    convenience init?(color: UIColor, size: CGSize = .zero) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }

    /// add pure color background
    func addBackground(color: UIColor) -> UIImage {
        let background = UIImage(color: color, size: self.size)
        UIGraphicsBeginImageContextWithOptions(self.size, false, UIScreen.main.scale)
        background?.draw(in: CGRect(origin: .zero, size: self.size))
        self.draw(in: CGRect(origin: .zero, size: self.size))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result ?? self
    }

    /// add padding
    func add(padding: CGFloat) -> UIImage {
        let sizeWithPadding = CGSize(width: self.size.width + padding * 2, height: self.size.height + padding * 2)
        let background = UIImage(color: .clear, size: sizeWithPadding)
        UIGraphicsBeginImageContextWithOptions(sizeWithPadding, false, UIScreen.main.scale)
        background?.draw(in: CGRect(origin: .zero, size: sizeWithPadding))
        self.draw(in: CGRect(origin: CGPoint(x: padding, y: padding), size: self.size))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result ?? self
    }
}

/// Just a wrapped view used to detect touch type for homeric `PUBLIC_WHITEBOARD_DRAW`
@available(iOS 13.0, *)
public final class WrappedPKCanvasView: PKCanvasView {

    /// a flag for first touch, used for homeric `PUBLIC_WHITEBOARD_DRAW`
    var isFirstTouch: Bool = true

    weak var lkCanvasView: LKCanvasView?

    static let logger = Logger.log(LKCanvasViewController.self, category: "Module.LarkCanvas.WrappedPKCanvasView")

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first else { return }
        // callback
        if let lkCanvasView = lkCanvasView {
            lkCanvasView.delegate?.canvasViewDidEnter(
                lifeCycle: .viewDidTouch(canvas: lkCanvasView, touch: touch, isFirstTouch: isFirstTouch)
            )
        }
        if isFirstTouch {
            isFirstTouch = false
        }
        if !self.isFirstResponder {
            self.becomeFirstResponder()
        }
    }
}

private extension UDComponentsExtension where BaseType == UIColor {
    /// 画布绘制区域内背景颜色
    static var canvasBgcolor: UIColor {
        UIColor.ud.primaryOnPrimaryFill & UIColor.ud.staticBlack
    }
    /// 画布绘制区域外背景颜色
    static var canvasOutsideBgColor: UIColor {
        UIColor.ud.fillDisable & UIColor.ud.bgBase
    }
}
