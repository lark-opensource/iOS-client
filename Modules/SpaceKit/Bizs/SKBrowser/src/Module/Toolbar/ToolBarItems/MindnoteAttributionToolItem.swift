//
//  MindnoteAttributionToolItem.swift
//  SpaceKit
//
//  Created by longweiwei on 2019/2/14.
//
import SKCommon
import SKUIKit
import EENavigator
import SKInfra

class MindnoteAttributionToolItem: DocsBaseToolBarItem {

    /// js callback method name
    var jsMethodName: String?
    /// view that manager attribution buttons
    var txtAttributionView: MindNoteAttributionView?
    /// ui status for all the buttons
    private var status: [BarButtonIdentifier: ToolBarItemInfo] = [BarButtonIdentifier: ToolBarItemInfo]()

    override var tapAgainToBack: Bool {
        return true
    }

    /// init
    ///
    /// - Parameter info: tool bar item info
    override init(info: ToolBarItemInfo, resolver: DocsResolver = DocsContainer.shared) {
        super.init(info: info, resolver: resolver)
        if let children = self.info().children {
            for child in children {
                if let identifier = BarButtonIdentifier(rawValue: child.identifier) {
                    status.updateValue(child, forKey: identifier)
                }
            }
        }
    }

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
        if txtAttributionView == nil {
            let frame = CGRect(x: 0, y: 0, width: SKDisplay.activeWindowBounds.width, height: 200)
            txtAttributionView = MindNoteAttributionView(status: status, frame: frame)
        }
        txtAttributionView?.delegate = self
//        txtAttributionView?.updateStatus(status: status)
        return txtAttributionView
    }

    /// transfer panel view to new item
    ///
    /// - Parameter item: new item
    override func transferPanelView(to item: DocsBaseToolBarItem) {
        if let toItem = item as? MindnoteAttributionToolItem {
            toItem.txtAttributionView = self.txtAttributionView
            toItem.txtAttributionView?.delegate = toItem
//            toItem.txtAttributionView?.updateStatus(status: toItem.status)
        }
    }
}

extension MindnoteAttributionToolItem: MindNoteAttributionViewDelegate {
    func mindnoteAttributionView(view: MindNoteAttributionView, button: BarButtonIdentifier, update value: String?) {
        let identifier = button.rawValue
        if let jsName = jsMethodName {
            if let sValue = value {
                let params = ["id": identifier, "value": sValue]
                self.jsEngine?.callFunction(DocsJSCallBack(jsName), params: params, completion: nil)
            } else {
                let params = ["id": identifier]
                self.jsEngine?.callFunction(DocsJSCallBack(jsName), params: params, completion: nil)
            }
        }
        if DocsAttributionToolItem.goBackKeyboardIdentifier.contains(identifier) {
            delegate?.requestJumpKeyboard(in: self)
        }
    }
}
