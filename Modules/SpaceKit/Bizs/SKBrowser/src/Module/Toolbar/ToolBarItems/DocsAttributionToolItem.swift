//
//  DocsAttributionToolItem.swift
//  SpaceKit
//
//  Created by Webster on 2019/1/9.
//
import SKFoundation
import SKUIKit
import EENavigator

/// the docs toolbar item which change the text's style
/// like bold, italic, code block '''  etc..
class DocsAttributionToolItem: PanelTypeToolBarItem {

    /// js callback method name
    var jsMethodName: String?
    /// ui status for all the buttons
    private var status: [BarButtonIdentifier: ToolBarItemInfo] = [BarButtonIdentifier: ToolBarItemInfo]()
    /// the button identifier should making toolbar display keyboard
    static let goBackKeyboardIdentifier: Set<String> = [BarButtonIdentifier.h1.rawValue,
                                                        BarButtonIdentifier.h2.rawValue,
                                                        BarButtonIdentifier.h3.rawValue,
                                                        BarButtonIdentifier.checkbox.rawValue,
                                                        BarButtonIdentifier.unorderedlist.rawValue,
                                                        BarButtonIdentifier.orderedlist.rawValue]
    // MARK: UI Widget
    var attributeView: DocsAttributionView?
    var titleView: ColorPickerNavigationView?

    /// bar item type
    ///
    /// - Returns: panel
    override func type() -> DocsToolBar.ItemType {
        return .panel
    }

    /// second level panel view belong to this item
    ///
    /// - Returns: text attribution view
    override func panelView() -> UIView? {
        if attributeView == nil {
            let frame = CGRect(x: 0, y: 0, width: SKDisplay.activeWindowBounds.width, height: 200)
            attributeView = DocsAttributionView(status: childStatus, frame: frame)
        }
        //attributeView?.delegate = self
        attributeView?.updateStatus(status: childStatus)
        return attributeView
    }

    /// transfer panel view to new item
    ///
    /// - Parameter item: new item
    override func transferPanelView(to item: DocsBaseToolBarItem) {
        if let toItem = item as? DocsAttributionToolItem {
            toItem.attributeView = self.attributeView
            //toItem.attributeView?.delegate = toItem
            toItem.attributeView?.updateStatus(status: toItem.childStatus)
            toItem.titleView = self.titleView
            toItem.titleView?.delegate = toItem
        }
    }

    override func panelWillDisappear() {
        super.panelWillDisappear()
        attributeView?.showColorPicker(toShow: false)
    }
}

extension DocsAttributionToolItem: ColorPickerNavigationViewDelegate {
    func colorPickerNavigationViewRequestExit(view: ColorPickerNavigationView) {
        attributeView?.showColorPicker(toShow: false)
        delegate?.requestExitTitleView(in: self)
        delegate?.requestTapicFeedback(item: self)
    }
}
