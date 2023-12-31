//
//  DocsEditorDataSource.swift
//  SKBrowser
//
//  Created by lijuyou on 2021/7/13.
//  


import SKFoundation
import SKCommon
import SKEditor

public class DocsEditorDataSource: EditorDataSource {
    public weak var delegate: EditorDataSourceDelegate?

    public init() {
        RNManager.manager.registerRnEvent(eventNames: [.larkUnifiedMessage], handler: self)
    }

    public func sendRequest(_ msg: SKDataMessage) {
        DocsLogger.info("[editor] sendRequest \(msg.handlerName)")
        RNManager.manager.sendLarkUnifiedMessageToRN(apiName: msg.handlerName, data: msg.data ?? [:], callbackID: msg.callbackId)
        
        //TODO: TEST BEGIN
        if msg.handlerName == "openDoc" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if let rsp = mock_documentData() {
                    self.delegate?.onResponse(rsp)
                }
            }
        }
        //TEST END
    }
}

extension DocsEditorDataSource: RNMessageDelegate {
    public func didReceivedRNData(data: [String: Any], eventName: RNManager.RNEventName) {
        guard let msg = SKDataMessage.deserialize(from: data),
              !msg.handlerName.isEmpty else {
            assertionFailure()
            DocsLogger.error("[editor] parse rn data error")
            return
        }
        self.delegate?.onResponse(msg)
    }
}
