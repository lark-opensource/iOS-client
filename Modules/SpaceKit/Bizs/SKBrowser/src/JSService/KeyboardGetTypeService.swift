//
//  KeyboardGetTypeService.swift
//  SKBrowser
//
//  Created by lizechuang on 2021/11/29.
//
// https://bytedance.feishu.cn/docs/doccnXMeucLkcLCDMMakn0ML32b

import SKCommon
import SKFoundation
import LarkKeyboardKit
import RxSwift

public final class KeyboardGetTypeService: BaseJSService {
    var callback: String?
    var curKeyboardType: Keyboard.TypeEnum?
    private let disposeBag = DisposeBag()
}

extension KeyboardGetTypeService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return [.keyBoardGetType]
    }
    public func handle(params: [String: Any], serviceName: String) {
        let service = DocsJSService(serviceName)
        switch service {
        case .keyBoardGetType:
            guard let callback = params["callback"] as? String else { return }
            self.callback = callback
            notifyKeyboardChange(type: KeyboardKit.shared.keyboardType)
            addObserverForeKeyboard()
        default:
            DocsLogger.info("no service")
        }
    }

    private func addObserverForeKeyboard() {
        KeyboardKit.shared.keyboardEventChange.subscribe(onNext: { [weak self] (event) in
            self?.notifyKeyboardChange(type: event.keyboard.type)
        }).disposed(by: disposeBag)
    }

    private func notifyKeyboardChange(type: Keyboard.TypeEnum) {
        guard let callback = callback else {
            return
        }
        if let curKeyboardType = curKeyboardType, curKeyboardType == type {
            return
        }
        var keyBoardType: Int = 0
        switch type {
        case .system:
            keyBoardType = 0
        case .hardware:
            keyBoardType = 1
        case .customInputView:
            keyBoardType = 2
        }
        self.curKeyboardType = type
        model?.jsEngine.callFunction(DocsJSCallBack(callback), params: ["keyBoardType": keyBoardType], completion: nil)
    }
}
