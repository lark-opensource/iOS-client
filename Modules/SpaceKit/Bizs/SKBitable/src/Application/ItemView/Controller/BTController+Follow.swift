//
//  BTController+VC.swift
//  SKBitable
//
//  Created by zoujie on 2021/8/30.
//  


import SKFoundation
import SKBrowser
import SKCommon
import SpaceInterface

extension BTController: FollowableViewController {

    // bitable 卡片时作为附件，所以询问的是 bitable 文档的。
    var isEditingStatus: Bool {
        return self.keyboard.isShow
    }

    var followTitle: String {
        return self.editorDocsInfo.title ?? ""
    }

    var followVC: UIViewController {
        return self
    }

    var followScrollView: UIScrollView? {
        return cardsView
    }

    func onSetup(followAPIDelegate: SpaceFollowAPIDelegate) {
        spaceFollowAPIDelegate = followAPIDelegate
    }

    func refreshFollow() {}

    func currentStatusChange(topFieldId: String?) {
        let subParams: [String: String] = [
            "topFieldId": topFieldId ?? currentCard?.topVisibleFieldID ?? "",
            "tableId": viewModel.actionParams.data.tableId,
            "recordId": currentCard?.recordID ?? ""
        ]
        let params: [String: Any] = [
            "module": "bitableCard",
            "data": subParams,
            "tableId": viewModel.actionParams.data.tableId,
        ]
        DocsLogger.debug("currentStatusChange", extraInfo: params, component: LogComponents.bitable)
        spaceFollowAPIDelegate?.follow(self, onOperate: .nativeStatus(funcName: DocsJSCallBack.bitableVCFollowState.rawValue, params: params))
    }

    func onOperate(_ operation: SpaceFollowOperation) {
        switch operation {
        case .onDocumentVCDidMove:
            //vcFollow情况下，切换到小窗模式或重新共享新文档，附件和卡片都会移除，需要通知前端
            viewModel.markDismissing()
            if self.navigationController?.currentWindow() == nil {
                //有卡片显示的情况下，退出到小窗，再从小窗进入，卡片已不在当前视图内，只需要移除navigationController内的所有VC即可
                self.navigationController?.viewControllers.removeAll()
            } else {
                //有卡片显示的情况下，重新共享其它文档，卡片还在视图内，需要dismiss掉
                //否则navigationController会存在视图的最上层，导致文档页面出现冻屏的现象，无法交互
                self.dismiss(animated: false)
            }
            afterRealDismissal()
        default:
            break
        }
    }
    
    var canSetAttachFile: Bool {
        return false
    }
    
}
