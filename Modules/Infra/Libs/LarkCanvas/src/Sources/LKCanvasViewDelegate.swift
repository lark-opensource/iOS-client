//
//  LKCanvasViewDelegate.swift
//  LarkCanvas
//
//  Created by Saafo on 2021/2/24.
//

import UIKit
import Foundation

/// delegate protocol of LKCanvasView
@available(iOS 13.0, *)
public protocol LKCanvasViewDelegate: AnyObject {

    // Layout
    func adjustCanvasInsets(traitCollection: UITraitCollection, viewSize: CGSize)

    // Callback
    /// LifeCycle of LKCanvasView
    func canvasViewDidEnter(lifeCycle: LKCanvasView.LifeCycle)

    // Callbacks for PKCanvasViewDelegate & PKToolPickerObserver
    func toolPickerFramesObscuredDidChangeCallback()

    func toolPickerVisibilityDidChangeCallback()

    func toolPickerSelectedToolDidChangeCallback()

    func toolPickerIsRulerActiveDidChangeCallback()

    func canvasViewDrawingDidChangeCallback()

    func canvasViewDidFinishRenderingCallback()

    func canvasViewDidBeginUsingToolCallback()

    func canvasViewDidEndUsingToolCallback()
}

@available(iOS 13.0, *)
public extension LKCanvasViewDelegate {
    // Layout
    /// Default empty implementation, can be override
    func adjustCanvasInsets(traitCollection: UITraitCollection, viewSize: CGSize) {}

    // Callback
    /// Default empty implementation, can be override
    func canvasViewDidEnter(lifeCycle: LKCanvasView.LifeCycle) {}

    // Callbacks for PKCanvasViewDelegate & PKToolPickerObserver
    /// Default empty implementation, can be override
    func toolPickerFramesObscuredDidChangeCallback() {}
    /// Default empty implementation, can be override
    func toolPickerVisibilityDidChangeCallback() {}
    /// Default empty implementation, can be override
    func toolPickerSelectedToolDidChangeCallback() {}
    /// Default empty implementation, can be override
    func toolPickerIsRulerActiveDidChangeCallback() {}
    /// Default empty implementation, can be override
    func canvasViewDrawingDidChangeCallback() {}
    /// Default empty implementation, can be override
    func canvasViewDidFinishRenderingCallback() {}
    /// Default empty implementation, can be override
    func canvasViewDidBeginUsingToolCallback() {}
    /// Default empty implementation, can be override
    func canvasViewDidEndUsingToolCallback() {}
}

@available(iOS 13.0, *)
public extension LKCanvasView {
    /// LifeCycle of LKCanvasView
    enum LifeCycle {
        /// When LKCanvasView is touched
        /// - Parameters:
        ///   - canvas: the canvas which is been touched
        ///   - touch: the first touch of touchesBegan(_ touches: with event:)
        ///   - isFirstTouch: whether is the first touch since canvas appeared
        case viewDidTouch(canvas: LKCanvasView, touch: UITouch, isFirstTouch: Bool)
    }
}
