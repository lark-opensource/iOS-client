//
//  BitableBrowserViewController+Container.swift
//  SKBitable
//
//  Created by yinyuan on 2023/9/6.
//

import Foundation
import SKCommon

extension BitableBrowserViewController: BTContainerDelegate {
    var browserViewController: BitableBrowserViewController? {
        return self
    }
    
    func callFunction(_ function: DocsJSCallBack, params: [String: Any]?, completion: ((_ info: Any?, _ error: Error?) -> Void)?) {
        self.editor.jsEngine.callFunction(function, params: params, completion: completion)
    }
}
