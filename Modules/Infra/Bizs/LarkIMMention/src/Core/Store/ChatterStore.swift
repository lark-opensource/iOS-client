//
//  ChatterStore.swift
//  LarkIMMention
//
//  Created by Yuri on 2022/12/8.
//

import UIKit
import Foundation
import RxSwift
import RustPB

enum ChatterProviderResult {
    case recommand(RustPB.Im_V1_GetMentionChatChattersResponse)
    case search(String, RustPB.Im_V1_GetMentionChatChattersResponse)
}

class ChatterStore: MentionStore {
    
    private let wantedSectionTitle = I18N.Lark_Legacy_ProbabilityAtPersonHint
    
    override func handleRecommendReuslt(_ res: ProviderResult) {
        assert(res.result.count == 3, "Chatter Data must has wanted, inChat, outChat")
        super.handleRecommendReuslt(res)
        var sections = [IMMentionReuslt.Section]()
        var indexFrom = 0
        // all
        if hasAtAll() {
            let items = [IMPickerOption.all(count: context.chatUserCount, showChatUserCount: context.showChatUserCount)]
                .mapTrackInfo(pageType: .user, chooseType: .recommend)
            let section = IMMentionReuslt.Section(title: nil, items: items)
            sections.append(section)
            indexFrom = 1
        }
        if res.result.count > 2 {
            // wanted
            let wantedRes = res.result[0]
            if !wantedRes.isEmpty {
                let wantedSection = handleRecommendWantedChattersSection(items: res.result[0])
                sections.append(wantedSection)
            }
            // in chat
            let inChatSections = handleRecommendInChatChattersSection(items: res.result[1], indexFrom: indexFrom)
            sections.append(contentsOf: inChatSections)
        }
        currentItems = IMMentionReuslt(sections: sections)
        handleNameIndex()
    }
    
    private func handleRecommendWantedChattersSection(items: [IMMentionOptionType]) -> IMMentionReuslt.Section {
        
        let wantedItems = items.mapTrackInfo(pageType: .user, chooseType: .recommend)
        let wantedSection = IMMentionReuslt.Section(title: wantedSectionTitle, items: wantedItems)
        return wantedSection
    }
    
    private func handleRecommendInChatChattersSection(items: [IMMentionOptionType], indexFrom: Int) -> [IMMentionReuslt.Section] {
        let inChatSectionTitle = I18N.Lark_Legacy_AllMember
        let allChatterSection = IMMentionReuslt.Section(title: inChatSectionTitle, items: [])
        let inChatItems = items.mapTrackInfo(pageType: .user, chooseType: .recommend)
        let groupedWords = Dictionary(grouping: inChatItems, by: {
            $0.actualName?.getNameCharacter() ?? "#"
        })
        let sortedGroupedWords = groupedWords.sorted(by: { $0.key < $1.key })
        var result = [allChatterSection]
        result.append(contentsOf: sortedGroupedWords.map {
            IMMentionReuslt.Section(title: $0.key, items: $0.value, isInitialSection: true)
        })
        return result
    }
    
    private func handleNameIndex() {
        var nameIndex = [String]()
        var indexMap = [Int: Int]()
        for (i, section) in currentItems.sections.enumerated() {
            guard let title = section.title else { continue }
            if title == wantedSectionTitle {
                indexMap[nameIndex.count] = i
                nameIndex.append("@")
            }
            if section.isInitialSection {
                indexMap[nameIndex.count] = i
                nameIndex.append(title)
            }
        }
        currentState.nameIndex = nameIndex
        currentState.nameDict = indexMap
    }
    
    override func handleSearchReuslt(_ res: ProviderResult) {
        assert(res.result.count == 3, "Chatter Data must has wanted, inChat, outChat")
        super.handleSearchReuslt(res)
        // all wanted in
        var sections = [IMMentionReuslt.Section]()
        if res.result.count > 2 {
            let inChatSectionTitle = I18N.Lark_IM_SearchForMembersOrDocs_MembersInThisChat_Title
            let outChatSectionTitle = "\(I18N.Lark_IM_SearchForMembersOrDocs_MembersNotInThisChat_Title) \(I18N.Lark_IM_TheyWontReceiveThisMessage_Desc)"
            let inChatItems = res.result[1].mapTrackInfo(pageType: .user, chooseType: .search)
            let outChatItems = res.result[2].mapTrackInfo(pageType: .user, chooseType: .search)
            let inChatSection = IMMentionReuslt.Section(title: inChatSectionTitle, items: inChatItems, isShowFooter: inChatItems.isEmpty)
            let outChatSection = IMMentionReuslt.Section(title: outChatSectionTitle, items: outChatItems)
            sections.append(inChatSection)
            sections.append(outChatSection)
        }
        currentItems = IMMentionReuslt(sections: sections)
    }
    
    private func covertProviderReusltToSection(res: [IMMentionOptionType], title: String?) -> IMMentionReuslt.Section {
        return IMMentionReuslt.Section(title: title, items: res)
    }
    
    private func hasAtAll() -> Bool {
        return context.isEnableAtAll && context.chatUserCount > 0
    }
}

extension IMPickerOption {
    static func all(count: Int32, showChatUserCount: Bool) -> IMMentionOptionType {
        var item = IMPickerOption()
        item.id = "all"
        item.type = .chatter
        item.actualName = BundleI18n.LarkIMMention.Lark_IM_SearchForMembersOrDocs_MentionAll_Text
        if showChatUserCount {
            item.name = NSAttributedString(string: "\(BundleI18n.LarkIMMention.Lark_IM_SearchForMembersOrDocs_MentionAll_Text)(\(count))")
        } else {
            item.name = NSAttributedString(string: "\(BundleI18n.LarkIMMention.Lark_IM_SearchForMembersOrDocs_MentionAll_Text)")
        }
        item.desc = NSAttributedString(string: BundleI18n.LarkIMMention.Lark_IM_SearchForMembersOrDocs_MentionAll_Desc)
        item.isInChat = true
        return item
    }
}

extension Character {
    func canTransformToPinyinHead() -> Bool {
        return isChinese() || isLetter()
    }

    func isChinese() -> Bool {
        return "\u{4E00}" <= self && self <= "\u{9FA5}"
    }

    func isLetter() -> Bool {
        return self >= "A" && self <= "z"
    }
}

extension String {
    func getNameCharacter() -> String {
        var key = "#"
        let firstLetter = String(self.prefix(1))
        if let first = firstLetter.first, first.canTransformToPinyinHead() {
            key = firstLetter.transformToPinyinHead()
        }
        return key
    }
    
    func transformToPinyin(hasBlank: Bool = false) -> String {
        let stringRef = NSMutableString(string: self) as CFMutableString
        CFStringTransform(stringRef, nil, kCFStringTransformToLatin, false)
        CFStringTransform(stringRef, nil, kCFStringTransformStripCombiningMarks, false)
        let pinyin = stringRef as String
        return hasBlank ? pinyin : pinyin.replacingOccurrences(of: " ", with: "")
    }

    func transformToPinyinHead(lowercased: Bool = false) -> String {
        let pinyin = transformToPinyin(hasBlank: true).capitalized
        var headPinyinStr = ""
        for ch in pinyin {
            if ch <= "Z" && ch >= "A" {
                headPinyinStr.append(ch)
            }
        }
        return lowercased ? headPinyinStr.lowercased() : headPinyinStr
    }
}
