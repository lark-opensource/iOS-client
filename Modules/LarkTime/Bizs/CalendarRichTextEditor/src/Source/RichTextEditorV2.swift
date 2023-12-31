//
//  RichTextEditorV2.swift
//  SpaceKit
//
//  Created by 边俊林 on 2019/8/2.
//

import Foundation
import SwiftyJSON

private typealias RichTextEditorV2Callback = () -> Void
final class RichTextEditorV2: RichTextEditorInterface {
    private var _v2JSBridgeMapping: [String: String] = [:]
    private var _callbacks: [String: [RichTextEditorV2Callback]] = [:]

    // sdk 1.0 接口
    override func getDocData(completion: @escaping (String?, Error?) -> Void) {
        getContent(completion: completion)
    }

    override func getDocHtml(completion: @escaping (String?, Error?) -> Void) {
        getHtml(completion: completion)
    }

    override func set(content: String, success: (() -> Void)?, fail: @escaping (Error) -> Void) {
        render(content, success: success, fail: fail)
    }

    override func setDoc(data: String, success: (() -> Void)?, fail: @escaping (Error) -> Void) {
        render(data, success: success, fail: fail)
    }

    override func checkKeep(completion: @escaping (Bool?, Error?) -> Void) {
        getIsChanged(completion: completion)
    }

    // sdk 2.0 接口
    override func setStyle(_ style: DocsRichTextParam.AditStyle, success: (() -> Void)?, fail: @escaping (Error) -> Void) {
        commitCallbackTask({ [weak self] in
            guard let self = self else { return }
            self.goFLAG(module: "setStyle")
            let formatedStr = ["style": style.convertToDict()].jsonString ?? ""
            self.callJSFunction(with: JSService.richTextSetStyle, parameter: formatedStr) { [weak self] (_, error) in
                self?.toFLAG(module: "setStyle")
                if let err = error { fail(err) } else { success?() }
            }
        }, for: JSService.richTextSetStyle.rawValue)
    }

    override func getContent(completion: @escaping (String?, Error?) -> Void) {
        commitCallbackTask({ [weak self] in
            guard let self = self else { return }
            self.goFLAG(module: "getContent")
            self.callJSFunction(with: JSService.richTextGetContent, parameter: "") { [weak self] (obj, error) in
                self?.toFLAG(module: "getContent")
                let json = JSON(obj as Any)
                /// 只取apool和initialAttributedText两个字段，抛掉style，和Android对齐。
                if let contentDict = json["content"].dictionaryObject,
                   let apool = contentDict["apool"],
                   let initialAttributedText = contentDict["initialAttributedText"],
                   let jsonStr = ["apool": apool, "initialAttributedText": initialAttributedText].jsonString {
                    completion(jsonStr, error)
                } else {
                    Logger.error("RichTextEditor v2 getContent can't resolve text", extraInfo: ["json": json.description])
                }
            }
        }, for: JSService.richTextGetContent.rawValue)
    }

    override func getHtml(completion: @escaping (String?, Error?) -> Void) {
        commitCallbackTask({ [weak self] in
            guard let self = self else { return }
            self.goFLAG(module: "getHtml")
            self.callJSFunction(with: JSService.richTextGetHtml, parameter: "") { [weak self] (obj, error) in
                self?.toFLAG(module: "getContent")
                let json = JSON(obj as Any)
                if let html = json["html"].string {
                    completion(html, error)
                } else {
                    Logger.error("RichTextEditor v2 getHtml can't resolve html", extraInfo: ["json": json.description])
                }
            }
        }, for: JSService.richTextGetHtml.rawValue)
    }

    override func render(_ content: String, success: (() -> Void)?, fail: @escaping (Error) -> Void) {
        commitCallbackTask({ [weak self] in
            guard let self = self else { return }
            self.goFLAG(module: "renderContent")
            if content.isEmpty {
                self.clearContent(success: success, fail: fail)
                return
            }
            let formatedStr = ["content": content].jsonString ?? ""
            self.callJSFunction(with: JSService.richTextRender, parameter: formatedStr, enableLog: false) { [weak self] (_, error) in
                self?.toFLAG(module: "renderContent")
                if let err = error { fail(err) } else { success?() }
            }
        }, for: JSService.richTextRender.rawValue)
    }

    override func getRect(completion: @escaping (String?, Error?) -> Void) {
        commitCallbackTask({ [weak self] in
            guard let self = self else { return }
            self.goFLAG(module: "getRect")
            self.callJSFunction(with: JSService.richTextGetRect, parameter: "") { [weak self] (obj, error) in
                self?.toFLAG(module: "getRect")
                completion(obj as? String, error)
            }
        }, for: JSService.richTextGetRect.rawValue)
    }

    override func clearContent(success: (() -> Void)?, fail: @escaping (Error) -> Void) {
        commitCallbackTask({ [weak self] in
            guard let self = self else { return }
            self.callJSFunction(with: JSService.richTextClearContent, parameter: "") { (_, error) in
                if let err = error { fail(err) } else { success?() }
            }
        }, for: JSService.richTextClearContent.rawValue)
    }

    override func getIsChanged(completion: @escaping (Bool?, Error?) -> Void) {
        commitCallbackTask({ [weak self] in
            guard let self = self else { return }
            self.goFLAG(module: "getIsChanged")
            self.callJSFunction(with: JSService.richTextIsChanged, parameter: "") { [weak self] (obj, error) in
                self?.toFLAG(module: "getIsChanged")
                let json = JSON(obj as Any)
                if let boolval = json["isChanged"].bool {
                    completion(!boolval, error) // 日历拿的是isNotChanged😓
                } else {
                    Logger.error("RichTextEditor v2 getText can't resolve isChanged", extraInfo: ["json": json.description])
                }
            }
        }, for: JSService.richTextIsChanged.rawValue)
    }

    override func setPlaceholder(_ props: DocsRichTextParam.PlaceholderProps, success: (() -> Void)?, fail: @escaping (Error) -> Void) {
        commitCallbackTask({ [weak self] in
            guard let self = self else { return }
            self.goFLAG(module: "setPlaceholder")
            let formatedStr = ["props": props.convertToDict()].jsonString ?? ""
            self.callJSFunction(with: JSService.richTextSetPlaceholder, parameter: formatedStr) { [weak self] (_, error) in
                self?.toFLAG(module: "setPlaceholder")
                if let err = error { fail(err) } else { success?() }
            }
        }, for: JSService.richTextSetPlaceholder.rawValue)
    }

    // 版本无差别通用接口
    override func getText(completion: @escaping (String?, Error?) -> Void) {
        commitCallbackTask({ [weak self] in
            guard let self = self else { return }
            self.goFLAG(module: "getText")
            self.callJSFunction(with: JSService.richTextGetText, parameter: "") { [weak self] (obj, error) in
                self?.toFLAG(module: "getText")
                let json = JSON(obj as Any)
                if let text = json["text"].string {
                    completion(text, error)
                } else {
                    Logger.error("RichTextEditor v2 getText can't resolve text", extraInfo: ["json": json.description])
                }
            }
        }, for: JSService.richTextGetText.rawValue)
    }

    override func setEditable(_ enable: Bool, success: (() -> Void)?, fail: @escaping (Error) -> Void) {
        commitCallbackTask({ [weak self] in
            guard let self = self else { return }
            self.goFLAG(module: "setEditable")
            let formatedStr = ["editable": enable].jsonString ?? ""
            self.callJSFunction(with: JSService.richTextSetEditable, parameter: formatedStr) { [weak self] (_, error) in
                self?.toFLAG(module: "setEditable")
                if let err = error { fail(err) } else { success?() }
            }
        }, for: JSService.richTextSetEditable.rawValue)
    }

    override func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)?) {
        Logger.info("RichTextView evaluated custom script", extraInfo: ["script": javaScriptString])
        jsEngine?.evaluateJavaScript(javaScriptString, completionHandler: completionHandler)
    }
}

extension RichTextEditorV2 {
    // 2.0接口必须走bridge，没有注册JSService必定没有走bridge，故参数不允许传String，不同于1.0
    func callJSFunction(with service: JSService, parameter: String, enableLog: Bool = true, completion: @escaping (Any?, Error?) -> Void) {
        guard let jscallback = _v2JSBridgeMapping[service.rawValue] else {
            Logger.error("RichTextEditor v2 can't find js callback", extraInfo: ["service": service.rawValue])
            return
        }

        let script = "\(jscallback)(\(parameter))"
        if enableLog {
            Logger.info("RTTextEditor will evaluate script", extraInfo: ["script": script])
        }
        jsEngine?.evaluateJavaScript(script, completionHandler: { (obj, error) in
            completion(obj, error)
        })
    }

    private func goFLAG(module: String) {
        Logger.info("RichTextEditorV2 core service record -> start \(module): \(Int64(Date().timeIntervalSince1970 * 1000))")
    }

    private func toFLAG(module: String) {
        Logger.info("RichTextEditorV2 core service record -> end \(module): \(Int64(Date().timeIntervalSince1970 * 1000))")
    }
}

// JS Bridge Supporting Method
extension RichTextEditorV2 {
    func clearBridges() {
        Logger.info("RichTextEditorV2 JSBridge will remove all bridges")
        _v2JSBridgeMapping.removeAll()
    }

    func removeAllTasks() {
        _callbacks.forEach {
            if !$1.isEmpty {
                Logger.info("RichTextEditorV2 JSBridge will remove the task waiting for bridge", extraInfo: ["jsMethod": $0])
            }
        }
        _callbacks.removeAll()
    }

    func updateJSBridge(_ bridge: String, for jsMethod: String) {
        _v2JSBridgeMapping[jsMethod] = bridge
        launchCallbackTask(for: jsMethod)
    }

    // commit a js callback task, auto run when js bridge is avaiable
    @inline(__always)
    private func commitCallbackTask(_ callback: @escaping RichTextEditorV2Callback, for jsMethod: String) {
        if _v2JSBridgeMapping[jsMethod] == nil {
            _callbacks[jsMethod] == nil ? _callbacks[jsMethod] = [] : ()
            _callbacks[jsMethod]?.append(callback)
            Logger.info("RichTextEditorV2 JSBridge queue up task for bridge", extraInfo: ["jsMethod": jsMethod])
        } else {
            callback()
        }
    }

    private func launchCallbackTask(for jsMethod: String) {
        guard nil != _v2JSBridgeMapping[jsMethod],
                let storedCallbacks = _callbacks[jsMethod] else { return }
        _callbacks[jsMethod] = nil
        storedCallbacks.forEach {
            Logger.info("RichTextEditorV2 JSBridge launch task for bridge", extraInfo: ["jsMethod": jsMethod])
            $0()
        }
    }
}

// MARK: Model Resolve helping method
private protocol BridgeConvertible {
    func convertToString() -> String
    func convertToDict() -> [String: Any]
}

extension BridgeConvertible {
    func convertToString() -> String { return "" }
    func convertToDict() -> [String: Any] { return [:] }
}

extension DocsRichTextParam.AditContent: BridgeConvertible {
    func convertToDict() -> [String: Any] {
        return [:]
    }

}

extension DocsRichTextParam.AditStyle: BridgeConvertible {
    func convertToDict() -> [String: Any] {
        var kv: [String: Any] = [:]

        let cssFontSize = fontSize?.hasSuffix("px") == true
            ? (fontSize ?? "") : "\(fontSize ?? "")px"
        if fontSize != nil { kv["fontSize"] = cssFontSize }
        kv.unwrap(color, toKey: "color")
        kv.unwrap(minHeight, toKey: "minHeight")
        kv.unwrap(maxHeight, toKey: "maxHeight")
        kv.unwrap(textAlign, toKey: "textAlign")
        kv.unwrap(fontFamily, toKey: "fontFamily")
        kv.unwrap(fontWeight, toKey: "fontWeight")
        kv.unwrap(innerHeight, toKey: "innerHeight")
        kv.unwrap(listMarginText, toKey: "listMarginText")
        kv.unwrap(horizontalLRSpace, toKey: "horizontalLRSpace")
        kv.unwrap(background, toKey: "background")
        kv.unwrap(linkColor, toKey: "linkColor")
        kv.unwrap(listMarkerColor, toKey: "listMarkerColor")
        kv.unwrap(isSysBold, toKey: "isSysBold")
        return kv
    }
}

extension Dictionary {
    mutating func unwrap(_ optionalValue: Value?, toKey key: Key, or nilHandler: @escaping () -> Void = {}) {
        if let value = optionalValue {
            self[key] = value
        } else {
            nilHandler()
        }
    }
}

extension DocsRichTextParam.PlaceholderProps: BridgeConvertible {
    func convertToDict() -> [String: Any] {
        var kv: [String: String] = [:]
        // 在此添加新的
        kv.unwrap(text, toKey: "text")
        kv.unwrap(color, toKey: "color")
        kv.unwrap(fontSize, toKey: "fontSize")
        kv.unwrap(fontFamily, toKey: "fontFamily")
        kv.unwrap(bold?.description, toKey: "bold")
        kv.unwrap(italic?.description, toKey: "italic")
        kv.unwrap(backgroundColor, toKey: "backgroundColor")
        kv.unwrap(underline?.description, toKey: "underline")
        kv.unwrap(strikeThrough?.description, toKey: "strikeThrough")
        return kv
    }
}
