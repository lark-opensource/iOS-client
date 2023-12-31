//
//  MinutesKeyWordsViewModel.swift
//  Minutes
//
//  Created by panzaofeng on 2021/1/12.
//  Copyright © 2021年 wangcong. All rights reserved.
//

import UIKit
import MinutesFoundation
import MinutesNetwork

/// 选中item时的类型
public enum MinutesKeyWordsViewStatus {
    /// shrink: 收缩状态
    case shrink
    /// expand: 展开状态
    case expand
    /// 隐藏
    case hiden
    /// 无需展开
    case plain
}

enum KeyWordStatus {
    /// shrink: 收缩状态
    case data(text: String, isSelected: Bool)
}

class MinutesKeyWordsViewModel {

    private let keywordsViewTopMargin: CGFloat = 20
    private let keywordsViewBottomMargin: CGFloat = 16
    private let keywordsViewLineSpacing: CGFloat = 10
    private let keywordsViewItemHeight: CGFloat = 20
    private let keywordsViewItemSpacing: CGFloat = 8
    private let keywordsViewTextBorder: CGFloat = 4
    
    var keywordsViewWidth: CGFloat = 0

    var viewStatus: MinutesKeyWordsViewStatus = .hiden

    public var minutes: Minutes

    public var isClip: Bool {
        return minutes.isClip
    }

    public var isSupportASR: Bool {
        return minutes.basicInfo?.supportAsr == true
    }

    init(minutes: Minutes) {
        self.minutes = minutes
    }

    func configureDataAndUpdate(_ data: MinutesData, complete: (() -> Void)?) {
        let minViewWidth = 0.1
        guard keywordsViewWidth > minViewWidth else {
            return
        }
        DispatchQueue.global().async {[weak self] in
            var minutesData: [KeyWordStatus] = []

            for keyword in data.keywords {
                let keyWordStatus = KeyWordStatus.data(text: keyword, isSelected: false)
                minutesData.append(keyWordStatus)
            }
            
            self?.update(minutesData: &minutesData, callback: { (viewStatus, shrinkHeight, expandHeight) in
                DispatchQueue.main.async {
                    guard let self = self else {
                        return
                    }
                    self.shrinkHeight = shrinkHeight
                    self.expandHeight = expandHeight
                    self.data = minutesData
                    self.viewStatus = viewStatus
                    complete?()
                }
            })
        }
    }

    var shrinkHeight: CGFloat = 0
    var expandHeight: CGFloat = 0

    public var data: [KeyWordStatus] = []
    public var dataSelectedIndex: Int = -1

    func selectedItem(selectedIndex: Int, status: MinutesKeyWordsViewStatus) {
        processSelected(selectedIndex: selectedIndex, originalSelectedIndex: &dataSelectedIndex, datas: &data)
    }

    private func processSelected(selectedIndex: Int, originalSelectedIndex: inout Int, datas: inout [KeyWordStatus]) {
        if originalSelectedIndex >= 0 && originalSelectedIndex < datas.count {
            if case .data(let text, let isSelected) = datas[originalSelectedIndex] {
                datas[originalSelectedIndex] = .data(text: text, isSelected: false)
            }
        }
        if selectedIndex != originalSelectedIndex, selectedIndex >= 0 && selectedIndex < datas.count {
            if case .data(let text, let isSelected) = datas[selectedIndex] {
                originalSelectedIndex = selectedIndex
                datas[selectedIndex] = .data(text: text, isSelected: true)
            } else {
                originalSelectedIndex = -1
            }
        } else {
            originalSelectedIndex = -1
        }
    }

    func clearKeyWordSelected() {
        clearKeyWordSelectedInternal(originalSelectedIndex: &dataSelectedIndex, datas: &data)
    }

    private func clearKeyWordSelectedInternal(originalSelectedIndex: inout Int, datas: inout [KeyWordStatus]) {
        if originalSelectedIndex >= 0 && originalSelectedIndex < datas.count {
            if case .data(let text, let isSelected) = datas[originalSelectedIndex] {
                datas[originalSelectedIndex] = .data(text: text, isSelected: false)
            }
            originalSelectedIndex = -1
        }
    }

    // disable-lint: magic number
    func update(minutesData: inout [KeyWordStatus], callback: ((MinutesKeyWordsViewStatus, CGFloat, CGFloat) -> Void)? = nil) {
        // update 重置分割位
        var minutesDataStatusDividePosition = 0
        var minutesViewStatus: MinutesKeyWordsViewStatus = .hiden

        let itemSpace: CGFloat = keywordsViewItemSpacing
        let viewWidth: CGFloat = keywordsViewWidth
        var currentLine: NSInteger = 0
        var tempLineWidth: CGFloat = 0
      
        for textStatus in minutesData {
            if case .data(let text, let isSelected) = textStatus {
                var textWidth = text.size(withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12)]).width + keywordsViewTextBorder * 2
                if textWidth > viewWidth {
                    textWidth = viewWidth
                }
                if currentLine == 0 {
                    if tempLineWidth <= 0.01 {
                        tempLineWidth = textWidth
                        minutesViewStatus = .plain
                    } else {
                        if tempLineWidth + itemSpace + textWidth > viewWidth {
                            currentLine = 1
                            minutesViewStatus = .shrink
                            tempLineWidth = textWidth
                        } else {
                            tempLineWidth += itemSpace + textWidth
                            minutesViewStatus = .plain
                        }
                    }
                }
                else {
                    if tempLineWidth + itemSpace + textWidth > viewWidth {
                        currentLine += 1
                        tempLineWidth = textWidth
                    } else {
                        tempLineWidth += itemSpace + textWidth
                    }
                }
            }
        }
        var shrinkHeight: CGFloat = 0
        var expandHeight: CGFloat = 0
        if minutesViewStatus == .plain {
            shrinkHeight = keywordsViewTopMargin + keywordsViewBottomMargin + keywordsViewItemHeight
            expandHeight = keywordsViewTopMargin + keywordsViewBottomMargin + keywordsViewItemHeight
        } else if minutesViewStatus == .shrink {
            let height = CGFloat((keywordsViewItemHeight + keywordsViewLineSpacing) * CGFloat(currentLine + 1))
            shrinkHeight = keywordsViewTopMargin + keywordsViewBottomMargin + keywordsViewItemHeight
            expandHeight = keywordsViewTopMargin + keywordsViewBottomMargin + height - keywordsViewLineSpacing
        }
        callback?(minutesViewStatus, shrinkHeight, expandHeight)
    }
    // enable-lint: magic number

}
