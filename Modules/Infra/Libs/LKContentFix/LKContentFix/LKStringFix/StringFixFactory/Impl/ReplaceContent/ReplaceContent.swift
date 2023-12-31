//
//  ReplaceContent.swift
//  LKContentFix
//
//  Created by 李勇 on 2020/9/6.
//

import UIKit
import Foundation
import ThreadSafeDataStructure

final class ReplaceContent: StringFixFactory {
    /// 需要进行替换的信息
    struct Info {
        // 替换为什么内容
        let to: String

        init?(config: Any) {
            guard let config = config as? [String: String], let to = config["to"] else { return nil }

            self.to = to
        }
    }

    /// 需要进行替换的内容
    private var fixInfo: SafeDictionary<String, Info> = [:] + .readWriteLock

    /// 配置对应的key
    override var key: String { return "replaceContent" }

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
            // 不断的找到需要替换的内容
            while true {
                let range = (attrStr.string as NSString).range(of: from)
                // 如果已经替换了所有的内容，就退出循环
                if range.location == NSNotFound { break }

                // 得到该range的原本属性
                let attr = attrStr.attributes(at: range.location, effectiveRange: nil)
                // 替换内容
                attrStr.replaceCharacters(in: range, with: NSAttributedString(string: to.to, attributes: attr))
            }
        }
        return attrStr
    }
}
