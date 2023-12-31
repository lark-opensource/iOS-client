//
//  WebViewGestureProxy.swift
//  SpaceKit
//
//  Created by Webster on 2019/7/14.
//

import Foundation
import WebKit
import SKUIKit
import SKFoundation


public final class WebViewGestureProxy: EditorGestureProxy, EditorViewGestureDelegate {

    public func onLongPress(editorView: UIView?, gestureRecognizer: UIGestureRecognizer) {
        observers.all.forEach {
            $0.receiveLongPress(editorView: editorView, gestureRecognizer: gestureRecognizer)
        }
    }

    public func onSingleTap(editorView: UIView?, gestureRecognizer: UIGestureRecognizer) {
        observers.all.forEach {
            $0.receiveSingleTap(editorView: editorView, gestureRecognizer: gestureRecognizer)
        }
    }

    public func onPan(editorView: UIView?, gestureRecognizer: UIPanGestureRecognizer) {
        observers.all.forEach {
            $0.receivePan(editorView: editorView, gestureRecognizer: gestureRecognizer)
        }
    }

    public func canStartSlideToSelect(by panGestureRecognizer: UIPanGestureRecognizer) -> Bool {
        var canStart = false
        observers.all.forEach {
            let start = $0.canStartSlideToSelect(by: panGestureRecognizer)
            canStart = canStart || start
        }
        return canStart
    }
}
