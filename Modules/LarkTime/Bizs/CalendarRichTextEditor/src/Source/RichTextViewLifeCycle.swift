//
//  RichTextViewLifeCycle.swift
//  SpaceKit
//
//  Created by weidong fu on 2018/12/11.
//

import Foundation

protocol RichTextViewLifeCycleEvent {
    func browserKeyboardDidChange(_ keyboardInfo: KeyBoadInfo)
}

final class ViewLifeCycleDispatch {
    let observers: ObserverContainer<RichTextViewLifeCycleEvent>

    init() {
        self.observers = ObserverContainer<RichTextViewLifeCycleEvent>()
    }

    func addObserver(_ o: RichTextViewLifeCycleEvent) {
        observers.add(o)
    }

//    func removeObserver(_ o: RichTextViewLifeCycleEvent) {
//        observers.remove(o)
//    }
}

extension ViewLifeCycleDispatch: RichTextViewLifeCycleEvent {
    func browserKeyboardDidChange(_ keyboardInfo: KeyBoadInfo) {
        observers.all.forEach { $0.browserKeyboardDidChange(keyboardInfo) }
    }
}
