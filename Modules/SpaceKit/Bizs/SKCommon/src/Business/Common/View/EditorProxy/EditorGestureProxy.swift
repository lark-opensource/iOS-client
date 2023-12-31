//
//  EditorGestureProxy.swift
//  SKCommon
//
//  Created by chenhuaguan on 2021/6/30.
//

import Foundation
import WebKit
import SKUIKit
import SKFoundation


public class EditorGestureProxy {
    var observers: ObserverContainer = ObserverContainer<EditorViewGestureObserver>()

    public init() {}

    public func addObserver(_ observer: EditorViewGestureObserver) {
        observers.add(observer)
    }

    public func removeObserver(_ observer: EditorViewGestureObserver) {
        observers.remove(observer)
    }
}
