//
//  Util.swift
//  ByteView
//
//  Created by kiri on 2021/6/28.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RichLabel
import ByteViewCommon
import UIKit

typealias Util = ByteViewCommon.Util
extension Util {
    static func swizzleInstanceMethod(_ clz: AnyClass, from selector1: Selector, to selector2: Selector) {
        guard let method1: Method = class_getInstanceMethod(clz, selector1),
              let method2: Method = class_getInstanceMethod(clz, selector2) else {
            return
        }

        if class_addMethod(clz, selector1, method_getImplementation(method2), method_getTypeEncoding(method2)) {
            class_replaceMethod(clz, selector2, method_getImplementation(method1), method_getTypeEncoding(method1))
        } else {
            method_exchangeImplementations(method1, method2)
        }
    }
}

func typeDescription(of value: Any) -> String {
    "\(type(of: value))"
}

func address(of value: AnyObject) -> String {
    let p = withExtendedLifetime(value) { "\(Unmanaged.passUnretained($0).toOpaque())" }
    return p.replacingOccurrences(of: "^0x0*", with: "0x", options: .regularExpression)
}

// 在deinit的时候调用可能造成闪退
func metadataDescription(of value: AnyObject) -> String {
    "\(typeDescription(of: value)): \(address(of: value))"
}

@inline(never)
@usableFromInline
func methodNotImplemented(function: StaticString = #function, file: StaticString = #fileID, line: UInt = #line) -> Never {
    fatalError("Method must be overridden: \(function)", file: file, line: line)
}

#if DEBUG
func assertMain(function: StaticString = #function) {
    assert(Thread.isMainThread, "Method must called in main thread: \(function)")
}
#else
@inline(__always)
@usableFromInline
func assertMain() {}
#endif

#if DEBUG
extension Util {
    static func observeDeinit(_ object: Any, logDescription: String? = nil,
                              file: String = #fileID, function: String = #function, line: Int = #line) {
        ObjectDeinitObserver.observe(object, logDescription: logDescription, file: file, function: function, line: line)
    }

    static func findRootVc(_ vc: UIViewController) -> UIViewController {
        if vc.parent == nil { return vc }
        return findRootVc(vc.parent!)
    }

    static func dumpExistObjects(_ msg: String = "dump") {
        ObjectDeinitObserver.dumpExistObjects(msg)
    }
}
#endif

extension BundleI18n {

    static func getCurrentLanguageString() -> String {
        switch currentLanguage {
        case .zh_TW: return "zh_tw"
        case .zh_HK: return "zh_hk"
        case .en_US: return "en_us"
        case .ja_JP: return "ja_jp"
        case .zh_CN: return "zh_cn"
        case .de_DE: return "de_de"
        case .fr_FR: return "fr_fr"
        case .es_ES: return "es_es"
        case .hi_IN: return "hi_in"
        case .id_ID: return "id_id"
        case .it_IT: return "it_it"
        case .ko_KR: return "ko_kr"
        case .pt_BR: return "pt_br"
        case .ru_RU: return "ru_ru"
        case .th_TH: return "th_th"
        case .vi_VN: return "vi_vn"
        case .ms_MY: return "ms_my"
        default: return "en_us"
        }
    }

    static func isChinese() -> Bool {
        return currentLanguage == .zh_CN
    }

    static func localeIdentifier() -> String {
        return isChinese() ? "zh_CN" : "en_US"
    }
}

extension Util {
    // 字典转字符串
    static func dicValueString(_ dic: [String: Any]) -> String? {
        let data = try? JSONSerialization.data(withJSONObject: dic, options: [])
        let str = String(data: data!, encoding: String.Encoding.utf8)
        return str
    }

    // 字符串转字典
    static func stringValueDic(_ str: String) -> [String: Any]? {
        let data = str.data(using: String.Encoding.utf8)
        if let dict = try? JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String: Any] {
            return dict
        }
        return nil
    }

    static func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {}
        }
        return nil
    }

    static func attributeHeight(attributeString: NSAttributedString, width: CGFloat, font: UIFont, lineHeight: CGFloat) -> CGFloat {
        let textParser = LKTextParserImpl()
        textParser.originAttrString = attributeString
        textParser.parse()
        let layoutEngine = LKTextLayoutEngineImpl()
        layoutEngine.attributedText = textParser.renderAttrString
        layoutEngine.preferMaxWidth = width

        let rectSize = layoutEngine.layout(size: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude))
        let numberOfline: Int = Int(rectSize.height / font.lineHeight + 0.5)
        return CGFloat(numberOfline) * lineHeight
    }

    static func attributeWidth(attributeString: NSAttributedString, height: CGFloat) -> CGFloat {
        let textParser = LKTextParserImpl()
        textParser.originAttrString = attributeString
        textParser.parse()
        let layoutEngine = LKTextLayoutEngineImpl()
        layoutEngine.attributedText = textParser.renderAttrString

        let rectSize = layoutEngine.layout(size: CGSize(width: CGFloat.greatestFiniteMagnitude, height: height))
        return rectSize.width
    }

    static func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIApplication.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
