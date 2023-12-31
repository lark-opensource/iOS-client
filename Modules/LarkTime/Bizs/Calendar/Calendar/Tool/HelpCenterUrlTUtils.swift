//
//  HelpCenterUrlTUtils.swift
//  Calendar
//
//  Created by Rico on 2023/4/18.
//

import Foundation

extension String {
    // 替换帮助中心url里面的语言
    // 例如 "https://www.feishu.cn/hc/zh-CN/articles/360034114413" -> "https://www.feishu.cn/hc/${current_languange}/articles/360034114413"
    
    func replaceLocaleForHelperCenterUtlString() -> String {
        var str = self
        if let hcRange = str.range(of: "/hc/"), let articlesRange = str.range(of: "/articles/") {
            let startIndex = str.index(hcRange.upperBound, offsetBy: 0)
            let endIndex = str.index(articlesRange.lowerBound, offsetBy: 0)
            guard startIndex < endIndex else { return self }
            let result = String(str[startIndex..<endIndex])
            str = str.replacingOccurrences(of: result, with: BundleI18n.currentLanguage.languageIdentifier)
        }
        return str
    }
}
