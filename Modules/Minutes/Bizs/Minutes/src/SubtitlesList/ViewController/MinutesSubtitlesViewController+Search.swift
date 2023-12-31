//
//  MinutesSubtitlesViewController+Search.swift
//  Minutes
//
//  Created by yangyao on 2021/1/20.
//

import Foundation
import MinutesFoundation
import MinutesNetwork

extension MinutesSubtitlesViewController: MinutesSearchViewDataProvider {
    func searchViewTotalCount(_ view: MinutesSearchView) -> Int {
        return totalIndex
    }
    func searchViewCurrentIndex(_ view: MinutesSearchView) -> Int {
        return searchIndex + 1
    }
}

extension MinutesSubtitlesViewController {
    func enterSearch() {
        isInSearchPage = true

        removeRefreshHeader()
    }

    func clearSearch() {
        totalIndex = 0
        searchIndex = -1
        for vm in viewModel.data {
            vm.clearSearchRanges()
        }
        tableView?.reloadData()
    }

    func exitSearch() {
        isInSearchPage = false
        searchViewModel = nil
        keywordsView.unselectKeywords()
        clearSearch()

        if !viewModel.data.isEmpty {
            configHeaderRefresh()
        }
        
        invaliateSearchWaitingTimer()
    }

    func unselectKeywordsView() {
        keywordsView.unselectKeywords()
    }

    @objc func goSearchNext() {
        guard let searchViewModel = searchViewModel else {
            return
        }
        searchIndex += 1
        if searchIndex == searchViewModel.searchResults.count {
            searchIndex = 0
        }
        updateSearchOffset()
    }

    @objc func goSearchPre() {
        guard let searchViewModel = searchViewModel else {
            return
        }
        searchIndex -= 1
        if searchIndex < 0 {
            searchIndex = searchViewModel.searchResults.count - 1
        }
        updateSearchOffset()
    }

    func createSearchWaitingTimer(_ handler: (() -> Void)?) {
        searchWaitingTimer = Timer(timeInterval: 1.0, repeats: true, block: { [weak self] (_) in
            handler?()
        })
        if let timer = searchWaitingTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    func invaliateSearchWaitingTimer() {
        searchWaitingTimer?.invalidate()
        searchWaitingTimer = nil
    }
    
    @objc func goSearch(_ text: String, type: Int, callback: (() -> Void)?) {
        let handler = { [weak self] in
            guard let self = self else { return }
            
            self.invaliateSearchWaitingTimer()
            if self.viewModel.isInTranslationMode {
                self.viewModel.minutes.translateData?.find(query: text, type: FindType(rawValue: type) ?? .normal) { [weak self] result in
                    self?.searchResultHandler(type, result: result, callback: callback)
                }
            } else {
                self.viewModel.minutes.data.find(query: text, type: FindType(rawValue: type) ?? .normal) { [weak self] result in
                    self?.searchResultHandler(type, result: result, callback: callback)
                }
            }
        }
        
        if !isFirstAllDataReady {
            createSearchWaitingTimer { [weak self]  in
                guard let self = self else { return }
                
                if self.isFirstAllDataReady == true {
                    handler()
                }
            }
        } else {
            handler()
        }
    }

    func searchResultHandler(_ type: Int, result: Result<FindResult, Error>, callback: (() -> Void)?) {
        switch result {
        case .success(let data):
            let searchResult = data
            if searchResult.timeline.isEmpty {
                DispatchQueue.main.async {
                    self.totalIndex = 0
                    self.searchIndex = 0

                    callback?()
                }
            } else {
                // 子线程
                serialQueue.async {
                    let searchViewModel = MinutesSearchViewModel(result: searchResult,
                                                                 pidAndSentenceDict: self.viewModel.pidAndSentenceDict,
                                                                 sentenceContentLenDict: self.viewModel.sentenceContentLenDict, pidAndIdxDict:
                                                                    self.viewModel.pidAndIdxDict)
                    self.searchViewModel = searchViewModel
                    for (idx, vm) in self.viewModel.data.enumerated() {
                        vm.searchRanges = searchViewModel.searchResultDict[idx]
                    }

                    // 主线程
                    DispatchQueue.main.async {
                        self.totalIndex = searchViewModel.searchResults.count
                        self.searchIndex = -1

                        self.goSearchNext()
                        // 完成之后会去取index
                        callback?()
                    }

                    var actionType = "nonblank_input_enter"
                    if type == 0 {
                        actionType = "nonblank_input_auto"
                    } else if type == 1 {
                        actionType = "nonblank_input_enter"
                    } else {
                        actionType = "keywords_input"
                    }
                    self.tracker.tracker(name: .clickButton, params: ["action_name": "subtitle_search",
                         "action_type": actionType,
                         "action_result": self.totalIndex])

                    self.tracker.tracker(name: .detailClick, params: ["click": "subtitle_search",
                         "action_type": actionType,
                         "action_language": self.dataProvider?.translationChosenLanguage(),
                         "target": "none"])
                }
            }
        case .failure(let error):
            DispatchQueue.main.async {
                callback?()
            }
        }
    }
}
