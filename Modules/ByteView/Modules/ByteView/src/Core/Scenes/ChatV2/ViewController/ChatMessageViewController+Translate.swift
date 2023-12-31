//
//  ChatMessageViewController+Translate.swift
//  ByteView
//
//  Created by wulv on 2021/11/18.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RichLabel
import UniverseDesignIcon
import RxSwift
import ByteViewNetwork
import ByteViewTracker
import ByteViewSetting

extension ChatMessageViewController {
    func showMenu(location: CGPoint) {
        // 定位到具体的触发cell
        guard let indexPath = tableView.indexPathForRow(at: location),
              let cell = tableView.cellForRow(at: indexPath) as? ChatMessageCell,
              let message = viewModel.message(at: indexPath.row) else { return }
        let locationForCell = tableView.convert(location, to: cell)
        guard let contentLabel = cell.getcontentLabel(location: locationForCell) as? LKSelectionLabel,
              let text = contentLabel.attributedText, text.length > 0 else { return }

        setSelectionRange(range: nil)
        menu?.dismiss()

        let menuLayout = ChatMessageSelectionMenuLayout(cell: cell, targetLabel: contentLabel)
        let menuVC = VCMenuViewController()
        menuVC.menuLayout = menuLayout
        menuVC.delegate = self

        let items = buildMenuItems(message: message)
        menuVC.updateItems(items)
        menuVC.add(to: self)

        self.menu = menuVC
        self.selectedLabel = contentLabel
        self.selectedCell = cell
        setSelectionRange(range: NSRange(0..<text.length))

        handleConflictGesture()
        updateEditViewLocation()
        // 弹出翻译菜单时，锁定消息刷新
        viewModel.freezeMessages()
    }

    private func buildMenuItems(message: ChatMessageCellModel) -> [VCMenuItem] {
        let translate = TranslateMenuItem(model: message)
        translate.clickHandler = { [weak self] item in
            guard let self = self, let range = self.selectedRange else { return }
            self.handleTranslateItemClick(item, messageID: message.id, selectedRange: range)
        }
        self.translateItem = translate
        return [translate]
    }

    func updateTranslateItem(with selectedRange: NSRange) {
        // 已经翻译完成的item，再次选中时，根据选中范围决定是选词翻译还是显示原文
        guard let menuVC = menu, let item = translateItem else { return }
        if isSelectAll(range: selectedRange) {
            item.resetAction()
        } else {
            item.changeToTranslationAction()
        }
        menuVC.updateItems([item])
    }

    func updateMenuStateWhenEndScroll() {
        guard let menuVC = menu, let selectedCell = selectedCell else { return }
        let tableShowRect = CGRect(x: tableView.contentOffset.x,
                                   y: tableView.contentOffset.y,
                                   width: tableView.frame.width,
                                   height: tableView.frame.height)
        if selectedCell.frame.intersects(tableShowRect) {
            menuVC.show(animated: true)
        } else {
            resetSelection()
        }
    }

    func recoveryMenu() {
        isLoadingMore = false
        guard isShowingMenu() else { return }
        updateMenuStateWhenEndScroll()
    }

    func isShowingMenu() -> Bool {
        return menu != nil
    }

    func getSelectedRect() -> CGRect {
        var rect: CGRect = .zero
        if let selectLabel = selectedLabel {
            let transformedLabel = selectLabel.convert(selectLabel.bounds, to: view)
            let startC = selectLabel.convert(selectLabel.startCursor.rect, to: view)
            let endC = selectLabel.convert(selectLabel.endCursor.rect, to: view)
            // 说明在同一行
            if startC.minY == endC.minY {
                rect.origin = CGPoint(x: startC.minX, y: startC.minY)
                rect.size = CGSize(width: endC.maxX - startC.minX, height: startC.height)
            }
            // 选择了多行
            else {
                rect.origin = CGPoint(x: transformedLabel.minX, y: startC.minY)
                rect.size = CGSize(width: transformedLabel.width, height: endC.maxY - startC.minY)
            }
            return rect
        }
        return rect
    }

    func isSelectAll(range: NSRange) -> Bool {
        range == selectedLabel?.visibleTextRange
    }

    func getSelectedText(range: NSRange) -> [String] {
        if let text = selectedLabel?.attributedText?.attributedSubstring(from: range).string {
            let splitText = text.components(separatedBy: "\n")
            return splitText
        }
        return []
    }

    func showSelectedTranslationCard(isSuccess: Bool, content: [String], language: String) {
        guard isSuccess else {
            resetSelection()
            return
        }

        let rect: CGRect = getSelectedRect()
        let card = TranslateView(delegate: self, text: content, language: language, selectRect: rect, topVC: self)
        card.dismissClosure = { [weak self] in
            self?.resetSelection()
        }
        card.show()
    }

    func scrollToBottomAfterTranslation(sources: [String: TranslateSource]) {
        // 如果最后一行被手动翻译完，自动滚动到该行底部
        if let indexPath = lastVisibleIndexPath,
            let cellModel = viewModel.message(at: indexPath.row),
            sources[cellModel.id] == .manualTranslate {
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }

    func handleTranslateItemClick(_ item: TranslateMenuItem, messageID: String, selectedRange range: NSRange) {
        if item.action == .translate {
            if isSelectAll(range: range) {
                VCTracker.post(name: .vc_meeting_chat_send_message_click, params: [.click: "translate_sentence"])
                translateMessage(messageID: messageID)
            } else {
                VCTracker.post(name: .vc_meeting_chat_send_message_click, params: [.click: "translate_word"])
                translateSelectedText()
            }
        } else if item.action == .hideTranslation {
            VCTracker.post(name: .vc_meeting_chat_send_message_click, params: [.click: "close_translation"])
            resetSelection()
            viewModel.changeDisplayRule(.noTranslation, forMessage: messageID)
        } else if item.action == .showOriginal {
            VCTracker.post(name: .vc_meeting_chat_send_message_click, params: [.click: "show_origin"])
            resetSelection()
            viewModel.changeDisplayRule(.noTranslation, forMessage: messageID)
        }
    }

    // 手动翻译
    func translateMessage(messageID: String) {
        showTranslationDrawer { [weak self] language in
            guard let self = self else { return }
            self.resetSelection()
            self.viewModel.translateMessage(with: messageID, languageKey: language.key)
            VCTracker.post(name: .vc_meeting_chat_send_message_click, params: [.click: "choose_language", "translage_language": language.key])
        }
    }

    // 划词翻译
    func translateSelectedText() {
        guard let selectedRange = selectedRange else { return }
        let selectedText = getSelectedText(range: selectedRange)
        if selectedText.isEmpty { return }

        showTranslationDrawer { [weak self] language in
            guard let self = self else { return }
            self.viewModel.translateText(selectedText, languageKey: language.key)
            VCTracker.post(name: .vc_meeting_chat_send_message_click, params: [.click: "choose_language", "translage_language": language.key])
        }
    }

    // 展示可选语言列表
    private func showTranslationDrawer(onSelection: @escaping (TranslateLanguage) -> Void) {
        let languages = viewModel.translationLanguages
        if languages.isEmpty { return }
        let translateCenter = SelectTargetDrawerCenter(router: viewModel.meeting.router, languages: languages.map { $0.name }, dismissCallBack: { [weak self] in
            self?.resetSelection()
        }, selectedCallBack: { index in
            onSelection(languages[index])
        })
        translateCenter.showSelectDrawer()
    }
}

extension ChatMessageViewController {

    func bindTranslation() {
        viewModel.triggerTranslatioinContentRelay
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (isSuccess, content, language) in
                self?.showSelectedTranslationCard(isSuccess: isSuccess, content: content, language: language)
            })
            .disposed(by: rx.disposeBag)
    }
}

extension ChatMessageViewController: TranslatedViewDelegate {
    func lanuageItemDidTap() {
        translateSelectedText()
    }
}

extension ChatMessageViewController: VCMenuViewControllerDelegate {
    func menuViewDidDismiss(isSelected: Bool) {
        menu = nil
        if !isSelected {
            resetSelection()
        }
    }

    func shouldDismissMenuOnTap(in view: UIView, location: CGPoint) -> Bool {
        // menu 弹出时，点击到当前的 cell 内，不会隐藏 menu
        guard let cell = selectedCell as? ChatMessageCell, let bubble = cell.getBubbleView() else { return true }
        let pointInBubble = view.convert(location, to: bubble)
        let pointInTableView = view.convert(location, to: tableView)
        // 如果只有部分 cell 在 tableView 当前屏上，此时点击 tableView 外气泡位置，也会判定点击位置在气泡中，导致无法 dismiss menu
        // 因此这里还要加一个条件，如果点击位置在 tableView 外，也 dismiss menu
        return !tableView.bounds.contains(pointInTableView) || !bubble.bounds.contains(pointInBubble)
    }
}
