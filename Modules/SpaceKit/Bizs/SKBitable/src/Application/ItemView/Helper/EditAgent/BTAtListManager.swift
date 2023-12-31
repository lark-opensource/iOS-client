//
//  BTAtListManager.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/4/13.
//  


import UIKit
import SKCommon
import SKBrowser
import SKFoundation
import UniverseDesignColor
import SpaceInterface

protocol BTAtListMangerDelegate: AnyObject {
    func atListGetCoordinator() -> BTEditCoordinator?
    func atListDidSelect(keyword: String, with info: AtInfo)
    func atListGetRelateTextView() -> UITextView?
    func atListViewDidShow() 
    func atListViewDidHide()
}

extension BTAtListMangerDelegate {
    func atListViewDidShow() {}
    func atListViewDidHide() {}
}

final class BTAtListManager {
    
    weak var delegate: BTAtListMangerDelegate?
    
    var coordinator: BTEditCoordinator? {
        return delegate?.atListGetCoordinator()
    }
    // 可由外部来设置面板筛选类型。
    var atViewFilter: Set<AtDataSource.RequestType> = AtDataSource.RequestType.atViewFilter
    
    var atContext: (str: String, location: Int)? {
        didSet {
            var keyword = atContext?.str
            if let str = atContext?.str, str == "@" {
                keyword = ""
            }
            if let first = keyword?.first, first == "@" {
                keyword?.removeFirst()
            }
            refreshAtListView(with: keyword)
        }
    }
    
    let atListViewHeight: CGFloat = 220.0

    private var isShowingAtListView: Bool = false

    private lazy var atListView: AtListView? = {
        guard let fileType = coordinator?.editorDocsInfo.type,
              let token = coordinator?.editorDocsInfo.objToken
        else {
            spaceAssertionFailure()
            return nil
        }
        let atConfig = AtDataSource.Config(chatID: coordinator?.hostChatId, sourceFileType: fileType, location: .comment, token: token)
        let dataSource = AtDataSource(config: atConfig)
        let atListView = AtListView(dataSource, type: .comment)
        atListView.selectAction = { [weak self]  atInfo, _, index in
            guard let atInfo = atInfo, let context = self?.atContext else { return }
            var keyword = context.str
            if context.str.count == 0 {
                keyword = "@"
            }
            self?.delegate?.atListDidSelect(keyword: keyword, with: atInfo)
            self?.hideAtListView()
        }
        atListView.cancelAction = { [weak self] in
            self?.hideAtListView()
        }
        return atListView
    }()

    func showAtListView() {
        guard let at = atListView else { return }
        isShowingAtListView = true
        guard let inputSuperview = coordinator?.inputSuperview, let coordinator = coordinator else { return }
        if !inputSuperview.contains(at) {
            inputSuperview.addSubview(at)
            at.snp.makeConstraints({ (make) in
                make.height.equalTo(atListViewHeight)
                make.bottom.equalToSuperview().offset(-coordinator.keyboardHeight)
                make.width.left.equalToSuperview()
            })
        }
        delegate?.atListViewDidShow()
    }

    func hideAtListView() {
        isShowingAtListView = false
        if atListView != nil && atListView?.superview != nil {
            atListView?.removeFromSuperview()
            delegate?.atListViewDidHide()
        }
    }

    func refreshAtListView(with key: String?) {
        guard let str = key else { return }
        atListView?.refresh(with: str, filter: atViewFilter)
    }

    func handleAtIfNeeded(_ textView: UITextView) {
        if let last = textView.text.last, last == "@" {
            if let range = textView.text.range(of: "@", options: .backwards) {
                let location = textView.text.distance(from: textView.text.startIndex, to: range.lowerBound)
                atContext = ("", location + 1)
            }
        }
        atContext?.str = fetchKeyword(textView.text, selectRange: textView.selectedRange)
    }

    private func fetchKeyword(_ text: String, selectRange: NSRange) -> String {
        guard let editingTextView = delegate?.atListGetRelateTextView() else { return "" }
        let index = AtInfo.removeEmojiLocation(with: editingTextView, location: selectRange.location)
        let textBeforeSelectLocation = text.mySubString(to: index)
        if let lastAtIndex = textBeforeSelectLocation.lastIndex(of: "@") {
            let keyword = String(textBeforeSelectLocation[lastAtIndex...])
            if keyword.last == " " || keyword.last == "\n" {
                return ""
            } else {
                return keyword
            }
        } else { // 找不到 @
            return ""
        }
    }
}
