//
//  DocsRequestCenter.swift
//  SpaceKit
//
//  Created by Huang JinZhu on 2018/6/30.
//swiftlint:disable type_body_length file_length


import UIKit
import SwiftyJSON
import SKFoundation
import SKUIKit
import SKResource
import EENavigator
import UniverseDesignToast
import UniverseDesignDialog
import HandyJSON
import SpaceInterface
import SKInfra


public final class DocsRequestCenter: NSObject {
    /*
    //通过模版创建ToDo文档
    //https://bytedance.feishu.cn/docs/doccnQdKDHzW1J1vUNX9plnCz1d
    public class func getTodoTemplateId(completion: @escaping (String?, Error?) -> Void) -> DocsRequest<String> {
        var params: [String: Any] = [String: Any]()
        params["platform"] = "todo"
        params["obj_type"] = "2"
        params["version"] = "4"
        return DocsRequest<String>(path: OpenAPI.APIPath.getSystemTemplate, params: params)
            .set(method: .GET)
            .set {(json) -> (String?, error: Error?) in
                let dict = JSON(json ?? "")
                if  DocsNetworkError.isSuccess(dict["code"].int),
                    let categories = dict["data"]["categories"].array, categories.count > 0,
                    let templates = categories[0]["templates"].array, templates.count > 0 {
                    let template = templates[0]
                    let token = template["obj_token"].string
                    return (token, nil)
                } else if var docsErr = DocsNetworkError(dict["code"].int) {
                    docsErr.set(msg: dict["msg"].string)
                    return (nil, docsErr)
                } else {
                    return (nil, DocsNetworkError.invalidData)
                }
            }
            .start(result: { (result, error) in
                completion(result, error)
            })
    }


    public class func createToDo(token: String,
                                 from: UIViewController?,
                                 completion: @escaping (String?, Error?) -> Void) -> DocsRequest<String> {
        var params: [String: Any] = [String: Any]()
        params["token"] = token
        params["type"] = "2"
        return DocsRequest<String>(path: OpenAPI.APIPath.createFilesByTemplate, params: params)
            .set(method: .POST)
            .set {(json) -> (String?, error: Error?) in
                let dict = JSON(json ?? "")
                if  DocsNetworkError.isSuccess(dict["code"].int),
                    let url = dict["data"]["obj_url"].string {
                    return (url, nil)
                } else if var docsErr = DocsNetworkError(dict["code"].int) {
                    docsErr.set(msg: dict["msg"].string)
                    guard let from = from else {
                        return (nil, docsErr)
                    }
                    if docsErr.code == .createLimited {
                        // 租户达到创建的上线，弹出付费提示
                        showQuotaAlert(from: from)
                    } else if docsErr.code == .spaceUserStorageLimited, QuotaAlertPresentor.shared.enableUserQuota {
                        QuotaAlertPresentor.shared.showUserQuotaAlert(mountNodeToken: nil,
                                                                      mountPoint: nil,
                                                                      from: from,
                                                                      bizParams: nil)
                    } else if DocsNetworkError.isDlpError(docsErr) {
                        DlpManager.updateCurrentToken(token: token)
                        let text = DocsNetworkError.dlpErrorMsg(docsErr)
                        UDToast.showFailure(with: text, on: from.view.window ?? from.view)
                        PermissionStatistics.shared.reportDlpSecurityInterceptToastView(action: .OPEN, dlpError: docsErr)
                    }
                    return (nil, docsErr)
                } else {
                    return (nil, DocsNetworkError.invalidData)
                }
            }
            .start(result: { (result, error) in
                completion(result, error)
            })
    }
    */

    /// 单容器需求 - 新建文件夹
    public class func createFolderV2(name: String, parent: String = "", desc: String?, completion: @escaping (String?, Error?) -> Void) -> DocsRequest<String> {
        var params: [String: Any] = [:]
        if let desc = desc {
            params["desc"] = desc
        }
        params["name"] = name
        params["parent_token"] = parent
        params["source"] = 0
        return DocsRequest<String>(path: OpenAPI.APIPath.createFolderV2, params: params)
            .set { (json) -> (String?, error: Error?) in
                let dict = JSON(json ?? "")
                if DocsNetworkError.isSuccess(dict["code"].int),
                   let nodes = dict["data"]["entities"]["nodes"].dictionaryObject,
                   let node = nodes.values.first as? [String: Any],
                   let objToken = node["obj_token"] as? String {
                    return (objToken, nil)
                } else if var docsErr = DocsNetworkError(dict["code"].int) {
                    docsErr.set(msg: dict["msg"].string)
                    return (nil, docsErr)
                } else {
                    return (nil, DocsNetworkError.invalidData)
                }
            }.start(result: { (result, error) in
                completion(result, error)
            })
    }


    public class func createFileV2(type: DocsType, name: String, parent: String = "", completion: @escaping (String?, Error?) -> Void) -> DocsRequest<String> {
        var params: [String: Any] =  [:]
        params["type"] = type.rawValue
        params["name"] = name
        params["parent_token"] = parent
        params["source"] = 0
        params["time_zone"] = TimeZone.current.identifier
        return DocsRequest<String>(path: OpenAPI.APIPath.createFilesV2, params: params)
            .set { (json) -> (String?, error: Error?) in
                let dict = JSON(json ?? "")
                if DocsNetworkError.isSuccess(dict["code"].int),
                   let nodes = dict["data"]["entities"]["nodes"].dictionaryObject,
                   let node = nodes.values.first as? [String: Any],
                   let objToken = node["obj_token"] as? String {
                    return (objToken, nil)
                } else if var docsErr = DocsNetworkError(dict["code"].int) {
                    docsErr.set(msg: dict["msg"].string)
                    return (nil, docsErr)
                } else {
                    return (nil, DocsNetworkError.invalidData)
                }
            }.start(result: { (result, error) in
                completion(result, error)
            })
    }


    public class func create(type: DocsType, name: String, in parent: String?, parameters: [String: Any]? = nil, completion: @escaping (String?, Error?) -> Void) -> DocsRequest<String> {
        var params: [String: Any] = parameters ?? [String: Any]()
        params["type"] = type.rawValue
        params["name"] = name
        params["parent_token"] = parent
        params["time_zone"] = TimeZone.current.identifier
        return DocsRequest<String>(path: OpenAPI.APIPath.createFiles, params: params)
            .set { (json) -> (String?, error: Error?) in
                let dict = JSON(json ?? "")
                if  DocsNetworkError.isSuccess(dict["code"].int),
                    let objToken = dict["data"]["obj_token"].string {
                    return (objToken, nil)
                } else if var docsErr = DocsNetworkError(dict["code"].int) {
                    docsErr.set(msg: dict["msg"].string)
                    return (nil, docsErr)
                } else {
                    return (nil, DocsNetworkError.invalidData)
                }
            }.start(result: { (result, error) in
                completion(result, error)
            })
    }


    ///创建副本
    public class func createCopyV2(type: DocsType,
                                 name: String?,
                                 token: String,
                                 parent: String?,
                                 parameters: [String: Any]? = nil,
                                 from: UIViewController?,
                                 moudle: PageModule,
                                 fileSize: Int64? = nil,
                                 completion: @escaping (String?, Error?) -> Void) -> DocsRequest<String> {
        var params: [String: Any] = parameters ?? [String: Any]()
        if type == .file, name?.contains(".") == true {
            let arraySubstrings: [Substring]? = name?.split(separator: ".")
            let lastName = arraySubstrings?.last ?? ""
            let suffix = "." + lastName
            let tmp = name
            let replaceC = " " + BundleI18n.SKResource.Doc_Facade_CopyDocSuffix + "." + lastName
            let newTitle = tmp?.replacingOccurrences(of: suffix, with: replaceC)
            params["title"] = newTitle
        } else {
            params["title"] = (name ?? "") + " " + BundleI18n.SKResource.Doc_Facade_CopyDocSuffix
        }
        params["obj_type"] = type.rawValue
        params["parent_token"] = parent
        params["obj_token"] = token
        params["need_comment"] = false
        params["source"] = 0
        params["time_zone"] = TimeZone.current.identifier
        if type == .sheet {
            params["async"] = true
        }
        params["copy_source"] = moudle.copySource
        return DocsRequest<String>(path: OpenAPI.APIPath.fileCopyV2, params: params)
            .set { (json) -> (String?, error: Error?) in
                let dict = JSON(json ?? "")
                if  DocsNetworkError.isSuccess(dict["code"].int),
                    let nodes = dict["data"]["entities"]["nodes"].dictionaryObject,
                    let node = nodes.values.first as? [String: Any],
                    let url = node["url"] as? String {
                    return (url, nil)
                } else if var docsErr = DocsNetworkError(dict["code"].int) {
                    docsErr.set(msg: dict["msg"].string)
                    return (nil, docsErr)
                } else {
                    return (nil, DocsNetworkError.invalidData)
                }
            }
            .set(method: .POST)
            .start(result: { (result, error) in
                completion(result, error)
                guard error == nil else {
                    if let fromVC = from {
                        UDToast.removeToast(on: fromVC.view)
                    }
                    if let err = (error as? DocsNetworkError) {
                        guard let from = from else {
                            spaceAssertionFailure("createCopy cannot get from vc")
                            return
                        }
                        if err.code == .createLimited {
                            // 租户达到创建的上线，弹出付费提示
                            showQuotaAlert(from: from)
                        } else if err.code == .spaceUserStorageLimited, QuotaAlertPresentor.shared.enableUserQuota {
                            let bizParams = SpaceBizParameter(module: moudle)
                            QuotaAlertPresentor.shared.showUserQuotaAlert(mountNodeToken: nil,
                                                                          mountPoint: nil,
                                                                          from: from,
                                                                          bizParams: bizParams)
                        } else if err.code == DocsNetworkError.Code.copyFileError {
                            if type == DocsType.file {
                                UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_DriveMakeCopyCrossUnitTips, on: from.view)
                            } else {
                                UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_DocMakeCopyCrossUnitTips, on: from.view)
                            }
                        } else if err.code == .spaceFileSizeLimited, SettingConfig.sizeLimitEnable, let size = fileSize {
                            QuotaAlertPresentor.shared.showUserUploadAlert(mountNodeToken: nil, mountPoint: nil, from: from, fileSize: size, quotaType: .bigFileToCopy)
                        } else if DocsNetworkError.isDlpError(err) {
                            DlpManager.updateCurrentToken(token: token)
                            let text = DocsNetworkError.dlpErrorMsg(err)
                            UDToast.showFailure(with: text, on: from.view.window ?? from.view)
                            PermissionStatistics.shared.reportDlpSecurityInterceptToastView(action: .CREATECOPY, dlpError: err)
                        } else {
                            UDToast.showFailure(with: err.errorMsg, on: from.view)
                        }
                    } else {
                        if let fromVC = from {
                            UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_OperateFailed, on: fromVC.view)
                        }
                    }
                    return
                }
            })
    }

    ///创建副本
    public class func createCopy(type: DocsType,
                                 name: String?,
                                 token: String,
                                 parent: String?,
                                 parameters: [String: Any]? = nil,
                                 from: UIViewController?,
                                 moudle: PageModule,
                                 fileSize: Int64? = nil,
                                 completion: @escaping (String?, Error?) -> Void) -> DocsRequest<String> {
        var params: [String: Any] = parameters ?? [String: Any]()
        params["title"] = getCopyTitle(objType: type, name: name)
        params["obj_type"] = type.rawValue
        params["parent_token"] = parent
        params["obj_token"] = token
        params["time_zone"] = TimeZone.current.identifier
        if type == .sheet {
            params["async"] = true
        }
        return DocsRequest<String>(path: OpenAPI.APIPath.fileCopy, params: params)
            .set { (json) -> (String?, error: Error?) in
                let dict = JSON(json ?? "")
                if  DocsNetworkError.isSuccess(dict["code"].int),
                    //let objToken = dict["data"]["obj_token"].string,
                    let url = dict["data"]["url"].string {
                    return (url, nil)
                } else if var docsErr = DocsNetworkError(dict["code"].int) {
                    docsErr.set(msg: dict["msg"].string)
                    return (nil, docsErr)
                } else {
                    return (nil, DocsNetworkError.invalidData)
                }
            }
            .set(method: .POST)
            .start(result: { (result, error) in
                completion(result, error)
                guard error == nil else {
                    if let fromVC = from {
                        UDToast.removeToast(on: fromVC.view)
                    }
                    if let err = (error as? DocsNetworkError) {
                        guard let from = from else {
                            spaceAssertionFailure("createCopy cannot get from vc")
                            return
                        }
                        if err.code == .createLimited {
                            // 租户达到创建的上线，弹出付费提示
                            showQuotaAlert(from: from)
                        } else if err.code == .spaceUserStorageLimited, QuotaAlertPresentor.shared.enableUserQuota {
                            let bizParams = SpaceBizParameter(module: moudle)
                            QuotaAlertPresentor.shared.showUserQuotaAlert(mountNodeToken: nil,
                                                                          mountPoint: nil,
                                                                          from: from,
                                                                          bizParams: bizParams)
                        } else if err.code == .spaceFileSizeLimited, SettingConfig.sizeLimitEnable, let size = fileSize {
                            QuotaAlertPresentor.shared.showUserUploadAlert(mountNodeToken: nil,
                                                                           mountPoint: nil,
                                                                           from: from,
                                                                           fileSize: size,
                                                                           quotaType: .bigFileToCopy)
                        } else if err.code == DocsNetworkError.Code.copyFileError {
                            if type == DocsType.file {
                                UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_DriveMakeCopyCrossUnitTips, on: from.view)
                            } else {
                                UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_DocMakeCopyCrossUnitTips, on: from.view)
                            }
                        } else if err.code == .coldDocument {
                            UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_OperateFailed, on: from.view)
                        } else if DocsNetworkError.isDlpError(err) {
                            DlpManager.updateCurrentToken(token: token)
                            let text = DocsNetworkError.dlpErrorMsg(err)
                            UDToast.showFailure(with: text, on: from.view.window ?? from.view)
                            PermissionStatistics.shared.reportDlpSecurityInterceptToastView(action: .CREATECOPY, dlpError: err)
                        } else {
                            UDToast.showFailure(with: err.errorMsg, on: from.view)
                        }
                    } else {
                        if let fromVC = from {
                            UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_OperateFailed, on: fromVC.view)
                        }
                    }
                    return
                }
            })
    }

    public class func getCopyTitle(objType: DocsType, name: String?) -> String {
        let title: String
        if let name = name, !name.isEmpty {
            title = name
        } else {
            title = objType.untitledString
        }
        if objType == .file, title.contains(".") {
            let arraySubstrings: [Substring]? = title.split(separator: ".")
            let lastName = arraySubstrings?.last ?? ""
            let suffix = "." + lastName
            let tmp = title
            let replaceC = " " + BundleI18n.SKResource.Doc_Facade_CopyDocSuffix + "." + lastName
            let newTitle = tmp.replacingOccurrences(of: suffix, with: replaceC)
            return newTitle
        } else {
            return "\(title) \(BundleI18n.SKResource.Doc_Facade_CopyDocSuffix)"
        }
    }


    public class func createByTemplate(type: DocsType,
                                       in parent: String?,
                                       parameters: [String: Any]? = nil,
                                       from: UIViewController?,
                                       templateSource: TemplateCenterTracker.TemplateSource? = nil,
                                       completion: @escaping (TemplateCreateDocsResult?, Error?) -> Void)
    -> DocsRequest<TemplateCreateDocsResult> {
        var params: [String: Any] = parameters ?? [String: Any]()
        params["type"] = type.rawValue
        params["parent_token"] = parent
        
        if let ts = templateSource {
            params["extra_info"] = ts.i18nExtInfo().jsonString
        } else {
            params["extra_info"] = ["time_zone": TimeZone.current.identifier].jsonString
        }
        
        return DocsRequest<TemplateCreateDocsResult>(path: OpenAPI.APIPath.createFilesByTemplate, params: params)
            .set { (json) -> (TemplateCreateDocsResult?, error: Error?) in
                let dict = JSON(json ?? "")
                if DocsNetworkError.isSuccess(dict["code"].int),
                   let data = dict["data"].dictionaryObject,
                   let result = TemplateCreateDocsResult.deserialize(from: data) {
                    return (result, nil)
                } else if var docsErr = DocsNetworkError(dict["code"].int) {
                    docsErr.set(msg: dict["msg"].string)
                    guard let from = from else {
                        return (nil, docsErr)
                    }
                    if docsErr.code == .createLimited {
                        // 租户达到创建的上线，弹出付费提示
                        showQuotaAlert(from: from)
                    } else if docsErr.code == .spaceUserStorageLimited, QuotaAlertPresentor.shared.enableUserQuota {
                        QuotaAlertPresentor.shared.showUserQuotaAlert(mountNodeToken: nil,
                                                                      mountPoint: nil,
                                                                      from: from,
                                                                      bizParams: nil)
                    } else if DocsNetworkError.isDlpError(docsErr) {
                        DlpManager.updateCurrentToken(token: "")
                        let text = DocsNetworkError.dlpErrorMsg(docsErr)
                        UDToast.showFailure(with: text, on: from.view.window ?? from.view)
                        PermissionStatistics.shared.reportDlpSecurityInterceptToastView(action: .OPEN, dlpError: docsErr)
                    }
                    return (nil, docsErr)
                } else {
                    return (nil, DocsNetworkError.invalidData)
                }
            }
            .set(method: .POST)
            .set(timeout: 20)
            .set(retryCount: 0)
            .start(result: { (result, error) in
                completion(result, error)
            })
    }
    
    public class func createBy(templateId: String,
                               in parent: String?,
                               parameters: [String: Any]? = nil,
                               from: UIViewController?,
                               templateSource: TemplateCenterTracker.TemplateSource? = nil,
                               completion: @escaping (TemplateCreateDocsResult?, Error?) -> Void)
    -> DocsRequest<TemplateCreateDocsResult> {

        var params: [String: Any] = parameters ?? [String: Any]()
        params["template_i18n_id"] = templateId
        
        if let ts = templateSource {
            params["extra_info"] = ts.i18nExtInfo().jsonString
        } else {
            params["extra_info"] = ["time_zone": TimeZone.current.identifier].jsonString
        }
        if let parent = parent {
            params["parent_token"] = parent
        }
        
        return DocsRequest<TemplateCreateDocsResult>(path: OpenAPI.APIPath.createFilesByTemplateId, params: params)
            .set { (json) -> (TemplateCreateDocsResult?, error: Error?) in
                let dict = JSON(json ?? "")
                if DocsNetworkError.isSuccess(dict["code"].int),
                   let data = dict["data"].dictionaryObject,
                   let result = TemplateCreateDocsResult.deserialize(from: data) {
                    return (result, nil)
                } else if var docsErr = DocsNetworkError(dict["code"].int) {
                    docsErr.set(msg: dict["msg"].string)
                    guard let from = from else {
                        return (nil, docsErr)
                    }
                    if docsErr.code == .createLimited {
                        // 租户达到创建的上线，弹出付费提示
                        showQuotaAlert(from: from)
                    } else if docsErr.code == .spaceUserStorageLimited, QuotaAlertPresentor.shared.enableUserQuota {
                        QuotaAlertPresentor.shared.showUserQuotaAlert(mountNodeToken: nil,
                                                                      mountPoint: nil,
                                                                      from: from,
                                                                      bizParams: nil)
                    } else if DocsNetworkError.isDlpError(docsErr) {
                        DlpManager.updateCurrentToken(token: "")
                        let text = DocsNetworkError.dlpErrorMsg(docsErr)
                        UDToast.showFailure(with: text, on: from.view.window ?? from.view)
                        PermissionStatistics.shared.reportDlpSecurityInterceptToastView(action: .OPEN, dlpError: docsErr)
                    }
                    return (nil, docsErr)
                } else {
                    return (nil, DocsNetworkError.invalidData)
                }
            }
            .set(method: .POST)
            .set(timeout: 20)
            .set(retryCount: 0)
            .start(result: { (result, error) in
                completion(result, error)
            })
    }
    
    static func showQuotaAlert(from: UIViewController) {
        guard QuotaAlertPresentor.shared.enableTenantQuota else {
            DocsLogger.info("oversea user user old logic")
            showOldQuotaAlert(from: from)
            return
        }
        QuotaAlertPresentor.shared.showQuotaAlert(type: .makeCopy, from: from)
    }
    
    static func showOldQuotaAlert(from: UIViewController) {
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.SKResource.Doc_List_StorageLimitTitle)
        dialog.setContent(text: BundleI18n.SKResource.Doc_List_StorageLimitDesc)
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel)
        dialog.addDestructiveButton(text: BundleI18n.SKResource.Doc_Facade_NotifyAdminUpgrade, dismissCheck: {  
            return true
        })
        Navigator.shared.present(dialog, from: from, animated: true, completion: nil)
    }

    ///文档、文件夹新旧信息
    public class func getEntryInfoFor(objToken: String, objType: DocsType, completion: @escaping (Int?, Error?) -> Void) -> DocsRequest<Int> {
        var params: [String: Any] = [String: Any]()
        params["obj_token"] = objToken
        params["obj_type"] = objType.rawValue
        return DocsRequest<Int>(path: OpenAPI.APIPath.getEntityInfo, params: ["entities": [params]])
            .set(encodeType: .jsonEncodeDefault)
            .set(method: .POST)
            .set {(json) -> (Int?, error: Error?) in
                let dict = JSON(json ?? "")
                if  DocsNetworkError.isSuccess(dict["code"].int),
                    let ownerType = dict["data"][objToken]["owner_type"].int {
                    return (ownerType, nil)
                } else if var docsErr = DocsNetworkError(dict["code"].int) {
                    docsErr.set(msg: dict["msg"].string)
                    return (nil, docsErr)
                } else {
                    return (nil, DocsNetworkError.invalidData)
                }
            }
            .start(result: { (result, error) in
                completion(result, error)
            })
    }

}
public struct TemplateCreateDocsResult: HandyJSON {
    var objToken: String?
    var objType: Int?
    var templateToken: String?
    public var title: String?
    public var url: String?
    
    mutating public func mapping(mapper: HelpingMapper) {
        mapper <<< self.objToken <-- "obj_token"
        mapper <<< self.objType <-- ["obj_type", "type"]
        mapper <<< self.templateToken <-- "template_token"
        mapper <<< self.url <-- "obj_url"
    }
    
    public init() {}
}
