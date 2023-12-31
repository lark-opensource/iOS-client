//
//  KeyboardPanelCanvasSubModule.swift
//  LarkBaseKeyboard
//
//  Created by liluobin on 2023/4/10.
//

import LarkFoundation
import LarkKeyboardView
import LarkOpenKeyboard
import LarkOpenIM
import LarkCanvas
import LarkUIKit
import EENavigator

public struct KeyboardPanelCanvasConfig {
    let itemIconColor: UIColor
    let canvasId: String
    let bizTrancker: String

    public init(itemIconColor: UIColor, canvasId: String, bizTrancker: String) {
        self.itemIconColor = itemIconColor
        self.canvasId = canvasId
        self.bizTrancker = bizTrancker
    }
}


open class KeyboardPanelCanvasSubModule <C:KeyboardContext, M:KeyboardMetaModel>: BaseKeyboardPanelDefaultSubModule<C, M>, LKCanvasViewControllerDelegate {

    open override var panelItemKey: KeyboardItemKey {
        return .canvas
    }

    open func getKeyboardPanelCanvasConfig() -> KeyboardPanelCanvasConfig? {
        return nil
    }

    open override func didCreatePanelItem() -> InputKeyboardItem? {
        guard #available(iOS 13, *), Display.pad, !Utils.isiOSAppOnMacSystem else {
            return nil
        }
        return buildCanvas()
    }

    @available(iOS 13.0, *)
    func buildCanvas() -> InputKeyboardItem? {
        guard let config = self.getKeyboardPanelCanvasConfig() else {
            return nil
        }

        let badgeTypeBlock: () -> KeyboardIconBadgeType = {
            // 如果有画板缓存，返回红点类型 badge，否则返回无 badge
            return LKCanvasConfig.cacheProvider.checkCache(identifier: config.canvasId) ? .redPoint : .none
        }
        return LarkKeyboard.buildCanvas(
            badgeTypeBlock: badgeTypeBlock,
            iconColor: config.itemIconColor,
            selectedBlock: { [weak self] () -> Bool in
                self?.inputTextViewInputCanvas()
                self?.didTapItem()
                return false
            }
        )
    }

    open func didTapItem() {}
    
    @available(iOS 13.0, *)
    open func inputTextViewInputCanvas() {
        guard let config = self.getKeyboardPanelCanvasConfig() else { return }
        let from = context.displayVC
        Navigator.shared.present(
            LKCanvasViewController(identifier: config.canvasId,
                                   from: config.bizTrancker,
                                   delegate: self),
            wrap: LkNavigationController.self,
            from: from,
            prepare: { $0.modalPresentationStyle = .fullScreen }
        )
    }

    // MARK: - LKCanvas Delegate
    @available(iOS 13.0, *)
    open func canvasWillFinish(in controller: LKCanvasViewController,
                                 drawingImage: UIImage, canvasData: Data,
                                 canvasShouldDismissCallback: @escaping (Bool) -> Void) {
        /// 业务放自行处理
    }

    @available(iOS 13.0, *)
    open func canvasDidClose() {
    }

    @available(iOS 13.0, *)
    open func canvasDidEnter(lifeCycle: LKCanvasViewController.LifeCycle) {
        switch lifeCycle {
        case .viewDidDisappear:
            // update badge
            context.keyboardPanel.reloadPanelBtn(key: KeyboardItemKey.canvas.rawValue)
        default:
            break
        }
    }
}
