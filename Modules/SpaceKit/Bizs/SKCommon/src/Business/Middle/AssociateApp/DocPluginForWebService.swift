//
//  DocPluginForWebService.swift
//  SKCommon
//
//  Created by huangzhikai on 2023/10/12.
//  一事一档相关网络请求

import Foundation
import SKFoundation
import SKInfra
import SwiftyJSON
import SpaceInterface
import EENavigator
import SKResource
import UniverseDesignDialog
import UniverseDesignToast
import LarkDocsIcon

public final class DocPluginForWebService {
    // 查看是否有关联文档，按钮是否可见。 https://bytedance.feishu.cn/wiki/UYsrwlDNniRd1Hk1ENkc5cNlnFf?create_from=create_doc_to_wiki#BR7Rd3UfNoPErJxgTJWcnhXYnge
    public static func checkReferenceExist(appUrl: String, completion: @escaping ((visible: Bool, referenceExist: Bool, urlMetaId: Int?), Error?) -> Void) {
        var params = [String: Any]()
        params["app_url"] = appUrl // 应用链接
        params["type"] = 2 // 默认不传返回多个插件结果， 1 返回chat 结果 2 返回ccm 结果
        DocsRequest<JSON>(path: OpenAPI.APIPath.associateAppCheckReferenceExist, params: params)
            .set(method: .GET)
            .makeSelfReferenced()
            .start(result: { json, error in
                guard error == nil else {
                    completion((visible: false, referenceExist: false, urlMetaId: nil), error)
                    return
                }
                
                guard let data = json?["data"].dictionaryObject,
                      let pluginsInfo = data["plugins_info"] as? [String: Any],
                      let ccmPlugin = pluginsInfo["ccm_plugin"] as? [String: Any] else {
                    completion((visible: false, referenceExist: false, urlMetaId: nil), error)
                    return
                }
                let urlMetaId = data["url_meta_id"] as? Int
                let visible = ccmPlugin["visible"] as? Bool ?? false
                let referenceExist = ccmPlugin["reference_exist"] as? Bool ?? false
                
                completion((visible: visible, referenceExist: referenceExist, urlMetaId: urlMetaId), nil)
            })
    }
    
    //查看关联的文档列表
    public static func appReference(appUrl: String, completion: @escaping (AssociateAppModel?, Error?) -> Void) {
        var params = [String: Any]()
        params["app_url"] = appUrl // 应用链接
        DocsRequest<JSON>(path: OpenAPI.APIPath.associateAppAppReference, params: params)
            .set(method: .GET)
            .makeSelfReferenced()
            .start(result: { json, error in
                guard error == nil else {
                    completion(nil, error)
                    return
                }
                let jsonData = json?["data"]
                if let data = try? jsonData?.rawData() {
                    let model = try? JSONDecoder().decode(AssociateAppModel.self, from: data)
                    completion(model, nil)
                    return
                }
                completion(nil, nil)
            })
    }
    
    /// 关联已有文档
    public static func addReference(appUrl: String, docList: [(docToken: String, docType: DocsType, url: String)], completion: @escaping (Bool, Error?) -> Void) {
        
        guard docList.count > 0 else {
            completion(false, nil)
            return
        }
        
        var params = [String: Any]()
        params["app_url"] = appUrl // 应用链接
        var obj_list = [[String: Any]]()
        for doc in docList {
            obj_list.append(["obj_token": doc.docToken, "obj_type": doc.docType.rawValue])
        }
        params["obj_list"] = obj_list
        DocsRequest<JSON>(path: OpenAPI.APIPath.associateAppReferenceCreate, params: params)
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
            .makeSelfReferenced()
            .start(result: { json, error in
                guard error == nil else {
                    DocsLogger.error("addReference error: \(String(describing: error))", component: LogComponents.associateApp)
                    completion(false, error)
                    return
                }
                guard let data = json?.dictionaryObject,
                      let code = data["code"] as? Int,
                      code == 0 else {
                    DocsLogger.error("addReference fail: \(String(describing: json))", component: LogComponents.associateApp)
                    completion(false, error)
                    return
                }
                completion(true, error)
                
            })
    }
    
    //创建新的文档并关联
    public static func createReference(appUrl: String, completion: @escaping (String?, Error?) -> Void) {
        
        var params = [String: Any]()
        params["type"] = DocsType.docX.rawValue
        params["source"] = 0
        
        let extInfo = ["app_url": appUrl]
        
        guard let infoJson = extInfo.toJSONString() else {
            DocsLogger.error("createReference extInfo to json error, extInfo: \(extInfo)", component: LogComponents.associateApp)
            return
        }
        params["ext_info"] = infoJson
        
        DocsRequest<JSON>(path: OpenAPI.APIPath.associateAppNewCreate, params: params)
            .set(method: .POST)
            .makeSelfReferenced()
            .start(result: { json, error in
                guard error == nil else {
                    DocsLogger.error("createReference error: \(String(describing: error))", component: LogComponents.associateApp)
                    completion(nil, error)
                    return
                }
                guard let data = json?.dictionaryObject,
                      let code = data["code"] as? Int,
                      code == 0 else {
                    DocsLogger.error("createReference fail: \(String(describing: json))", component: LogComponents.associateApp)
                    completion(nil, error)
                    return
                }
                guard let nodes = json?["data"]["entities"]["nodes"].dictionaryObject,
                      let node = nodes.values.first as? [String: Any],
                      let url = node["url"] as? String else {
                    DocsLogger.error("createReference url is nil: \(String(describing: data))", component: LogComponents.associateApp)
                    completion(nil, error)
                    return
                }
                completion(url, nil)
                
            })
    }
    
    //解除关联文档
    public static func deleteReference(appUrl: String, docList: [(docToken: String, docType: DocsType)], completion: @escaping (Bool, Error?) -> Void) {
        
        guard docList.count > 0 else {
            completion(false, nil)
            return
        }
        
        var params = [String: Any]()
        params["app_url"] = appUrl // 应用链接
        var obj_list = [[String: Any]]()
        for doc in docList {
            obj_list.append(["obj_token": doc.docToken, "obj_type": doc.docType.rawValue])
        }
        params["obj_list"] = obj_list
        
        DocsRequest<JSON>(path: OpenAPI.APIPath.associateAppReferenceDelete, params: params)
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
            .makeSelfReferenced()
            .start(result: { json, error in
                guard error == nil else {
                    completion(false, error)
                    return
                }
                guard let data = json?.dictionaryObject,
                      let code = data["code"] as? Int,
                      code == 0 else {
                    completion(false, error)
                    return
                }
                //解除关联文档通过，发出通知
                NotificationCenter.default.post(name: Notification.Name.Docs.deleteAssociateApp, object: appUrl, userInfo: nil)
                completion(true, error)
                
            })
    }
    
}

extension DocPluginForWebService {
    public static func showTipAndDeleteReference(appUrl: String?, urlMetaId: Int?, hostVC: UIViewController, docList: [(docToken: String, docType: DocsType)], completion: @escaping (Bool, Error?) -> Void) {
        
        guard let appUrl = appUrl, !appUrl.isEmpty else {
            DocsLogger.info("showTipAndDeleteReference, appUrl is nil or empty", component: LogComponents.associateApp)
            UDToast.showFailure(with: BundleI18n.SKResource.LarkCCM_Docs_AppLinkDoc_DocUnlinked_Toast, on: hostVC.view)
            return
        }
        
        AssociateAppTracker.reportPluginClickTrackerEvent(clickType: .clickUnbindDocsEntrance, 
                                                          showType: .viewDocs,
                                                          docsToken: docList.first?.docToken,
                                                          docsType: docList.first?.docType,
                                                          webUrl: URL(string: appUrl), 
                                                          urlId: urlMetaId)
        // 弹窗
        let title = BundleI18n.SKResource.LarkCCM_Docs_AppLinkDoc_Unlink_Title
        let content = BundleI18n.SKResource.LarkCCM_Docs_AppLinkDoc_Unlink_Desc
        
        let dialog = UDDialog(config: UDDialogUIConfig(style: .vertical))
        dialog.setTitle(text: title)
        dialog.setContent(text: content)
        dialog.addDestructiveButton(text: BundleI18n.SKResource.LarkCCM_Docs_AppLinkDoc_Unlink_Popover_Button,
                                    dismissCompletion: {
            
            DocPluginForWebService.deleteReference(appUrl: appUrl, docList: docList) { isSuccess, error in
                if isSuccess {
                    UDToast.showSuccess(with: BundleI18n.SKResource.LarkCCM_Docs_AppLinkDoc_DocUnlinked_Toast, on: hostVC.view)
                    AssociateAppTracker.reportPluginClickTrackerEvent(clickType: .successUnbindDocs,
                                                                      showType: .viewDocs,
                                                                      docsToken: docList.first?.docToken,
                                                                      docsType: docList.first?.docType,
                                                                      webUrl: URL(string: appUrl),
                                                                      urlId: urlMetaId)
                    
                } else {
                    UDToast.showFailure(with: BundleI18n.SKResource.LarkCCM_Docs_AppLinkDoc_UnlinkFail_Toast, on: hostVC.view)
                }
                completion(isSuccess, error)
            }
            
        })
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel)
        Navigator.shared.present(dialog, from: hostVC, animated: true)
    }
}
