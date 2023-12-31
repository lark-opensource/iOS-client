//
//  LKCanvasViewControllerDelegate.swift
//  LarkCanvas
//
//  Created by Saafo on 2021/2/24.
//

import UIKit
import Foundation

/// delegate protocol for LKCanvasViewController
@available(iOS 13.0, *)
public protocol LKCanvasViewControllerDelegate: AnyObject {

    /// method to call when tap `Finish` button
    /// - Parameters:
    ///   - controller:                     The LKCanvasViewController whose `Finish` button is tapped
    ///   - drawingImage:                   Export current drawing as image
    ///   - canvasData:                     Export current drawing raw data ( with ability to continue editing )
    ///   - canvasShouldDismissCallback:    Call this callback to dimiss the Controller, param is whether should dismiss
    /// - Note: Must call the callback at the end of the implementation of this method, otherwise the draft may be lost
    func canvasWillFinish(in controller: LKCanvasViewController,
                          drawingImage: UIImage, canvasData: Data,
                          canvasShouldDismissCallback: @escaping (Bool) -> Void)

    /// LifeCycle of LKCanvasViewController, optional
    func canvasDidEnter(lifeCycle: LKCanvasViewController.LifeCycle)
}

@available(iOS 13.0, *)
public extension LKCanvasViewControllerDelegate {
    /// Default empty implementation, can be override
    func canvasDidEnter(lifeCycle: LKCanvasViewController.LifeCycle) {}
}

@available(iOS 13.0, *)
public extension LKCanvasViewController {
    /// LifeCycle of LKCanvasViewController
    enum LifeCycle {
        /// When LKCanvasViewController finished layout
        case viewDidLayout

        /// When LKCanvasViewController is appeared
        case viewDidAppear

        /// When LKCanvasView loaded data
        /// - Parameters:
        ///   - canvas: the canvs which loaded data
        ///   - succeeded: whether load any data successfully
        case canvasDidLoadData(canvas: LKCanvasView, succeeded: Bool)

        /// When LKCanvasView is touched
        /// - Parameters:
        ///   -  canvas: the canvas which is been touched
        ///   - touch: the first touch of touchesBegan(_ touches: with event:)
        ///   - isFirstTouch: whether is the first touch since canvas appeared
        case canvasDidTouch(canvas: LKCanvasView, touch: UITouch, isFirstTouch: Bool)

        /// When LKCanvasView is cleaned
        /// - Parameter canvas: the canvas which is been cleaned
        case canvasDidClean(canvas: LKCanvasView)

        /// When tap `save to album` button
        /// - Parameter succeeded: whether successfully save to album
        case savedToAlbum(succeeded: Bool)

        /// When LKCanvasViewController is disappeared
        case viewDidDisappear
    }
}
