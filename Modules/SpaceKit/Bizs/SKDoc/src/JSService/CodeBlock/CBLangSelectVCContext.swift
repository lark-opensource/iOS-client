//
//  CBLangSelectVCContext.swift
//  SKBrowser
//
//  Created by lizechuang on 2020/9/21.
//

import Foundation
import SKCommon
import SKResource

class CBLangSelectVCContext {
    enum Const {
        static let searchViewOffset = 16.0
        static let searchViewHeight = 32
    }

    private var languages: [String]

    private var selectLanguage: String

    private var hadFilterLanguages: [String]

    public init(languages: [String],
                selectLanguage: String) {
        self.languages = languages
        self.selectLanguage = selectLanguage
        self.hadFilterLanguages = languages
    }

    public func obtainLanguages() -> [String] {
        if hadFilterLanguages.isEmpty {
            return [BundleI18n.SKResource.Doc_Block_NoResultsFound]
        }
        return hadFilterLanguages
    }

    public func ontainLanguageInfoWithIndex(_ index: Int) -> (name: String, isSelect: Bool, isLast: Bool, isEmpty: Bool)? {
        guard hadFilterLanguages.count != 0 else {
            return (BundleI18n.SKResource.Doc_Block_NoResultsFound, false, true, true)
        }
        guard index < hadFilterLanguages.count else {
            skAssertionFailure("index >= languages.count")
            return nil
        }
        return (hadFilterLanguages[index], hadFilterLanguages[index] == selectLanguage, index == hadFilterLanguages.count - 1, false)
    }

    // 在使用在第一次加载TableView时获取SelectIndex( 业务需求需要指定到前两个
    public func obtainSelectIndex() -> Int? {
        guard let selectIndex = hadFilterLanguages.firstIndex(of: selectLanguage) else {
            skAssertionFailure("selectLanguage not found")
            return nil
        }
        let targetIndex = selectIndex - 2
        guard targetIndex >= 0, targetIndex < hadFilterLanguages.count else {
            return nil
        }
        return targetIndex
    }

    public func filterRelatedLanguagesWithKeyword(_ keyword: String, complete: () -> Void) {
        let filterlanguages = languages
        hadFilterLanguages = filterlanguages.filter { $0.uppercased().contains(keyword.uppercased()) } // 搜索大小写不做区分
        complete()
    }

    public func resetFilterLanguages(complete: () -> Void) {
        hadFilterLanguages = languages
        complete()
    }
}
