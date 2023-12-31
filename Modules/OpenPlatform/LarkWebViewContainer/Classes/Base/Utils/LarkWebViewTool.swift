//
//  LarkWebViewTool.swift
//  LarkWebViewContainer
//
//  Created by 新竹路车神 on 2020/9/14.
//

import CommonCrypto
import LarkOPInterface

/// 安全的异步派发到主线程执行任务
/// - Parameter block: 任务
func executeOnMainQueueAsync(_ block: @escaping os_block_t) {
    if Thread.isMainThread {
        block()
    } else {
        DispatchQueue.main.async {
            block()
        }
    }
}

/// 安全的同步派发到主线程执行任务
/// - Parameter block: 任务
func executeOnMainQueueSync(_ block: os_block_t) {
    if Thread.isMainThread {
        block()
    } else {
        DispatchQueue.main.sync {
            block()
        }
    }
}

extension String {

    func fromBase64() -> String? {
        guard let data = Data(base64Encoded: self) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// 转换JS字符串到可执行状态 Code From CCM CCM测试通过
    /// - Returns: 可执行字符串
    func transformToExecutableScript() -> String {
        var script = trimmingCharacters(in: .newlines)
        // NOTE: 亲测 newlines 无法去掉以下的换行符
        let NSNewLineCharacter = "\u{000a}"
        let NSLineSeparatorCharacter = "\u{2028}"
        let NSParagraphSeparatorCharacter = "\u{2029}"
        script = script.replacingOccurrences(of: NSNewLineCharacter, with: "")
        script = script.replacingOccurrences(of: NSLineSeparatorCharacter, with: "")
        script = script.replacingOccurrences(of: NSParagraphSeparatorCharacter, with: "")
        return script
    }
    
    public func lkw_cookie_mask() -> String {
        if self.isEmpty {
            return ""
        } else if self.count == 1 {
            return "*"
        } else if self.count == 2 {
            return "**"
        } else if self.count == 3 {
            let prefixIndex = String.Index.init(encodedOffset: 1)
            let suffixIndex = String.Index.init(encodedOffset: 2)
            let maskRange = prefixIndex ..< suffixIndex
            return self.replacingCharacters(in: maskRange, with: "*")
        } else {
            var padding = Int(floor(Double(self.count / 4)))
            var length = self.count - padding * 2
            let toIndex = String.Index.init(encodedOffset: padding)
            let fromIndex = String.Index.init(encodedOffset: padding + length)
            return self.substring(to: toIndex) + "***" + self.substring(from: fromIndex)
        }
    }
}

extension UIView {
    /// 视图是否可见
    /// - Returns: 是否可见
    func isVisible() -> Bool {
        guard let window = window else {
            return false
        }
        guard !window.isHidden, !isHidden else {
            return false
        }
        return alpha > 0
    }
}

@objcMembers
public final class LarkWebViewLogHelper: NSObject {
    
    /// 仅LarkWebView内OC代码可用
    public static func info(_ message: String?) {
        logger.info(message ?? "")
    }
    
    /// 仅LarkWebView内OC代码可用
    public static func error(_ message: String?, error: Error?) {
        logger.error(message ?? "", error: error)
    }
}
