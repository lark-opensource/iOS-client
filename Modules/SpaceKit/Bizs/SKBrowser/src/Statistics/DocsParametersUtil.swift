//
//  DocsCommonParametersUtil.swift
//  SKBrowser
//
//  Created by zengsenyuan on 2021/11/4.
//  


import SKFoundation
import SKCommon
import SKInfra

/// 文档公共参数生成工具
public struct DocsParametersUtil {

    /// 根据文档信息，获取 CMM 公共参数和 Space 公共参数
    /// - Parameter docsInfo: 文档信息
    /// - Returns: 公告参数
    /// 公参文档： https://bytedance.feishu.cn/wiki/wikcnYAaVu1taJMtZmqS954fPjh?sheet=G016mv
    public static func createCommonParams(by docsInfo: DocsInfo) -> [String: String] {
        let token = docsInfo.token
        let (userPerm, filePerm) = getPermission(token: token)
        var params: [String: String] = [
            "page_token": DocsTracker.encrypt(id: token),
            "file_id": DocsTracker.encrypt(id: token),
            "file_type": docsInfo.inherentType.name, //与数据方确定，这里需要使用真实类型。
            "app_form": (docsInfo.isInVideoConference == true) ? "vc" : "none",
            "module": docsInfo.type.name, //文档的类型名称刚好与模块一一对应，对其他地方的埋点无参考性。与数据方确定：如果是 wiki 的话，模块名为 wiki。
            "sub_module": "none",
            "user_permission": userPerm,
            "file_permission": filePerm,
            "is_shortcut": docsInfo.isShortCut ? "true" : "false",
            "shortcut_id": docsInfo.isShortCut ? DocsTracker.encrypt(id: token) : "none",
            "mobile_screen_mode": OrientationUtil.shared.orientation.isPortrait ? "vertical" : "horizontal"
        ]

        if let wikiInfo = docsInfo.wikiInfo {
            params["is_shortcut"] = String(wikiInfo.wikiNodeState.isShortcut)
            if wikiInfo.wikiNodeState.isShortcut {
                if wikiInfo.wikiNodeState.originIsExternal {
                    params["shortcut_id"] = DocsTracker.encrypt(id: token)
                    params["original_docs_container"] = "space"
                } else {
                    let originToken = wikiInfo.wikiNodeState.shortcutWikiToken ?? token
                    params["shortcut_id"] = DocsTracker.encrypt(id: originToken)
                    params["original_docs_container"] = "wiki"
                }
            } else {
                params["original_docs_container"] = "wiki"
            }
        } else {
            params["original_docs_container"] = "space"
        }

        /*
         container_type: wiki/folder
         container_id:  当container_type=folder时，上报文件夹id。当container_type=wiki时，上报space_id
         */
        if docsInfo.type == .wiki {
            params["container_type"] = "wiki"
            params["container_id"] = docsInfo.fileEntry.shareFolderInfo?.spaceID ?? "none"
        } else if docsInfo.type == .folder {
            params["container_type"] = "folder"
            params["container_id"] = DocsTracker.encrypt(id: token)
        }
        
        if docsInfo.inherentType == .baseAdd {
            params["file_type"] = "base_add"
            params["module"] = "base_add"
        }
        
        return params
    }
    

    // 只是上报用，暂时放过不改造
    /// 根据文档 token 获取相关文献
    /// - Parameter token: 文档token
    @available(*, deprecated, message: "Use PermissionSDK instead - PermissionSDK")
    private static func getPermission(token: String) -> (userPermission: String, filePermission: String) {
        let permissonMgr = DocsContainer.shared.resolve(PermissionManager.self)!
        let userPermission = permissonMgr.getUserPermissions(for: token)?.rawValue ?? 1
        let filePermission = permissonMgr.getPublicPermissionMeta(token: token)?.rawValue ?? "0"
        return ("\(userPermission)", filePermission)
    }
}
