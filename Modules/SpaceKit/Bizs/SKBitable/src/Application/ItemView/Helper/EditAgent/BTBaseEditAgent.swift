// 
// Created by duanxiaochen.7 on 2020/3/24.
// Affiliated with DocsSDK.
// 
// Description:

import Foundation
import SKCommon
import SKBrowser
import SKFoundation

protocol BTEditAgent: AnyObject {
    var editingPanelRect: CGRect { get }
    func startEditing(_ cell: BTFieldCellProtocol)
    func stopEditing(immediately: Bool, sync: Bool)
}

protocol BTEditCoordinator: AnyObject {
    var viewModel: BTViewModel { get }
    var currentCard: BTRecord? { get }
    var attachedController: UIViewController { get }
    var inputSuperview: UIView { get }
    var inputSuperviewDistanceToWindowBottom: CGFloat { get }
    var keyboardHeight: CGFloat { get }
    /// 编辑上下文中用到的 docsInfo（type + token，有些 url 编辑时要使用其它关联文档的 docsInfo，记录分享、记录新建等）
    /// 原来叫 hostDocsInfo，这里面有特殊处理，改个名字免得和 BTJSService 的弄混了
    var editorDocsInfo: DocsInfo { get }
    var hostChatId: String? { get }
    func invalidateEditAgent()
    func shouldContinueEditing(fieldID: String, inRecordID: String) -> Bool
    func visibleEditCell(fieldID: String) -> BTFieldCellProtocol?
}

protocol BTBaseEditAgentBaseDelegate: AnyObject {
    func didCloseEditPanel(_ agent: BTEditAgent, payloadParams: [String: Any]?)
    func didStopEditing()
    /// 后续点击跳转统一用这个
    func didClickItem(with model: SKBrowser.BTCapsuleModel, fileName: String?)
}

extension BTBaseEditAgentBaseDelegate {
    
    func didClickItem(with model: SKBrowser.BTCapsuleModel, fileName: String?) {
        
    }
}


class BTBaseEditAgent: NSObject, BTEditAgent {

    weak var baseDelegate: BTBaseEditAgentBaseDelegate?

    weak var coordinator: BTEditCoordinator?

    var fieldID: String

    var recordID: String

    init(fieldID: String, recordID: String) {
        self.fieldID = fieldID
        self.recordID = recordID
    }

    var editHandler: BTEditEngine? { coordinator?.viewModel }

    var relatedVisibleField: BTFieldCellProtocol? {
        return coordinator?.visibleEditCell(fieldID: fieldID)
    }

    var editType: BTFieldType {
        return .notSupport
    }

    var inputSuperview: UIView { coordinator?.inputSuperview ?? UIView() }

    func startEditing(_ cell: BTFieldCellProtocol) {
        spaceAssertionFailure("子类务必实现该方法")
    }

    func updateInput(fieldModel: BTFieldModel) {
        // fieldModel 里包含字段最新的内容，子类实现该方法来更新编辑面板的内容
    }

    func stopEditing(immediately: Bool, sync: Bool = false) {
        spaceAssertionFailure("子类务必实现该方法")
    }
    
    var editingPanelRect: CGRect {
        spaceAssertionFailure("子类务必实现该方法")
        return .zero
    }

    func handleEmitEvent(event: BTEmitEvent, router: BTAsyncRequestRouter) {}
}
