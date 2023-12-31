//
//  BTFilterCoordinator.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/6/29.
//  

import SKUIKit
import SKResource
import EENavigator
import CoreGraphics
import UniverseDesignColor


let BTFilterDatePopoverSize = CGSize(width: 375, height: BTFilterValueDateController.contentHeight)

final class BTFilterPopoverArgs {
    var sourceView: UIView
    var sourceRect: CGRect
    var contentSize: CGSize
    
    internal init(sourceView: UIView, sourceRect: CGRect, contentSize: CGSize = BTFilterDatePopoverSize) {
        self.sourceView = sourceView
        self.sourceRect = sourceRect
        self.contentSize = contentSize
    }
}

enum BTFilterFieldAction: String {
    case field
    case rule
    case dateValueRule
}

final class BTFilterCoordinator {
    
    private weak var hostVC: UIViewController?
    private let baseContext: BaseContext
    
    var isRegularSize: Bool {
        guard let hostVC = hostVC else {
            return false
        }
        return hostVC.isMyWindowRegularSize() && SKDisplay.pad
    }
    
    var topMostVC: UIViewController? {
        guard let hostVC = hostVC else {
            return nil
        }
        return UIViewController.docs.topMost(of: hostVC)
    }
    
    init(hostVC: UIViewController, baseContext: BaseContext) {
        self.hostVC = hostVC
        self.baseContext = baseContext
    }
    
    func createCommonListController(title: String,
                                    action: BTFilterFieldAction,
                                    datas: [BTFieldCommonData],
                                    selectedIndex: Int = 0) -> BTFieldCommonDataListController {
        let selectedIndexPath = IndexPath(item: selectedIndex, section: 0)
        let listVC = BTFieldCommonDataListController(data: datas,
                                                     title: title,
                                                     action: action.rawValue,
                                                     shouldShowDragBar: false,
                                                     shouldShowDoneButton: true,
                                                     lastSelectedIndexPath: selectedIndexPath,
                                                     initViewHeightBlock: { [weak self] in
            return (self?.hostVC?.view.window?.bounds.height ?? SKDisplay.activeWindowBounds.height) * 0.8
        })
        listVC.supportedInterfaceOrientationsSetByOutside = .portrait
        return listVC
    }
   
    
    /// 获取值类型控制器
    func createValueController(valueDateType: BTFilterValueDataType,
                               finishHandler:  @escaping BTFilterValueBaseController.FinishWithValueHandler,
                               cancelHandler: @escaping BTFilterValueBaseController.CancelHandler) -> BTDraggableViewController {
        
        let defaultTitle = BundleI18n.SKResource.Bitable_Relation_ConditionValue_Mobile
        
        let valuVc: BTFilterValueBaseController
        switch valueDateType {
        case let .text(value):
            valuVc = BTFilterValueInputController(title: defaultTitle, type: .text(value), baseContext: self.baseContext)
        case let .number(value):
            valuVc = BTFilterValueInputController(title: defaultTitle, type: .number(value), baseContext: self.baseContext)
        case let .phone(value):
            valuVc = BTFilterValueInputController(title: defaultTitle, type: .phone(value), baseContext: self.baseContext)
        case let .options(alls, isAllowMultiple):
            valuVc = BTFilterValueOptionsController(title: defaultTitle,
                                                    options: alls,
                                                    isAllowMultipleSelect: isAllowMultiple)
        case let .links(viewModel):
            valuVc = BTFilterValueLinksController(title: defaultTitle,
                                                  btViewModel: viewModel)
            
        case let .date(date, format):
            valuVc = BTFilterValueDateController(title: BundleI18n.SKResource.Bitable_Filter_SelectDateTitle_Mobile, date: date, formatConfig: format)
        case let .chatter(viewModel: viewModel):
            valuVc = BTFilterValueChattersController(title: defaultTitle,
                                                  viewModel: viewModel)
        }
        valuVc.didFinishWithValues = finishHandler
        valuVc.didCancel = cancelHandler
        return valuVc
    }
    
    func openController(_ controller: BTDraggableViewController,
                        isFirstStep: Bool,
                        popoverArgs: BTFilterPopoverArgs? = nil) {
        
        guard let topMostVC = topMostVC else {
            return
        }
        if let popoverArgs = popoverArgs {
            BTNavigator.setupPopover(controller,
                                     sourceView: popoverArgs.sourceView,
                                     sourceRect: popoverArgs.sourceRect,
                                     contentSize: popoverArgs.contentSize)
            return Navigator.shared.present(controller, from: topMostVC)
        }
        if isFirstStep {
            openEmbedInNav(controller: controller)
        } else {
            Navigator.shared.push(controller, from: topMostVC)
        }
    }
    
    /// 打开特定控制器，并且嵌套在导航栏控制器中
    private func openEmbedInNav(controller: BTDraggableViewController) {
        if let topMost = self.topMostVC {
            BTNavigator.presentDraggableVCEmbedInNav(controller, from: topMost)
        }
    }
}
