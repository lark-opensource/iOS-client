//
//  NavigationCloseDetailOnSearchPadSubModule.swift
//  LarkMessageCore
//
//  Created by chenyanjie on 2023/11/24.
//

import Foundation
import LarkOpenChat
import LarkUIKit
import LarkMessengerInterface

class NavigationCloseDetailOnSearchPadSubModule: BaseNavigationBarItemSubModule {
    private var metaModel: ChatNavigationBarMetaModel?
    private lazy var closeDetailButton: UIButton = {
        return searchOuterService?.closeDetailButton(chatID: self.metaModel?.chat.id ?? "") ?? UIButton()
    }()

    private lazy var searchOuterService: SearchOuterService? = {
        let service = try? self.context.userResolver.resolve(assert: SearchOuterService.self)
        return service
    }()

    var _items: [ChatNavigationExtendItem] = []

    override func canHandle(model: ChatNavigationBarMetaModel) -> Bool {
        return canHandleCloseDetailButtonItem()
    }

    override func createItems(metaModel: ChatNavigationBarMetaModel) {
        self.metaModel = metaModel
    }

    override var items: [ChatNavigationExtendItem] {
        return _items
    }

    override func viewWillAppear() {
        buildItems()
    }

    private func buildItems() {
        self._items = []
        if needShowCloseDetailButtonItem() {
            self._items.append(ChatNavigationExtendItem(type: .closeDetail, view: closeDetailButton))
        }
        self.context.refreshLeftItems()
    }

    private func canHandleCloseDetailButtonItem() -> Bool {
        guard let searchOuterService = searchOuterService, searchOuterService.enableSearchiPadSpliteMode() else { return false }
        let service = try? self.context.userResolver.resolve(assert: ChatCloseDetailLeftItemService.self)
        if service?.source == .searchResultMessage { return true }
        return false
    }

    private func needShowCloseDetailButtonItem() -> Bool {
        guard canHandleCloseDetailButtonItem() else { return false }
        if let split = self.context.chatVC().larkSplitViewController {
            if !split.isCollapsed {
                return true
            }
        }
        return false
    }

}
