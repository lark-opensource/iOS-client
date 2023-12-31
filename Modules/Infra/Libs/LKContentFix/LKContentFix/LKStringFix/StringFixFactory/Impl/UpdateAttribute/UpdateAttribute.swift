//
//  UpdateAttribute.swift
//  LKContentFix
//
//  Created by 李勇 on 2020/9/6.
//

import Foundation
import UIKit
import ThreadSafeDataStructure

final class UpdateAttribute: StringFixFactory {
    /// 需要进行替换的信息
    struct Info {
        // 存放字体名替换信息
        let fontName: [String: String]

        init?(config: Any) {
            guard let config = config as? [[String: String]] else { return nil }

            var fontName: [String: String] = [:]
            // 遍历配置
            config.forEach { subConfig in
                guard let attribute = subConfig["attribute"] else { return }
                // 替换字体名
                if attribute == "fontName", let from = subConfig["from"], let to = subConfig["to"] {
                    fontName[from] = to
                }
            }

            // 如果没有任何有效配置，则直接不创建
            guard !fontName.isEmpty else { return nil }
            self.fontName = fontName
        }
    }

    /// 需要进行替换的内容
    private var fixInfo: SafeDictionary<String, Info> = [:] + .readWriteLock

    /// 配置对应的key
    override var key: String { return "updateAttribute" }

    /// 重置所有的配置
    override func reset() {
        self.fixInfo.removeAll()
    }

    /// 配置，这里传入的config是根据configKey得到的，str表示config是对于哪个内容下发的配置
    override func loadConfig(_ str: String, _ config: Any) {
        guard let info = Info(config: config) else { return }

        self.fixInfo[str] = info
    }

    /// 开始处理内容
    override func fix(_ attrStr: NSMutableAttributedString) -> NSMutableAttributedString {
        // copy一份，方式遍历过程中内容变化
        let fixInfo = self.fixInfo.getImmutableCopy()

        fixInfo.forEach { (from, to) in
            // 规定从哪个范围查找内容
            var findRange = NSRange(location: 0, length: attrStr.length)
            // 不断的找到需要替换的内容
            while true {
                let range = (attrStr.string as NSString).range(of: from, options: [], range: findRange)
                // 如果已经替换了所有的内容，就退出循环
                if range.location == NSNotFound { break }

                // 得到该range的原本属性
                var attr = attrStr.attributes(at: range.location, effectiveRange: nil)
                // 替换字体
                if let font = attr[.font] as? UIFont, let toName = to.fontName[font.fontName] {
                    attr[.font] = UIFont(name: toName, size: font.pointSize)
                }
                // 进行内容替换
                attrStr.replaceCharacters(in: range, with: NSAttributedString(string: from, attributes: attr))

                // 移动要查找的范围
                findRange = NSRange(location: range.upperBound, length: attrStr.length - range.upperBound)
            }
        }
        return attrStr
    }
}
