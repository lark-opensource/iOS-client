//
//  SearchDefaultChatView.swift
//  LarkSearch
//
//  Created by sunyihe on 2022/9/23.
//

import UIKit
import Homeric
import RxSwift
import LarkModel
import LarkUIKit
import Foundation
import LarkSearchCore
import LarkSDKInterface
import LarkKeyCommandKit
import LarkMessengerInterface
import LarkContainer

open class SearchDefaultChatView: UIView, UITableViewDelegate, UITableViewDataSource, TableViewKeyboardHandlerDelegate {

    let tableView: UITableView
    private var originResults: [ForwardItem] = []
    private weak var selectionDataSource: SelectionDataSource?
    private let disposeBag = DisposeBag()
    var keyboardHandler: TableViewKeyboardHandler?

    var loaded = false // lazy load when appear on window
    let bag = DisposeBag()
    var resolver: UserResolver
    public init(resolver: UserResolver, feedService: FeedSyncDispatchService, pickTypes: ChatFilterMode, selection: SelectionDataSource) {
        self.resolver = resolver
        var chatTypes: [Chat.ChatMode]?
        switch pickTypes {
        case .normal:
            chatTypes = [.default]
        case .thread:
            chatTypes = [.thread, .threadV2]
        @unknown default:
            break
        }

        self.tableView = UITableView(frame: CGRect(origin: .zero, size: .zero), style: .plain)
        self.selectionDataSource = selection
        super.init(frame: .zero)

        setupTableview()
        feedService.topInboxChats(by: 20, chatType: chatTypes, needChatBox: true)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] chats in
                self?.originResults = chats.map { .init(chat: $0) }
                self?.tableView.reloadData()
            }).disposed(by: disposeBag)
        bindViewModel()

        // tableview keyboard
        keyboardHandler = TableViewKeyboardHandler(options: [.allowCellFocused(focused: Display.pad)])
        keyboardHandler?.delegate = self
    }

    func setupTableview() {
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.backgroundColor = UIColor.ud.bgBody
        tableView.keyboardDismissMode = .onDrag
        tableView.rowHeight = 68
        tableView.separatorColor = UIColor.ud.bgBody
        tableView.separatorStyle = .none
        tableView.contentInsetAdjustmentBehavior = .never

        tableView.register(ChatPickerTableCell.self, forCellReuseIdentifier: "ChatPickerTableCell")
        tableView.delegate = self
        tableView.dataSource = self

        self.addSubview(tableView)
    }

    private func bindViewModel() {
        self.selectionDataSource?.selectedChangeObservable.bind(onNext: { [weak self] _ in
            self?.tableView.reloadData()
        }).disposed(by: bag)
        self.selectionDataSource?.isMultipleChangeObservable.bind(onNext: { [weak self] _ in
            self?.tableView.reloadData()
        }).disposed(by: bag)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func keyBindings() -> [KeyBindingWraper] {
        return super.keyBindings() + (keyboardHandler?.baseSelectiveKeyBindings ?? [])
    }

    // TableViewKeyboardHandlerDelegate
    public func tableViewKeyboardHandler(handlerToGetTable: TableViewKeyboardHandler) -> UITableView {
        return tableView
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return originResults.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = self.originResults[indexPath.row]
        let lastRow = self.originResults.count == indexPath.row + 1
        if let selectionDataSource = selectionDataSource,
           let cell = model.reuseChatCell(in: tableView, resolver: self.resolver, selectionDataSource: selectionDataSource, isLastRow: lastRow) {
               return cell
        } else {
            assertionFailure()
            return UITableViewCell()
        }
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        tableView.deselectRow(at: indexPath, animated: true)
        let model = self.originResults[indexPath.row]
        selectionDataSource?.toggle(option: model,
                                   from: PickerSelectedFromInfo(sender: self, container: tableView, indexPath: indexPath, tag: ""),
                                   at: tableView.absolutePosition(at: indexPath),
                                   event: Homeric.PUBLIC_PICKER_SELECT_CLICK,
                                   target: Homeric.PUBLIC_PICKER_SELECT_VIEW,
                                   scene: "SearchDefaultChatView")
    }
}

public struct PickerSelectedFromInfo {
    /// 调用者, 一般是对应代码的self
    public var sender: Any?
    /// 容器View, 通常是tableView
    public var container: UIView?
    /// 操作item所在的位置
    public var indexPath: IndexPath?
    /// 额外的tag标识
    public var tag: String = ""
    /// 是否是搜索结果
    public var isSearch: Bool { tag == "search" }
}
