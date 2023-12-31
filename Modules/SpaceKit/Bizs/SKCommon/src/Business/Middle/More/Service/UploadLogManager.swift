//
//  UploadLogManager.swift
//  SpaceKit
//
//  Created by xurunkang on 2019/3/11.
//  

import SKFoundation
import SKUIKit
import SKResource
import UniverseDesignToast
import EENavigator
/*
// 仅仅解决确认页面的持有问题，其他人不要调用
public class UploadLogManager {

    private init() { }

    public class func uploadLog(_ deviceID: String) {
        var request: DocsRequest<[String: Any]>?
        request = DocsRequest(path: OpenAPI.APIPath.customerServiceID, params: ["device_id": deviceID, "upload_log": true, "join_oncall_chat": false])
            .set(transform: { (json) -> ([String: Any]?, error: Error?) in
                guard let dataDic = json?["data"].dictionaryObject else {
                    showError()
                    DocsLogger.info("上传失败")
                    return (nil, NSError(domain: "Error: JSON 解析出错", code: 400))
                }
                return (dataDic, nil)
            }).start(result: { (_, error) in
                if error == nil {
                    guard let mainSceneWindow = Navigator.shared.mainSceneWindow else {
                        return
                    }
                    UDToast.showSuccess(with: BundleI18n.SKResource.Doc_Facade_UploadCompleted,
                                           on: mainSceneWindow)
                    DocsLogger.info("上传成功")
                } else {
                    showError()
                    DocsLogger.info("上传失败")
                }
            })
        _ = request?.makeSelfReferenced()
    }
}

extension UploadLogManager {
    private class func showError() {
        guard let mainSceneWindow = Navigator.shared.mainSceneWindow else {
            return
        }
        UDToast.showFailure(with: BundleI18n.SKResource.Doc_More_ContactServiceFailed, on: mainSceneWindow)
    }
}
*/
