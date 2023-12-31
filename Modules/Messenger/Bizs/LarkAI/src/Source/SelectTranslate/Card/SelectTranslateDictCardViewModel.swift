//
//  SelectTranslateDictCardViewModel.swift
//  LarkAI
//
//  Created by ByteDance on 2022/7/25.
//

import UIKit
import Foundation
import LarkUIKit
import LKCommonsLogging
import LarkContainer
import LarkMessengerInterface
import LarkMessageBase
import LarkModel
import LarkSDKInterface
import ServerPB

protocol SelectTranslateDictItemProtocol {
    var cellIdentifier: String { get }
}

// 划词翻译卡片-释义
struct DictSimpleDefinitionTextModel: SelectTranslateDictItemProtocol {
    var cellIdentifier: String
    var partOfSpeech: String // 词性
    var definitionText: String // 释义
    var copyConfig: TranslateCopyConfig // 复制权限配置
}

// 划词翻译卡片-英英释义
struct DictEnglishDefinitionModel: SelectTranslateDictItemProtocol {
    var cellIdentifier: String
    var englishDefinitionIndex: Int32 // 索引
    var englishDefinitionText: String // 释义
    var copyConfig: TranslateCopyConfig // 复制权限配置
}

// 划词翻译卡片-双语例句
struct DictExampleSentenceModel: SelectTranslateDictItemProtocol {
    var cellIdentifier: String
    var exampleSentenceIndex: Int32
    var translationText: String // 例句译文
    var originText: String // 例句原文
    var copyConfig: TranslateCopyConfig // 复制权限配置
}

final class SelectTranslateDictCardViewModel {

    weak var viewController: UIViewController?
    var originTextString: String = "" // 后端返回需要展示的原文字段
    var translateText: String = ""
    let selectTranslateDictModel: ServerPB_Translate_TranslateDictCard
    let copyConfig: TranslateCopyConfig
    /// 走词典数据源
    private(set) var items: [[SelectTranslateDictItemProtocol]] = []
    /// section 0 释义
    private(set) var selectTranslateDictSimpleDefinitionSection: [SelectTranslateDictItemProtocol] = []
    /// section1 英英释义
    private(set) var selectTranslateDictEnglishDefinitionSection: [SelectTranslateDictItemProtocol] = []
    /// section2 双语例句
    private(set) var selectTranslateDictExampleSentenceSection: [SelectTranslateDictItemProtocol] = []

    var params: [String: Any] = [:]
    private(set) var headerViews: [() -> UIView] = []
    private(set) var footerViews: [() -> UIView] = []
    init(translateDictData: ServerPB_Translate_TranslateDictCard,
         trackParam: [String: Any],
         copyConfig: TranslateCopyConfig
    ) {
        self.selectTranslateDictModel = translateDictData
        self.params = trackParam
        self.copyConfig = copyConfig
        self.items = self.createDataSource()
        self.headerViews = self.createHeaderViews()
        self.footerViews = self.createFooterViews()
    }
    /// 创建数据源
    private func createDataSource() -> [[SelectTranslateDictItemProtocol]] {
        var tempItems: [[SelectTranslateDictItemProtocol]] = []
        var englishDefinitionIndex: Int32 = 0
        var exampleSetenceIndex: Int32 = 0
        originTextString = selectTranslateDictModel.text
        selectTranslateDictModel.definitions.forEach { (definition) in
            selectTranslateDictSimpleDefinitionSection.append(
                DictSimpleDefinitionTextModel(
                    cellIdentifier: DictSimpleDefinitionTableViewCell.lu.reuseIdentifier,
                    partOfSpeech: definition.pos,
                    definitionText: definition.definitionText,
                    copyConfig: copyConfig
                )
            )
            translateText.append(definition.definitionText)
            definition.detailDefinitions.forEach { (detailDefinition) in
                englishDefinitionIndex += 1
                selectTranslateDictEnglishDefinitionSection.append(
                    DictEnglishDefinitionModel(
                        cellIdentifier: DictEnglishDefinitionTableViewCell.lu.reuseIdentifier,
                        englishDefinitionIndex: englishDefinitionIndex,
                        englishDefinitionText: detailDefinition,
                        copyConfig: copyConfig
                    )
                )
            }
            definition.examples.forEach { (example) in
                exampleSetenceIndex += 1
                selectTranslateDictExampleSentenceSection.append(
                    DictExampleSentenceModel(
                        cellIdentifier: DictExampleSentenceTableViewCell.lu.reuseIdentifier,
                        exampleSentenceIndex: exampleSetenceIndex,
                        translationText: example.translation,
                        originText: example.origin,
                        copyConfig: copyConfig
                    )
                )
            }
        }
        tempItems.append(selectTranslateDictSimpleDefinitionSection)
        tempItems.append(selectTranslateDictEnglishDefinitionSection)
        tempItems.append(selectTranslateDictExampleSentenceSection)
        return tempItems
    }
    /// 创建头部视图
    private func createHeaderViews() -> [() -> UIView] {
        func createNormalHeaderView(title: String) -> UIView {
            let view = UIView()
            let topMagin = title.isEmpty ? 16 : 29
            let bottomMagin = title.isEmpty ? 0 : -13
            let detailLabel = UILabel()
            detailLabel.font = UIFont.systemFont(ofSize: 14)
            detailLabel.numberOfLines = 0
            detailLabel.textColor = UIColor.ud.textPlaceholder
            detailLabel.text = title
            view.addSubview(detailLabel)
            detailLabel.snp.makeConstraints { (make) in
                make.top.equalTo(topMagin)
                make.bottom.equalTo(bottomMagin)
                make.left.equalTo(0)
                make.right.equalTo(0)
            }
            return view
        }

        var tempHeaderViews: [() -> UIView] = []
        /// section 0
        if !selectTranslateDictSimpleDefinitionSection.isEmpty {
            tempHeaderViews.append {
                return createNormalHeaderView(title: "")
            }
        } else {
            tempHeaderViews.append {
                let view = UIView()
                view.snp.makeConstraints { $0.height.equalTo(1) }
                return view
            }
        }

        /// section 1
        if !selectTranslateDictEnglishDefinitionSection.isEmpty {
            tempHeaderViews.append {
                return createNormalHeaderView(title: BundleI18n.LarkAI.Lark_ASL_SelectTranslateQuoteDictionary_EnglishDefinition_SectionTitle)
            }
        } else {
            tempHeaderViews.append {
                let view = UIView()
                view.snp.makeConstraints { $0.height.equalTo(1) }
                return view
            }
        }

        if !selectTranslateDictExampleSentenceSection.isEmpty {
            tempHeaderViews.append {
                return createNormalHeaderView(title: BundleI18n.LarkAI.Lark_ASL_SelectTranslateQuoteDictionary_BilingualExamples_SectionTitle)
            }
        } else {
            tempHeaderViews.append {
                let view = UIView()
                view.snp.makeConstraints { $0.height.equalTo(1) }
                return view
            }
        }

        return tempHeaderViews
    }

    /// 创建尾部视图
    private func createFooterViews() -> [() -> UIView] {
        var tempFooterViews: [() -> UIView] = []
        /// section 0 =
        tempFooterViews.append {
            let view = UIView()
            view.snp.makeConstraints { $0.height.equalTo(1) }
            return view
        }
        /// section 1

        tempFooterViews.append {
            let view = UIView()
            view.snp.makeConstraints { $0.height.equalTo(1) }
            return view
        }

        /// section 2
        tempFooterViews.append {
            let view = UIView()
            view.snp.makeConstraints { $0.height.equalTo(1) }
            return view
        }
        return tempFooterViews
    }
}
