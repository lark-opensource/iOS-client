//
//  MinutesSummaryViewModel.swift
//  Minutes
//
//  Created by Todd Cheng on 2021/5/12.
//

import Foundation
import MinutesFoundation
import MinutesNetwork
import LarkContainer
import LarkSetting

enum MinutesSummaryContentType:Int {
    case AISumary = 18
    case AITodo = 19
}


public final class MinutesSummaryViewModel {
    var phrasesCache: [Int: [LingoDictPhrases]] = [:]
    var phraseingCache: [String: Bool] = [:]

    public typealias MinutesSummaryCellData = (contentId: String,
                                               startTime: Int,
                                               content: String,
                                               type: SummaryContentType,
                                               isChecked: Bool,
                                               isSubsection: Bool,
                                               isSubsectionHeader: Bool,
                                               subsectionHeaderTitle: String?,
                                               sectionId: Int,
                                               dPhrases: [Phrase])

    public var data: [[String: [MinutesSummaryCellData]]] = []

    var minutes: Minutes

    private var originalSummaryContentList: [String: SummaryContentList] = [:]

    var showEmptyView: Bool = false

    let userResolver: UserResolver

    init(minutes: Minutes, userResolver: UserResolver) {
        self.minutes = minutes
        self.userResolver = userResolver
        parseSummariesData()
    }

    func parseSummariesData() {
        guard let someSummaries = minutes.info.summaries, let someSectionList = someSummaries.sectionList, someSummaries.total != 0 else {
            data = []
            showEmptyView = true
            return
        }
        data = []
        for section in someSectionList {
            let subsectionList = section.subsectionList ?? []
            if subsectionList.isEmpty == false {
                for (idx, subsection) in subsectionList.enumerated() {
                    var minutesSummaryCellDatas: [MinutesSummaryCellData] = []
                    for contentId in (subsection.contentIds ?? []) {
                        if let content = someSummaries.contentList?[contentId] {
                            minutesSummaryCellDatas.append((content.contentId,
                                                            content.startTime,
                                                            content.data,
                                                            content.contentType,
                                                            content.checked,
                                                            isSubsection: true,
                                                            isSubsectionHeader: idx == 0,
                                                            subsectionHeaderTitle: section.title,content.sectionId, dPhrases: []))
                        }
                    }
                    if minutesSummaryCellDatas.isEmpty { continue }
                    data.append([subsection.title: minutesSummaryCellDatas])
                }
            } else {
                var minutesSummaryCellDatas: [MinutesSummaryCellData] = []
                for contentId in (section.contentIds ?? []) {
                    if let content = someSummaries.contentList?[contentId] {
                        minutesSummaryCellDatas.append((content.contentId,
                                                        content.startTime,
                                                        content.data,
                                                        content.contentType,
                                                        content.checked,
                                                        isSubsection: false,
                                                        isSubsectionHeader: false, subsectionHeaderTitle: nil, content.sectionId,
                                                        dPhrases: []))
                    }
                }

                if minutesSummaryCellDatas.isEmpty { continue }
                data.append([section.title: minutesSummaryCellDatas])
            }
        }

        showEmptyView = parseContentIds()
    }

    private func parseContentIds() -> Bool {
        var showEmptyView = false
        var contentIds: [String] = []
        if minutes.info.summaries?.sectionList?.isEmpty == true {
            showEmptyView = true
        } else {
            for section in minutes.info.summaries?.sectionList ?? [] {
                let subsectionList = section.subsectionList ?? []
                if subsectionList.isEmpty {
                    contentIds.append(contentsOf: section.contentIds ?? [])
                } else {
                    for subsection in subsectionList {
                        contentIds.append(contentsOf: subsection.contentIds ?? [])
                    }
                }
            }
        }
        showEmptyView = contentIds.isEmpty
        return showEmptyView
    }

    func storeOriginalSummaries(isNeedRequest: Bool) {
        if isNeedRequest {
            minutes.info.fetchSummaries(catchError: false, language: .default, completionHandler: { [weak self] result in
                guard let wSelf = self else { return }
                DispatchQueue.main.async {
                    switch result {
                    case .success(let data):
                        wSelf.originalSummaryContentList = data.contentList ?? [:]
                    case .failure:
                        break
                    }
                }
            })
        } else {
            originalSummaryContentList = minutes.info.summaries?.contentList ?? [:]
        }
    }

    func getOriginalSummaryContent(with contentId: String) -> String? {
        if originalSummaryContentList.isEmpty {
            return nil
        }

        if let content = originalSummaryContentList[contentId] {
            return content.data
        }
        return nil
    }

    func requestCheckbox(contentId: String, isChecked: Bool) {
        minutes.updateSummaryCheckbox(contentId: contentId, isChecked: isChecked) { _ in }
    }

    func updateCheckStatus(with indexPath: IndexPath, isChecked: Bool) {
        if let array = data[indexPath.section].values.first {
            let content = array[indexPath.row]
            let newItem: MinutesSummaryCellData = (content.0,
                                                   content.1,
                                                   content.2,
                                                   content.3,
                                                   isChecked,
                                                   content.5,
                                                   content.6,
                                                   content.7,
                                                   content.8,
                                                   content.9)
            var newArray = array
            newArray[indexPath.row] = newItem
            let key = minutes.info.summaries?.sectionList?[indexPath.section].title ?? "defaultKey"
            data[indexPath.section] = [key: newArray]
        }
    }
}

extension MinutesSummaryViewModel {
    // disable-lint: duplicated_code
    func queryDict(with section: Int, completion: (() -> Void)?) {
        guard data.isEmpty == false else { return }
        var visibleText: [String] = []

        var rowData: [MinutesSummaryCellData] = []
        var info: [String: [MinutesSummaryCellData]] = [:]

        if data.indices.contains(section), let array = data[section].values.first, array.isEmpty == false {
            let content = array.map { (element) in
                return element.content
            }
            visibleText.append(contentsOf: content)
            info = data[section]
            rowData = array
        }

        guard visibleText.isEmpty == false else {
            DispatchQueue.main.async {
                completion?()
            }
            return
        }

        let request = LingoDictQueryRequest(objectToken: minutes.objectToken, texts: visibleText, catchError: true)
        minutes.api.sendRequest(request) { [weak self] (result) in
            guard let self = self else { return }
            let r = result.map({ $0.data })

            switch r {
            case .success(let data):
                let phrases = data.phrases

                for (idx, phrase) in phrases.enumerated() {
                    if rowData.indices.contains(idx) {
                        var v = rowData[idx]
                        var dPhrases: [Phrase] = []
                        for p in phrase {
                            let range = NSRange(location: p.span.start, length: p.span.end - p.span.start)
                            let phrase = Phrase(name: p.name, dictId: p.ids.first, range: range)
                            dPhrases.append(phrase)
                        }
                        v.dPhrases = dPhrases
                        rowData[idx] = v
                    }

                    if let key = info.keys.first {
                        info.removeAll()
                        info[key] = rowData
                    }
                    if self.data.indices.contains(section) {
                        self.data[section] = info
                    }
                }
                DispatchQueue.main.async {
                    completion?()
                }
            case .failure(let error):
                MinutesLogger.network.error("summary lingo dict query failed: \(error)")
            }
        }
    }
    // enable-lint: duplicated_code
}
