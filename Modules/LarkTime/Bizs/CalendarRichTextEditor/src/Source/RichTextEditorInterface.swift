//
//  RichTextEditorInterface.swift
//  SpaceKit
//
//  Created by 边俊林 on 2019/8/2.
//

import Foundation

class RichTextEditorInterface {
    weak var jsEngine: RichTextViewJSEngine?

    // 📝 接口兼容情况
    // 使用sdk1.0
    // - 调用1.0接口    ✅
    // - 调用2.0接口    ⚠️ 不支持向上兼容，即1.0参数可用，2.0新参数现象未知
    // 使用sdk2.0
    // - 调用1.0接口    ✅
    // - 调用2.0接口    ✅

    // sdk 1.0 接口
    func getDocData(completion: @escaping (String?, Error?) -> Void) { }
    func getDocHtml(completion: @escaping (String?, Error?) -> Void) { }
    func set(content: String, success: (() -> Void)?, fail: @escaping (Error) -> Void) { }
    func setDoc(data: String, success: (() -> Void)?, fail: @escaping (Error) -> Void) { }

    func checkKeep(completion: @escaping (Bool?, Error?) -> Void) { }

    // sdk 2.0 接口
    func setStyle(_ style: DocsRichTextParam.AditStyle, success: (() -> Void)?, fail: @escaping (Error) -> Void) { }
    func getContent(completion: @escaping (String?, Error?) -> Void) { }
    func getHtml(completion: @escaping (String?, Error?) -> Void) { }
    func render(_ content: String, success: (() -> Void)?, fail: @escaping (Error) -> Void) { }
    func render(_ content: DocsRichTextParam.AditContent, success: (() -> Void)?, fail: @escaping (Error) -> Void) { }
    func getRect(completion: @escaping (String?, Error?) -> Void) { } // 2.0 only
    func clearContent(success: (() -> Void)?, fail: @escaping (Error) -> Void) { } // 2.0 only
    func getIsChanged(completion: @escaping (Bool?, Error?) -> Void) { }
    func setPlaceholder(_ props: DocsRichTextParam.PlaceholderProps, success: (() -> Void)?, fail: @escaping (Error) -> Void) { }
    func onPasteDocs(completion: @escaping ([Bool], Error?) -> Void) { }

    // 版本无差别通用接口
    func setCanScroll(_ canScroll: Bool) { }
    func getText(completion: @escaping (String?, Error?) -> Void) { }
    func setEditable(_ enable: Bool, success: (() -> Void)?, fail: @escaping (Error) -> Void) { }
    func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)?) { }
}
