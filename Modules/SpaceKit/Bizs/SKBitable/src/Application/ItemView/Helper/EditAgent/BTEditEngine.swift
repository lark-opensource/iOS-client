//
//  BTEditEngine.swift
//  DocsSDK
//
//  Created by Webster on 2020/5/18.
//
import SKBrowser
import Foundation
import SKCommon

/// URL 字段的修改方式
enum BTURLFieldModifyType {
    /// 编辑 textView 的方法来修改
    ///  - aText: 当前富文本
    ///  - link: 原先的链接
    ///  - finish: 是否收起键盘结束输入
    case editAtext(aText: NSAttributedString, link: String, finish: Bool)
    /// 编辑超链接面板的的方法来修改
    case editBoard(segment: BTRichTextSegmentModel)
}

protocol BTEditEngine: AnyObject {
    /// js执行
    var dataService: BTDataService? { get }

    /// 用户更新多行文本
    /// - Parameters:
    ///   - fieldID: field id
    ///   - attText: 当前富文本
    ///   - finish: 是否收起键盘结束输入
    func didModifyText(fieldID: String, attText: NSAttributedString, finish: Bool, editType: BTTextEditType?)
    
    /// 用户更新 URL 内容
    /// - Parameters:
    ///   - fieldID: field id
    ///   - modifyType: 修改方式
    func didModifyURLContent(fieldID: String, modifyType: BTURLFieldModifyType)
    
    /// 没有改动文本，关闭编辑
    /// - Parameter fieldID: field id
    func didFinishEditingWithoutModify(fieldID: String)

    /// 用户结束当前多行文本的编辑·
    /// - Parameter fieldID: field id
    func didEndModifyingText(fieldID: String)

    /// 用户结束日期选择
    func didFinishPickingDate(fieldID: String, date: Date?, trackInfo: BTTrackInfo)

    /// 用户点击某个选项（单选、多选字段都走这个）
    func optionSelectionChanged(fieldID: String, options: [BTCapsuleModel], isSingleSelect: Bool, trackInfo: BTTrackInfo)

    /// bitable事件上报
    func trackEvent(eventType: String, params: [String: Any])

    /// 用户更新选中的成员
    func didSelectUsers(fieldID: String, users: [BTUserModel], trackInfo: BTTrackInfo)
    /// 用户更新选中群或者其他chatter类型，
    /// BTChatterInfo { type: BTChatterType,
    /// chatters: [BTChatterModel],
    /// currentChatter: BTChatterModel? }
    func didSelectChatters(with fieldID: String,
                           chatterInfo: BTSelectChatterInfo,
                           trackInfo: BTTrackInfo,
                           noUpdateChatterData: Bool,
                           completion: ((BTChatterProtocol?, Error?) -> Void)?)
    
    func trackBitableEvent(eventType: String, params: [String: Any])
    
    func quickAddViewClick(fieldID: String)

    /// 用户删除附件
    func deleteAttachment(data: BTAttachmentModel, inFieldWithID: String)

    /// 用户上传附件（本地图片和视频）
    func didUploadAttachment(fieldID: String, data: [BTAttachmentModel])

    /// 用户更新 checkbox 值
    func didUpdateCheckbox(inFieldWithID: String, toStatus: Bool)

    /// 用户在关联面板里更新关联关系（增删关联记录，采用 cover 类型）
    func updateLinkedRecords(fieldID: String, linkedRecordIDs: [String], recordTitles: [String: String])

    /// 用户在关联面板里新建关联记录
    func addNewLinkedRecord(fromLocation: BTFieldLocation, toLocation: BTFieldLocation, value: [BTRichTextSegmentModel]?, resultHandler: ((Result<Any?, Error>) -> Void)?)

    /// 用户在关联字段里取消关联记录（逐条删除关联，采用 delete 类型）
    func cancelLinkage(fromFieldID: String, toRecordID: String)

    /// 用户点击删除记录
    func deleteRecord(recordID: String)

    ///修改数字字段
    func didModifyNumberField(fieldID: String, value: Double?, didClickDone: Bool)
    
    ///修改数字字段文本（编辑过程中）
    func didUpdateNumberField(fieldID: String, draft: String?)
    
    /// 修改电话号码字段
    func didModifyPhoneField(fieldID: String, value: BTPhoneModel, isFinish: Bool)

    ///用户在选择面板选择通知
    func saveNotifyStrategy(notifiesEnabled: Bool)

    ///获取当前文档上次用户通知选择，默认是true
    func obtainLastNotifyStrategy() -> Bool
    
    ///前端执行native请求
    func executeCommands(command: BTCommands,
                         field: BTFieldCellProtocol?,
                         property: Any?,
                         extraParams: Any?,
                         resultHandler: @escaping (BTExecuteFailReson?, Error?) -> Void)
    /// 获取字段权限
    func getPermissionData(entity: String,
                           operation: OperationType,
                           recordID: String?,
                           fieldIDs: [String]?,
                           resultHandler: @escaping (Any?, Error?) -> Void)

    /// 获取属性
    func getBitableCommonData(type: BTEventType,
                              fieldID: String,
                              extraParams: [String: Any]?,
                              resultHandler: @escaping (Any?, Error?) -> Void)

    /// 异步请求前端数据
    func asyncJsRequest(router: BTAsyncRequestRouter,
                        data: [String: Any]?,
                        overTimeInterval: Double?,
                        responseHandler: @escaping(Result<BTAsyncResponseModel, BTAsyncRequestError>) -> Void,
                        resultHandler: ((Result<Any?, Error>) -> Void)?)
}


enum BTCardFetchType: Hashable {
    case initialize(_ isBitableReady: Bool)       // 初始化全部卡片的 meta 和 data,tableReady走原来的拉是一条流程，如果不是拉取单条，ready后更新
    case update           // 刷新全部卡片的 meta 和 data
    case onlyData         // 只拉取全部卡片的 data，不拉 meta
    case left             // 拉取当前卡片左边的卡片们
    case right            // 拉取当前卡片右边的卡片们
    case filteredOnlyOne  // 只拉取一张卡片的 meta 和 data，只在被筛选的情形用
    case bitableReady     // bitableReady后需要拉取前后5条数据
    case linkCardInitialize //关联面板记录初始化
    case linkCardSearch //关联面板记录搜索
    case linkCardUpdate //关联面板记录协同更新，更新meta和data
    case linkCardOnlyData //关联面板记录协同更新，只更新data不更新meta
    case linkCardTop //关联面板记录拉取上方数据
    case linkCardBottom //关联面板记录拉取下方数据

    func offset(fromCurrentIndex currentIndex: Int, currentCount: Int) -> Int {
        switch self {
        case .initialize(let bitableIsReady):
            return bitableIsReady ? 5 : 0
        case .update, .onlyData:
            return 5
        case .left:
            return currentIndex == -1 ? 5 : 5 + BTViewModelConst.preloadOffset
        case .right:
            return currentIndex == -1 ? 5 : 0
        case .filteredOnlyOne:
            return 0
        case .bitableReady:
            return 5
        case .linkCardInitialize, .linkCardSearch:
            return 0
        case .linkCardUpdate, .linkCardOnlyData:
            return 10
        case .linkCardTop:
            return 10
        case .linkCardBottom:
            return 0
        }
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.update, .update):
            return true
        case (.initialize(_), .initialize(_)):
            return true
        case (.onlyData, .onlyData):
            return true
        case (.left, .left):
            return true
        case (.right, .right):
            return true
        case (.filteredOnlyOne, .filteredOnlyOne):
            return true
        case (.bitableReady, .bitableReady):
            return true
        case (.linkCardInitialize, .linkCardInitialize):
            return true
        case (.linkCardSearch, .linkCardSearch):
            return true
        case (.linkCardUpdate, .linkCardUpdate):
            return true
        case (.linkCardOnlyData, .linkCardOnlyData):
            return true
        case (.linkCardTop, .linkCardTop):
            return true
        case (.linkCardBottom, .linkCardBottom):
            return true
        default:
            return false
        }
    }

    func preloadSize(currentCount: Int) -> Int {
        switch self {
        case .initialize(let bitableIsReady):
            return bitableIsReady ? 11 : 1
        case .update, .onlyData:
            return 11
        case .left:
            return currentCount == 0 ? 11 : 6
        case .right:
            return currentCount == 0 ? 11 : 6 + BTViewModelConst.preloadOffset
        case .filteredOnlyOne:
            return 1
        case .bitableReady:
            return 11
        case .linkCardInitialize, .linkCardSearch:
            return 21
        case .linkCardUpdate, .linkCardOnlyData:
            return currentCount + 2 * 10
        case .linkCardTop:
            return 11
        case .linkCardBottom:
            return 11
        }
    }
}
