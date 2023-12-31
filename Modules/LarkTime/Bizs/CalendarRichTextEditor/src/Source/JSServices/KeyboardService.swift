//
//  KeyboardService.swift
//  SpaceKit
//
//  Created by weidong fu on 2018/12/11.
//

import Foundation

final class KeyboardService {
    var keyBoardCallback: String?
    weak var dispatch: ViewLifeCycleDispatch?
    weak var jsEngine: RichTextViewJSEngine?

    init(dispatch: ViewLifeCycleDispatch, jsEngine: RichTextViewJSEngine) {
        self.dispatch = dispatch
        self.jsEngine = jsEngine

        dispatch.addObserver(self)
    }
}

extension KeyboardService: RichTextViewLifeCycleEvent {
    func browserKeyboardDidChange(_ keyboardInfo: KeyBoadInfo) {
        guard let callback = self.keyBoardCallback else {
            Logger.error("KeyboardService can't find callback")
            return
        }
        let params = [
            "isOpenKeyboard": keyboardInfo.isShow,
            "innerHeight": keyboardInfo.height,
            "keyboardType": keyboardInfo.trigger
            ] as [String: Any]
        Logger.info("KeyboardService did call back", extraInfo: params)
        jsEngine?.callFunction(JSCallBack(callback), params: params, completion: nil)
    }
}

extension KeyboardService: JSServiceHandler {
    var handleServices: [JSService] {
        return [.rtOnKeyboardChanged]
    }

    func handle(params: [String: Any], serviceName: String) {
        guard let callback = params["callback"] as? String else {
            Logger.info("callback 传空了")
            return
        }
        keyBoardCallback = callback
    }
}
