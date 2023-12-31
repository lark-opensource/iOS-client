//
//  DocsBaseToolBarItem.swift
//  SpaceKit
//
//  Created by Webster on 2019/1/10.
//
import SKCommon
import SKInfra

protocol DocsToolBarItemDelegate: AnyObject {
    func requestHideToolBar(item: DocsBaseToolBarItem?)
    func requestJumpAnotherTitleView(in item: DocsBaseToolBarItem)
    func requestExitTitleView(in item: DocsBaseToolBarItem)
    func requestTapicFeedback(item: DocsBaseToolBarItem)
    func requestJumpKeyboard(in item: DocsBaseToolBarItem)
    func requestDocsInfo(item: DocsBaseToolBarItem) -> DocsInfo?
    func requestAddRestoreTag(item: DocsBaseToolBarItem?, tag: String?)
}

class DocsBaseToolBarItem {
    /// delegate
    weak var delegate: DocsToolBarItemDelegate?
    /// js engine to exe the js
    weak var jsEngine: BrowserJSEngine?
    /// the second level view's size when init
    var attachViewInitSize: CGSize?
    /// all the infos about this item
    private var itemInfo: ToolBarItemInfo
    /// the callback block when the item is clicked, only vaild in button type item
    var buttonCallBack: ((Bool) -> Void)?
    /// determine if the panel will back to keyboard after tap again
    var tapAgainToBack: Bool {
        return false
    }
    /// 二级面板
    var subPanel: SKSubToolBarPanel?
    /// The toolbar restore tag of this item, override it if you need to restore after
    /// the effect of causing the keyboard to retract has been removed.
    class var restoreTag: String { return "" }

    class var restoreScript: DocsJSCallBack { return DocsJSCallBack("") }
    let newCacheAPI: NewCacheAPI

    /// convenience constructor
    ///
    /// - Parameter identifier: the item's identifier
    convenience init(identifier: BarButtonIdentifier) {
        let dstInfo = ToolBarItemInfo(identifier: identifier.rawValue)
        self.init(info: dstInfo)
    }

    /// init fun
    ///
    /// - Parameter info: the base bar info
    init(info: ToolBarItemInfo, resolver: DocsResolver = DocsContainer.shared) {
        self.itemInfo = info
        newCacheAPI = resolver.resolve(NewCacheAPI.self)!
    }

    /// base item info
    ///
    /// - Returns: info
    func info() -> ToolBarItemInfo {
        return itemInfo
    }

    /// button bar item type
    /// current we has button and panle, default is return button without second level view
    /// - Returns: item type button or panle
    func type() -> DocsToolBar.ItemType {
        return .button
    }

    /// fetch the panel in second level view
    ///
    /// - Parameter toolbar: the toolbar which owns this item
    /// - Returns: current item's panel view, only has value when current item typs is panel
    func panelView() -> UIView? {
      return nil
    }

    /// the call back when item is pressed
    ///
    /// - Returns: callback exe block... only happend in button type
    final func callback() -> ((Bool) -> Void)? {
        return buttonCallBack
    }

    /// transfer the panel view to other bar item
    ///
    /// - Parameter item: other item instance
    func transferPanelView(to item: DocsBaseToolBarItem) {

    }

    /// Will invoked while this panel will disappear
    func panelWillDisappear() {

    }
}
