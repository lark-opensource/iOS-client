//
//  MinutesSubtitlesViewController+Search.swift
//  Minutes
//
//  Created by yangyao on 2021/1/20.
//

import Foundation
import MinutesFoundation

extension MinutesSubtitlesViewController: MinutesKeyWordsViewDelegate {
    func keyWordsViewChangeStatus(_ view: MinutesKeyWordsView, shouldReload: Bool) {
        // 没必要再刷新，和subtitle一起刷新
        if shouldReload {
            self.reloadData()
        }
    }

    func keyWordsView(_ view: MinutesKeyWordsView, didTap keyWord: String) {
        isDragged = false
        self.delegate?.doKeyWordSearch(text: keyWord)
    }

    func keyWordsViewBeginSearchKeywords() {
        delegate?.didBeginSearchKeywords()
    }
}
