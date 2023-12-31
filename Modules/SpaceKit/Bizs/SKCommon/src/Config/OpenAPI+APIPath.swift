//
//  OpenAPI.swift
//  DocsNetwork
//
//  Created by weidong fu on 1/1/2018.
//
//  swiftlint:disable file_length

import Foundation
import SKFoundation
import SKInfra

//接口文档地址： https://wiki.bytedance.net/pages/viewpage.action?pageId=145986898
public extension OpenAPI {
    
    struct APIPath {

    /*
         1. 回收站
         4. 个人文档
         5. 与我共享，是不是废弃了？
         6. 共享文件夹，是不是废弃了？
        */
        public static let fileList = "/api/explorer/root/get/"
        public static let createToDo = "/api/platform/template/create_todo/"
        //todoAction
        public static let updateTodoStatus = "/api/todo/status/update/"

        public static let search = "/api/search/refine_search/"
        public static let searchWiki = "/api/search/search_wiki/"
        public static let updateSearchHistory  = "/api/search/update_refine_search_history/"
        public static let getSearchHistory  = "/api/search/get_refine_search_history/"
        public static let delSearchHistory  = "/api/search/del_refine_search_history/"
        public static let folderDetail = "/api/explorer/folder/children/"
        public static let childrenListV3 = "/api/explorer/v3/children/list/"
        public static let fileExternalHint = "/api/explorer/obj/show_external_hint/"
        public static let getPersonFileListInHome = "/api/explorer/my/object/list/" // 新首页-my space 底部文档列表
        public static let mySpaceListV2 = "/api/explorer/v2/my_space/list/"
        public static let mySpaceListV3 = "/api/explorer/v3/my_space/list/"
        public static let mySpaceFolder = "/api/explorer/v3/my_space/folder/"
        public static let mySpaceFileV3 = "/api/explorer/v3/my_space/obj/"
        public static let recentUpdate = "/api/explorer/recent/list/"
        public static let subordinateRecentList = "/api/bff/workspace/recent/team/"
        public static let recentUpdateV2 = "/api/explorer/v2/recent/list/"
        public static let userProfile = "/api/user/"
        public static let createFile = "/api/explorer/create/"
        public static let appVersionCheck = "/api/mobile/check_version/"
        public static let htmlTemplate = "/mobile/get_template/"
        public static let move = "/api/explorer/move/"
        public static let moveV2 = "/api/explorer/v2/move/"
        public static let addShortCutTo = "/api/explorer/v2/create/shortcut/"
        public static let addTo            = "/api/explorer/object/archive/"
        public static let deleteV2 = "/api/explorer/v2/remove/"
        public static let deleteInDoc = "/api/explorer/v2/remove/object/"
        public static let spaceApplyDelete = "/api/explorer/v2/apply_delete/"
        public static let deleteByObjToken = "/api/explorer/obj/delete/"
        public static let queryPPTXToken = "/api/slide/query_pptx_token"
        public static let spaceOpenReport = "/api/explorer/recent/report/"

        /// 新首页删除
        /// https://bytedance.feishu.cn/wiki/wikcn7tDrSAPSnheTnSyX4KrEqd
        public static let deleteRecentFileByObjTokenV2 = "/api/explorer/v2/recent/delete/"
        
        public static let deleteShareWithMeListFileByObjToken = "/api/explorer/share/object/delete/"
        public static let deleteFileInFolderByToken = "/api/explorer/remove/"

        public static let rename = "/api/explorer/rename/"
        public static let renameV2 = "/api/explorer/v2/rename/"
        public static let renameSheet = "/api/sheet/update_meta/"
        public static let renameBitable = "/api/bitable/update_meta/"
        public static let renameMindnote = "/api/meta/update/"
        public static let renameSlides = "/api/meta/update/"
        public static let trashDelete = "/api/explorer/trash/delete/"
        public static let trashRestore = "/api/explorer/trash/restore/"
        public static let recommend = "/api/mention/recommend/"
        public static let api = "/api"
        public static let feeds = "/api/message/get_all_message/"
        public static let allUnread = "/api/message/get_all_unread/"
        public static let findMeta = "/api/meta/"
        public static let batchMeta = "/api/meta/batch"
        // MARK: feed
        public static let getUserMsg = "/api/message/get_user_message/"
        public static let getNewerMsg = "/api/message/get_user_newer_message/"
        public static let countNewMsg = "/api/message/count_user_message/"
        public static let folderPermission = "/api/explorer/space/apply_permission/"
        public static let feedMessageSyncForLD = "/space/api/notice/message_sync"
        
        /// 反馈所有消息已读
        public static let markReadAll            = "/api/message/user_read_all/"

        public static let readAll  = "/api/message/read_all/"
        /// 某条消息已读。
        public static let msgRead = "/api/message/read/"
        public static let createmove = "/api/explorer/createmove/"
        /// get_message废弃了不要用了
        public static let getFeed = "/api/message/get_message/"
        public static let getFeedV2 = "/api/message/get_message.v3/"
        public static let markMsgRead = "/api/message/read/​"
        public static let feedMute = "/api/platform/notice/mute/" // 文档消息免打扰开关
        public static let cleanMessage = "/api/platform/notice/clear_unread/" //一键已读开关

        // MARK: 预加载文档内容
        public static let preloadContent         = "/api/rce/messages"
        public static let getUserTicket          = "/api/passport/ws_ticket/"
        public static let preloadPageClientVar   = "/api/docx/pages/client_vars"
        public static let getDocxSSRContent      = "/ssr-mobile-app/docx/"
        // MAEK: 配置拉取
        public static let remoteConfig           = "/api/appconfig/get/"
        // 拉取文档版本号
        public static let remoteVersion          = "/api/rce/mget_version"

        // 请求文档权限
        public static let requestFilePermissionUrl = "/api/suite/permission/apply_permission/"
        public static let getParentToken           = "/api/explorer/get_token_info/"
        public static let fetchVisibleUserGroup    = "/api/suite/platform/visible_group/"
        public static let applyExemptAuditControl  = "/api/suite/permission/apply_permission_from_admin"

        //点赞
        public static let likesCount = "/api/like/count/"
        public static let likesList   = "/api/like/data/"
        public static let like        = "/api/like/like/"
        public static let dislike     = "/api/like/dislike/"

        // Drive局部评论
        public static let areaComments = "/api/box/comment/get/"
        public static let addAreaComment = "/api/box/comment/add/"

        /// 获取与我共享
        public static let shareFiles = "/api/explorer/share/object/list/"

        ///获取与我共享v2
        public static let shareFilesV2 = "/api/explorer/v2/share/list/"

        /// 获取共享文件夹
        public static let shareFolder = "/api/explorer/share/folder/list/"
        public static let newShareFolder = "/api/explorer/share/folder/newlist/"
        public static let newShareFolderV2 = "/api/explorer/v2/share/folder/list/"

        public static let hideShareFolder = "/api/explorer/share/folder/hide/"
        public static let showShareFolder = "/api/explorer/share/folder/show/"
        public static let hideShareFolderV2 = "/api/explorer/v2/share/folder/hide/"
        public static let showShareFolderV2 = "/api/explorer/v2/share/folder/show/"

        /// 获取收藏
        public static let getFavorites = "/api/explorer/star/list/"
        /// 获取收藏
        public static let getFavoritesV2 = "/api/explorer/v2/star/list/"

        /// 添加收藏
        public static let addFavorites = "/api/explorer/star/new/"

        /// 取消收藏
        public static let removeFavorites = "/api/explorer/star/remove/"

        /// 添加订阅
        public static let addSubscribe = "/api/subscribe/add"

        /// 取消订阅
        public static let removeSubscribe = "/api/subscribe/delete"

        /// 修改顺序
        public static let changeFavoritesPosition = "/api/explorer/star/move/"

        /// 获取Pin
        public static let getPins = "/api/explorer/pin/list/"

        /// 获取Pin
        public static let getPinsV2 = "/api/explorer/v2/pin/list"

        /// 添加Pin
        public static let addPins = "/api/explorer/pin/add/"

        /// 取消Pin
        public static let removePins = "/api/explorer/pin/remove/"

        /// 修改pin的位置
        public static let changePinPosition = "/api/explorer/pin/move/"

        /// 请求 Drive 缩略图
        public static let thumbnailDownload = "/api/box/stream/download/v2/cover/"

        /// 同步后台生成缩略图
        public static let thumbnailSync = "/api/thumbnail/sync/"

        /// 获取预览链接/旧的逻辑，兼容坚果云
        public static let getDownloadUrl = "/api/drive/getdownloadurl"

        /// 客服
        public static let customerServiceID = "/api/message/join_on_call_chat/"

        /// 创建文档/表格
        public static let createFiles = "/api/explorer/create/"

        /// 创建文档v2接口
        public static let createFilesV2 = "/api/explorer/v2/create/object/"

        /// 创建文件夹v2接口
        public static let createFolderV2 = "/api/explorer/v2/create/folder/"
        
        /// 获取文件/文件夹申诉状态
        public static let getComplaintInfo = "/api/platform/review/complaint/get/"
        public static let postComplaintInfo = "/api/platform/review/complaint/"


        /// 创建新年调查问卷
        public static let createNewSurvey = "/api/explorer/spring_questionnaire/"

        // MARK: - Drive
        /// 获取文件信息
        public static let fetchFileInfo = "/api/box/file/info/"

        /// 查询 Excel 文件编辑类型，用于判断是否通过 Sheet 打开编辑 Excel
        public static let excelFileEditType = "/api/v2/sheet/file_edit_type/"

        /// 获取服务端转码预览的地址
        public static let driveGetServerPreviewURL = "/api/box/preview/get/"

        /// 获取压缩文件预览目录
        public static let drivePreviewArchiveTree = "/api/box/preview/archive_tree"

        /// 下载原文件，需要有导出权限才可以下载，有安全风险，建议使用下面的`driveFetchPreviewFile`
        public static let driveOriginalFileDownload = "/api/box/stream/download/all/"

        /// 通过session获取预览文件
        public static let driveFetchPreviewFile = "/api/box/stream/download/preview/"

        /// 更新文件信息
        public static let updateFileInfo = "/api/box/file/update_info/"

        /// 保存到云空间
        public static let saveToSpace = "/api/box/file/save/"

        /// 获取非创作工具附件权限信息，目前只有email附件使用
        public static let attachmentPermission = "/api/box/file/permission/"
        
        public static let drivePreviewHtmlSubTable = "/api/box/stream/download/preview_sub"

        // MARK: - 更多菜单
        /// 历史记录列表
        public static let fileHistoryList = "/api/box/file/history/"

        /// 阅读数统计信息
        public static let readingData = "/api/obj_stats/get/"

        /// meta 接口, 参数是 token + type
        public static var meta: (_ token: String, _ type: Int) -> String = {
            return "/api/meta/?token=\($0)&type=\($1)"
        }

        /// 返回待生效和正在生效的公告
        public static let bulletinGet = "/api/bulletin/get/"
        /// 返回待生效和正在生效的公告
        public static let bulletinUpdateStatus = "/api/bulletin/close_status/"

        /// 关闭公告显示
        public static let bulletinClose    = "/api/bulletin/close/"

        /// 新建面板-拉取推荐模板
        public static let getRecommendTemplateList = "/api/obj_template/recommend/"
        /// 拉取模板搜索界面的推荐项目
        public static let getTemplasteSearchKeyRecommend = "/api/platform/template/search_key_recommend/"
        /// 拉取模板中心的banner
        public static let getTemplateCenterBanner = "/api/platform/template/template_banner/"
        
        public static let getThemeTemplateList = "/api/platform/template/topic_template_list/"
        /// 场景化模版详情
        public static let getTemplateCollection = "/api/platform/template/preview_template_collection"
        /// 领取模板合集
        public static let useTemplateCollection = "/api/platform/template/use_template_collection"
        /// Onboarding Banner - 拉取推荐模板
        public static let getBannerRecommendTemplateList = "/api/platform/obj_template/banner_recommend/"
        public static let getBannerRecommendTemplateListV2 = "/api/platform/obj_template/banner_recommend_v2/"
        /// 拉取模板列表
        public static let getTemplateList = "/api/obj_template/list.v2/"

        /// 通过模板创建文档
        public static let createFilesByTemplate = "/api/obj_template/create_obj/"
        
        /// 通过模版国际化id创建文档
        public static let createFilesByTemplateId = "/api/platform/template/create_i18n_obj/"
        // MARK: - 3.6
        ///获取wiki信息
        public static let getWikiInfo = "/api/wiki/tree/get_node/"

        // 导入为Docs在线文档
        public static let parseFileV2 = "/api/parser/parse_file/v2/"
        public static let importFile = "/api/import/create/"
        public static let importIMFile = "/api/larkimport/create/"

        // 获取导入结果
        public static let getParseResult = "/api/parser/getresult/"
        public static let getImportResult = "/api/import/result/"
        /// copy的drive接口
        public static let driveMutiCopy = "/api/box/file/multi_copy/"

        // 废弃，下个版本删除
        /// 请求导出 docx、pdf、xlsx、pptx、slide2pdf、slide2png
        public static let requestExport = "/api/parser/export/"
        /// 轮询导出结果
        public static let getExportResult = "/api/parser/get_export_result/"
        /// 下载导出的文件
        public static let downloadExport = "/api/parser/download/"

        /// 请求导出新接口
        public static let requestExportNew = "/api/export/create"
        /// 轮询导出结果新接口
        public static let getExportResultNew = "/api/export/result/"

        /// 提示管理员升级套餐
        public static let notifysuitebot = "/api/explorer/lark/notifysuitebot/"

        /// 传图接力
        public static let fileUpload    = "/api/file/upload/"
        public static let transmitImage = "/api/transmit_image/"

        ///创建副本
        public static let fileCopy = "/api/explorer/clone/"
        public static let fileCopyV2 = "/api/explorer/v2/clone/"
        public static let copyToWiki = "/api/wiki/v2/tree/node/copy_by_obj/"

        /// Onboarding
        public static let getOnboarding = "/api/user_guide/get/"
        public static let updateOnboarding = "/api/user_guide/update/"
        public static let doneOnboarding = "/api/user_guide/done/"
        /// 设置用户属性
        public static let setUserProperties = "/api/user_properties/set/"
        
        /// 文档icon
        public static let getIcon = "/api/icon/get"
        
        /// 工作台
        public static let bitableApi = "/api/bitable"
        public static func getWorkbenchStatus(_ token: String) -> String {
            return "\(bitableApi)/\(token)/workbench/status"
        }
        public static func workbenchAdd(_ token: String) -> String {
            return "\(bitableApi)/workbench/\(token)/add"
        }
        public static func workbenchRemove(_ token: String) -> String {
            return "\(bitableApi)/workbench/\(token)/remove"
        }
        public static func shouldShowWorkbenchOnboarding(_ token: String) -> String {
            return "\(bitableApi)/\(token)/workbench/guide/status"
        }

        // MARK: - Workspace 互通
        /// 移动添加到最近三个文件夹
        public static let recentlyUsedFolders = "/api/explorer/recent/folderpath/"
        public static let recentlyUsedFoldersV2 = "/api/explorer/v2/recent/folder_path/"

        public static let getSpaceMoveReviewer = "/api/explorer/v2/move_reviewer/"
        public static let spaceApplyMoveToSpace = "/api/explorer/v2/apply_move/"
        public static let spaceStartMoveToWiki = "/api/wiki/v2/tree/move_from_space2/"
        public static let spaceGetMoveToWikiStatus = "/api/wiki/v2/tree/move_from_space2_status/"
        public static let spaceApplyMoveToWiki = "/api/wiki/v2/tree/apply_move_from_space2/"
        /// 检查是否是在当前节点/文件夹下重复创建shortcut
        public static let checkRepeatCreateShortcut = "/api/bff/workspace/check_shortcut"

        // MARK: - 域名配置请求
        public static let getExtraDomainConfig = "/api/infra/domains/all"

        // MARK: - wiki
        public static let getAllWikiSpace = "/api/wiki/space/get_all_space/"
        public static let getRecentVisitWiki = "/api/wiki/search/get_recent/"
        public static let wikiGetRelation = "/api/wiki/tree/get_wiki_relation/"
        public static let wikiGetChild = "/api/wiki/tree/get_wiki_child/"
        public static let wikiDeleteRelation = "/api/wiki/tree/del_wiki_relation/"
        public static let wikiAddRelation = "/api/wiki/tree/create_wiki_relation/"
        public static let wikiStarSpace = "/api/wiki/space/star/add/"
        public static let wikiUnstarSpace = "/api/wiki/space/star/delete/"
        
        public static let wikiMoveRelation = "/api/wiki/tree/move_wiki_relation/"
        public static let wikiGetSpaceInfo = "/api/wiki/space/get_space_info/"
        public static let wikiGetUserRole = "/api/wiki/perm/get_user_role/"
        public static let getThumbnailURL = "/api/file/get_thumbnail_url"
        public static let wikiMoveRelationV2 = "/api/wiki/tree/v2/move_wiki_relation/"
        public static let wikiNodeType = "/api/wiki/tree/get_type/"

        // wiki2.0
        public static let getAllWikiSpaceV2 = "/api/wiki/v2/space/get_all_space/"
        public static let getAllWikiSpaceV2New = "/api/wiki/v2/space/get/"
        public static let getRecentVisitWikiV2 = "/api/wiki/v2/search/get_recent/"
        public static let wikiGetRelationV2 = "/api/wiki/v2/tree/get_info/"
        public static let wikiGetChildV2 = "/api/wiki/v2/tree/get_node_child/"
        public static let wikiDeleteNodeV2 = "/api/wiki/v2/tree/del_node/"
        public static let wikiAddRelationV2 = "/api/wiki/v2/tree/create_node/"
        public static let wikiStarSpaceV2 = "/api/wiki/v2/space/star/add/"
        public static let wikiUnstarSpaceV2 = "/api/wiki/v2/space/star/delete/"
        public static let wikiGetSpaceInfoV2 = "/api/wiki/v2/space/get_space_info/"
        public static let wikiMoveNodeV2 = "/api/wiki/v2/tree/move_node/"
        public static let wikiNodeTypeV2 = "/api/wiki/v2/tree/get_type/"
        public static let getWikiInfoV2 = "/api/wiki/v2/tree/get_node/"
        public static let wikiStarNode = "/api/wiki/v2/tree/star/new/"
        public static let wikiUnStarNode = "/api/wiki/v2/tree/star/remove/"
        public static let wikiGetStarList = "/api/wiki/v2/tree/star/get_favorite_info/"
        public static let wikiGetNodePermission = "/api/wiki/v2/perm/node/"
        public static let wikiGetSpacePermission = "/api/wiki/v2/perm/space/"
        public static let wikiCopyFile = "/api/wiki/v2/tree/node/copy/"
        public static let wikiCopyFileToSpace = "/api/wiki/v2/tree/node/copy_to_space/"
        public static let wikiGetMembers = "/api/wiki/v2/space/get_member/"
        public static let wikiBrowserReport = "/api/wiki/v2/search/wiki_browse_report/"
        public static let wikiGetVersion = "/api/wiki/v2/version/get/"
        public static let wikiGetVersionInfo = "/api/wiki/v2/tree/get_type_info/"
        public static let wikiDeleteSingleNode = "/api/wiki/v2/tree/del_single_node/"
        public static let wikiDeleteNodeStatus = "/api/wiki/v2/tree/del_single_node_status/"
        public static let getStarWikiSpace = "/api/wiki/v2/space/star/get/"
        public static let wikiFilterList = "/api/wiki/v2/space/class/get/"
        public static let wikiLibrarySpaceId = "/api/wiki/v2/space/my_library/get/"
        public static let createWikiMyLibrary = "/api/wiki/v2/space/create/"
        public static let wikiApplyDelete = "/api/wiki/v2/tree/apply_delete/"

        /// 获取 Wiki 公告
        public static let wikiAnnouncementList = "/api/wiki/v2/notice/list/"
        /// 上报公告已读信息
        public static let wikiAnnouncementReadReport = "/api/wiki/v2/notice/read_report/"
        /// 更新 Wiki 公告
        public static let wikiAnnouncementUpdate = "/api/wiki/v2/notice/update/"

        public static let wikiUpdateTitle = "/api/wiki/v2/tree/update_title/"
        public static let wikiBatchGetWikiInfoV2 = "/api/wiki/v2/tree/m_get_node_info/"
        /// 展示Wiki Feed入口
        public static let wikiEntranceStatus = "/api/bff/workspace/recommstatus"
        public static let wikiGetObjInfo = "/api/wiki/v2/obj/info/"

        /// 移动到 space
        public static let wikiGetMoveNodeAuthorizedUserInfo = "/api/wiki/v2/tree/move_node_authorized_userinfo/"
        public static let wikiApplyMoveNode = "/api/wiki/v2/tree/apply_move_node/"
        public static let wikiApplyMoveToSpace = "/api/wiki/v2/tree/apply_move_to_space/"
        public static let wikiStartMoveToSpace = "/api/wiki/v2/tree/move_to_space/"
        public static let wikiCheckMoveToSpaceStatus = "/api/wiki/v2/tree/move_to_space_status/"

        /// 获取保留标签入口
        public static let retentionItemVisible = "/lark/scs/compliance/entity/ccm/label/setting_visible"

        // MARK: - 精简模式
        // 最近浏览
        public static let getRecentListInLeanMode = "/api/explorer/lean/browse/list/"
        // 快速访问
        public static let getPinListInLeanMode = "/api/explorer/lean/pin/list/"
        // 由我创建
        public static let getMyObjectListInLeanMode = "/api/explorer/lean/my/object/list/"
        // 与我共享
        public static let getShareObjectListInLeanMode = "/api/explorer/lean/share/object/list/"
        
        // MARK: - DriveSDK
        // 获取文件信息
        public static let fetchFileInfoV2 = "/api/box/sdk/file/info/"
        // 触发保存到云空间
        public static let driveSDKsaveToSpace = "/api/box/stream/sdk/file/save/"
        // 获取预览文件地址
        public static let previewGetV2 = "/api/box/sdk/preview/get/"
        // 拼预览文件下载地址
        public static let driveFetchPreviewFileV2 = "/api/box/stream/sdk/download/preview/"
        // 分享时用的文档摘要
        public static let getShareSummary = "/api/summary/"

        // 模板中心V4
        public static let getSystemTemplate = "/api/platform/template/sys_list/"
        public static let getSystemTemplateV2 = "/api/platform/template/sys_list_v2/"
        public static let getCategoryTemplateList = "/api/platform/template/category/template_list"
        public static let getCustomTemplate = "/api/platform/template/custom_list/"
        public static let getBusinessTemplate = "/api/platform/template/co_list/"
        public static let searchTemplate = "/api/platform/template/search"
        public static let templateInfoV2 = "/api/platform/template/template_info_v2/"
        
        /// 保存为自定义模板
        public static let saveAsTemplate = "/api/obj_template/create/"
        /// 删除自定义模板
        public static let deleteDiyTemplate = "/api/obj_template/delete/"
        /// 群公告模版推荐
        public static let templateRecommendBottom = "/api/platform/template/recommend_bottom"

        public static let templateInsert = "/api/obj_template/template_insert"
        
        public static let getAggregationInfo = "/api/aggregation/obj_info/"
        
        /// 获取第三方(如 WPS) 的 access_token
        public static let thirdPartyAccessToken = "/api/box/third/access_token/"
        /// 获取第三方(如 WPS) 的 灰度策略
        public static let thirdPartyGrayStarategy = "/api/box/third/gray_strategy/"

        ///查询实体所在容器和路径
        public static let getObjPath = "/api/explorer/v2/obj/path/"
        ///查询任务进度
        public static let getTask = "/api/explorer/v2/task/"
        ///查询文件夹根目录
        public static let getRoot = "/api/explorer/root/"
        ///查询文档、文件夹新旧信息
        public static let getEntityInfo = "/api/explorer/v2/entity/info/"
        /// 容量信息查询
        public static let quotaInfo = "/api/box/quota/info/"
        /// 获取阅读记录信息
        public static let getReadRecordInfo = "/api/obj_stats/get_view_detail/"
        /// 获取用户隐私设置开关
        public static let getUserProperties = "/api/user_properties/get/"
        /// 获取Admin后台设置开关
        public static let getAdminTenantSetting = "/api/platform/ccm_setting/admin_tenant_setting/"

        /// 上传容量限制信息
        public static let uploadInfo = "/api/box/business/info"
        
        /// 查询操作记录
        public static let getOperateDetail = "/api/obj_stats/get_operate_detail/"
        /// 上报操作记录
        public static let reportOperation = "/api/obj_stats/report_operation/"
        /// 文档操作记录需求判断租户版本
        public static let getBusinessInfo = "/api/obj_stats/get_business_info/"

        /// 拉取 wiki 文件夹节点内容
        public static let getWikiCatalogList = "/api/wiki/v2/tree/get_node_child_info"
        ///查看可选密级
        public static let getSecLabelList = "/api/sec_label/visible"
        ///更新密级信息
        public static let updateSecLabel = "/api/sec_label/update"
        ///更新密集Banner
        public static let updateSecLabelBanner = "/api/sec_label/banner"
        ///查询密级降级审批定义
        public static let approvalDef = "/api/sec_label/approval/def"
        ///查询密级降级审批实例列表
        public static let approvalInstanceList = "/api/sec_label/approval/instance/list"
        ///创建密级降级审批实例
        public static let approvalInstanceCreate = "/api/sec_label/approval/instance/create"

        // MARK: - VErsion
        /// 源文档token查询版本文档token
        public static let getVersionToken = "/api/platform/version/meta/"
        /// 获取文档版本列表
        public static let getVersionData = "/api/platform/version/list/"
        /// 查询token是否是文档token
        public static let checkDocsToken = "/api/meta/"
        /// 重命名版本
        public static let renameVersion = "/api/platform/version/rename/"
        /// 删除版本
        public static let deleteVersion = "/api/platform/version/delete/"
        /// 查询版本名称
        public static let versionNameList = "/api/platform/version/name_list/"

        // MARK: - Workspace
        /// 获取 workspace ContainerInfo
        public static let getWorkspaceContainerInfo = "/api/bff/workspace/container/info"
        public static let getWorkspaceRecentOperation = "/api/bff/workspace/recent_operation"

        /// 获取通用配置
        public static let getCommonSetting = "/api/platform/common_setting/get/"
        /// 更新通用配置
        public static let updateCommonSetting = "/api/platform/common_setting/update/"

        /// dlp policystatus
        public static let dlpPolicystatus = "/lark/scs/compliance/intercept/ccm/policystatus"
        /// dlp scs
        public static let dlpScs = "/lark/scs/compliance/intercept/ccm/result"
        /// 恢复删除文档
        public static let wikiCanRestore = "/api/wiki/v2/tree/check_node_restore/"
        public static let spaceCanRestore = "/api/explorer/v2/trash/check_restore/"
        public static let wikiRestore = "/api/wiki/v2/tree/restore_node/"
        public static let spaceRestore = "/api/explorer/v2/trash/restore/"
        public static let getWikiTaskStatus = "/api/wiki/v2/task/status/"
        
        // MARK: - NewHome
        public static let getPinDocumentList = "/api/explorer/v3/pin/list/"
        public static let getNewTabShareList = "/api/explorer/v3/share/list/"

        // MARK: - 文档新鲜度
        /// 设置新鲜度
        public static let updateFreshStatus = "/api/platform/fresh_status/update"
        /// 反馈文档过期
        public static let feedbackFreshStatus = "/api/platform/fresh_status/feedback_expired"
        
        // MARK: 同步Block
        public static let getSyncBlockReference = "/api/block/reference"
        
        // MARK: - BaseHomePage
        public static let homePageRecommend = "/api/platform/template/content_recommend"
        public static let homePageDiversion = "/api/bitable/homepage/home/v1"
        public static let homePageRecommendReport = "/api/platform/template/report_data"
        
        // MARK: - HomePage Chart
        public static let homePageChart = "/api/bitable/homepage/charts"
        public static let chartSliceData = "/api/v3/sheet/blocks/chart/data"
        public static let chartInsertInDashboard = "/api/v2/sheet/blocks/dashboard/skeleton"

        // MARK: -检查同步块权限并返回同步块源文档token
        public static let syncedBlockPermission = "/api/suite/permission/synced_block/check_apply_permission"
        
        // MARK: 一事一档
        /// 检查web应用是否有关联文档AssociateApp
        public static let associateAppCheckReferenceExist = "/api/plugins"
        /// 查询关联的文档信息
        public static let associateAppAppReference = "/api/app/references"
        /// 关联已有文档
        public static let associateAppReferenceCreate = "/api/references/create"
        /// 解除关联
        public static let associateAppReferenceDelete = "/api/references/delete"
        /// 创建文档并关联 from
        public static let associateAppNewCreate = "/api/explorer/v2/create/object/"
        // MARK: - 订阅相关
        public static var getRecordSubscribeBehaviourPath: (_ baseToken: String) -> String = {//关注或者取消订阅
            return "/api/bitable/record/\($0)/subscribe"
        }
        //获取订阅状态
        public static var getRecordSubscribeStatePath: (_ baseToken: String) -> String = {
            return "/api/bitable/record/\($0)/subscribe_status"
        }
        //自动订阅操作
        public static var getRecordAutoSubscribeEditPath: (_ baseToken: String) -> String = {
            return "/api/bitable/record/\($0)/subscribe_base_edit_status"
        }
    }
    
    static func getConfigStr() -> String {
        let config: [String: Any] = [
            "privateProtocol": OpenAPI.offlineConfig.protocolEnable,
            "resourceUpdateInterval": OpenAPI.resouceUpdateInterval,
            "wifiTimeout": NetConfig.shared.timeoutConfig.wifiTimeout,
            "agenttoFrontend ": OpenAPI.docs.isSetAgentToFrontend,
            "禁用webview复用": OpenAPI.docs.disableEditorResue,
            "使用指定离线资源包?": GeckoPackageManager.shared.isUsingSpecial(.webInfo),
            "指定资源包版本号": GeckoPackageManager.shared.currentVersion(type: .webInfo),
            "gecko资源版本号": GeckoPackageManager.shared.currentVersion(type: .webInfo),
            "useGrayscalePackage fg": UserScopeNoChangeFG.HZK.useGrayscalePackage,
            "settings下发灰度包版本号": SettingConfig.grayscalePackageConfig?["version"] ?? "",
            "carrierTimeout": NetConfig.shared.timeoutConfig.carrierTimeout
        ]
        return config.description
    }
}
