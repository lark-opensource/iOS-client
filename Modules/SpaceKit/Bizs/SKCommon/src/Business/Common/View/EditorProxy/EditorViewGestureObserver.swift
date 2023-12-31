//
//  EditorViewGestureObserver.swift
//  SKCommon
//
//  Created by chenhuaguan on 2021/6/30.
//

import Foundation

public protocol EditorViewGestureObserver: AnyObject {
    func receiveLongPress(editorView: UIView?, gestureRecognizer: UIGestureRecognizer)
    func receiveSingleTap(editorView: UIView?, gestureRecognizer: UIGestureRecognizer)
    func receivePan(editorView: UIView?, gestureRecognizer: UIPanGestureRecognizer)
    func canStartSlideToSelect(by panGestureRecognizer: UIPanGestureRecognizer) -> Bool
}

public extension EditorViewGestureObserver {
    func canStartSlideToSelect(by panGestureRecognizer: UIPanGestureRecognizer) -> Bool {
        return false
    }
    func receiveLongPress(editorView: UIView?, gestureRecognizer: UIGestureRecognizer) { }
    func receiveSingleTap(editorView: UIView?, gestureRecognizer: UIGestureRecognizer) { }
    func receivePan(editorView: UIView?, gestureRecognizer: UIPanGestureRecognizer) { }
}
