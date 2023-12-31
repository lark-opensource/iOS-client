//
//  DocsNotifications.swift
//  SKCommon
//
//  Created by guotenghu on 2019/6/16.
//  

import Foundation

extension Notification.Name {
    /// Used as a namespace for all `Docs` related notifications.
    public struct Docs {
        static public let nameSpace = "docs.bytedance.notification.name"
        static public let Test = Notification.Name(rawValue: "com.docs.bytedance.test")

        /// 刷新个人文件列表
        static public let RefreshPersonFile = Notification.Name(rawValue: "docs.bytedance.notification.name.Docs.RefreshPersonFile")

        /// 刷新协作者列表
        static public let refreshCollaborators = Notification.Name(rawValue: "docs.bytedance.notification.name.Docs.refreshCollaborators")

        /// 刷新共享空间共享文件夹列表
        static public let refreshShareSpaceFolderList = Notification.Name(rawValue: "docs.bytedance.notification.name.Docs.refreshShareSpaceFolderList")

        /// 刷新最近浏览列表
        public static let refreshRecentFilesList = Notification.Name(rawValue: "docs.bytedance.notification.name.Docs.refreshRecentFilesList")
        public static func didSyncFakeObjToken(_ fakeToken: FileListDefine.ObjToken) -> Notification.Name {
            return Notification.Name(rawValue: "com.docs.bytedance.didSync.\(fakeToken)")
        }

        /// 收到通知以后，马上加到预加载队列里
        static public let addToPreloadQueue = Notification.Name(rawValue: "docs.bytedance.notification.name.receiveNoDelayPreload")

        /// user did login, key: "userID": String
        static public let userDidLogin = Notification.Name(rawValue: "docs.bytedance.notification.name.userDidLogin")

        /// user will logout
        static public let userWillLogout = Notification.Name(rawValue: "docs.bytedance.notification.name.userWillLogout")

        /// user did logout
        static public let userDidLogout = Notification.Name(rawValue: "docs.bytedance.notification.name.userDidLogout")

        /// 预加载js完成
        static public let preloadDocsFinished = Notification.Name(rawValue: "docs.bytedance.notification.name.preloadDocs.finished")
        static public let preloadDocsStart = Notification.Name(rawValue: "docs.bytedance.notification.name.preloadDocs.start")

        /// 预加载html任务完成
        static public let preloadDocsHtmlFinished = Notification.Name(rawValue: "docs.bytedance.notification.name.preloadDocsHtml.finished")

        ///准备push第一个webView
        static public let showingDocsViewController = Notification.Name(rawValue: "docs.bytedance.notification.name.showingDocsViewControllerl")
        ///准备dismiss最后一个webview
        static public let didHideDocsViewController = Notification.Name(rawValue: "docs.bytedance.notification.name.didHideDocsViewController")

        /// sheet 在输入态下弹出一个 modal view controller
        static public let modalViewControllerWillAppear = Notification.Name(rawValue: "com.bytedance.ee.docs.modalViewControllerWillAppear")
        static public let modalViewControllerWillDismiss = Notification.Name(rawValue: "com.bytedance.ee.docs.modalViewControllerWillDismiss")

        static public let createViewWillShowNotification = NSNotification.Name(rawValue: "\(Notification.Name.Docs.nameSpace).DocsCreateViewWillShow")
        static public let createViewWillHideNotification = NSNotification.Name(rawValue: "\(Notification.Name.Docs.nameSpace).DocsCreateViewWillHide")

        static public let docsInfoIconKeyUpdated = NSNotification.Name(rawValue: "\(Notification.Name.Docs.nameSpace).docsInfoIconKeyUpdated")
        /// RN Load Complete
        static public let rnSetupEnviromentComplete = NSNotification.Name(rawValue: "docs.bytedance.notification.name.Docs.rnSetupEnviromentComplete")

        // MARK: - WIKI
        static public let wikiTitleUpdated = Notification.Name(rawValue: "docs.bytedance.notification.name.Docs.wikiTitleUpdated")
        static public let wikiTreeNodeTitleUpdated = Notification.Name(rawValue: "docs.bytedance.notification.name.Docs.wikiTreeNodeTitleUpdated")
        static public let clipWikiSpaceListUpdate = Notification.Name(rawValue: "docs.bytedance.notification.name.Docs.clipWikiSpaceListUpdate")

        // RN Reload Complete
        static public let rnReloadComplete = Notification.Name(rawValue: "docs.bytedance.notification.name.Docs.rnReloadComplete")

        // find UnSync pics Complete
        static public let findUnSyncPicsComplete = Notification.Name(rawValue: "docs.bytedance.notification.name.Docs.findUnSyncPicsComplete")

        static public let userWillCleanNewCache = Notification.Name(rawValue: "docs.bytedance.notification.name.userWillCleanNewCache")

        static public let userDidCleanNewCache = Notification.Name(rawValue: "docs.bytedance.notification.name.userDidCleanNewCache")

        static public let fileListLoadDbFinish = Notification.Name(rawValue: "docs.bytedance.notification.name.fileListLoadDbFinish")

        // MARK: - publicPermissonUpdate
        static public let publicPermissonUpdate = Notification.Name(rawValue: "docs.bytedance.notification.name.publicPermissonUpdate")

        static public let bitableRulesUpdate = Notification.Name(rawValue: "docs.bytedance.notification.name.bitableRulesUpdate")
        static public let bitableRulesRemoveSuccess = Notification.Name(rawValue: "docs.bytedance.notification.name.bitableRulesRemoveSuccess")

        /// docsTabDidAppear
        static public let docsTabDidAppear = Notification.Name(rawValue: "docs.bytedance.notification.name.docsTabDidAppear")

        // MARK: - SimpleModeManager
        static public let clearDataNoticationInSimpleMode = Notification.Name(rawValue: "docs.bytedance.notification.name.clearDataNoticationInSimpleMode")


        // Wiki 文档内收藏/取消收藏通知目录树
        static public let wikiStarNode = Notification.Name(rawValue: "docs.bytedance.notification.name.wikiStarNode")
        static public let wikiUnStarNode = Notification.Name(rawValue: "docs.bytedance.notification.name.wikiUnStarNode")
        // Wiki 文档内space收藏/取消收藏通知目录树
        static public let wikiExplorerStarNode = Notification.Name(rawValue: "docs.bytedance.notification.name.wikiExplorerStarNode")
        // Wiki 文档space快速访问/取消快速访问通知目录树
        static public let WikiExplorerPinNode = Notification.Name(rawValue: "docs.bytedance.notification.name.wikiExplorerPinNode")
        // wiki 跨库移动完成
        static public let wikiAcross = Notification.Name(rawValue: "docs.bytedance.notification.name.wikiAcross")
        // 新首页MVP置顶云文档部分，在文档详情页内部删除当前文档后，同步外部列表移除
        static public let deleteDocInNewHome = Notification.Name(rawValue: "docs.bytedance.notification.name.deleteDocInNewHome")

        // Space 的操作导致文档被删除，在 object 中传递被删除的文档 objToken，通知其他场景关闭相关页面
        static public let deletedBySpaceOperation = Notification.Name(rawValue: "\(nameSpace).deletedBySpaceOperation")
        
        // Space 快速访问列表刷新协同
        static public let quickAccessUpdate = Notification.Name(rawValue: "space.quickaccess.need-update")

        // 文档的模板tag打开或关闭
        static public let templateTagChange = Notification.Name(rawValue: "docs.bytedance.notification.name.templateTagChange")

        // 企业密钥变更
        static public let cipherChanged = Notification.Name(rawValue: "docs.bytedance.notification.name.cipherChanged")
        
        // 监听应用的 event 事件
        static public let appliationSentEvent = Notification.Name(rawValue: "docs.bytedance.notification.name.appliationSentEvent")
        // 版本权限、状态发生变化的通知
        static public let versionDeleteNotifictaion = Notification.Name(rawValue: "docs.bytedance.notification.name.versionDeleteNotifictaion")
        static public let versionPermissionChangeNotifictaion = Notification.Name(rawValue: "docs.bytedance.notification.name.versionPermissionChangeNotifictaion")
        // docs的token如果是版本token，抛出
        static public let docsTokenCheckFailNotifictaion = Notification.Name(rawValue: "docs.bytedance.notification.name.docsTokenCheckFailNotifictaion")
        // 版本信息更新通知
        static public let updateVersionInfoNotifictaion = Notification.Name(rawValue: "docs.bytedance.notification.name.updateVersionInfoNotifictaion")
        
        // 监听协作者列表变化事件
        static public let CollaboratorListChanged = Notification.Name(rawValue: "docs.bytedance.notification.name.collaboratorListChanged")
        // 热更包更新后通知预加载webview
        static public let geckoPackageDidUpdate = Notification.Name(rawValue: "docs.bytedance.notification.name.geckoPackageDidUpdate")
        
        // 离线创建wiki文档
        static public let addFakeWikiNodeInWikiTree = Notification.Name(rawValue: "docs.bytedance.notification.name.addFakeNodeInWikiTree")
        static public let updateFakeWikiInfo = Notification.Name(rawValue: "docs.bytedance.notification.name.updateFakeWikiInfo")
        
        // 金刚位的高亮状态通知
        static public let notifySelectedSpaceEntarnce = Notification.Name(rawValue: "docs.bytedance.notification.name.selectedSpaceEntrance")
        
        // 关联文档解除通知
        static public let deleteAssociateApp = Notification.Name(rawValue: "docs.bytedance.notification.name.deleteAssociateApp")
        
        // ipad列表切换同步phone样式列表
        static public let notifySelectedListChange = Notification.Name(rawValue: "docs.bytedance.notification.name.selectedListChange")
    }
}
