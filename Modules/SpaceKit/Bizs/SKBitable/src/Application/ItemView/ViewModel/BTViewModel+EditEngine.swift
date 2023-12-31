//
//  BTViewModel+CardEditEngine.swift
//  DocsSDK
//
//  Created by linxin on 2020/3/26.
//


import UIKit
import SKBrowser
import SKCommon
import SKFoundation
import LarkRustClient
import RustPB
import LarkReleaseConfig
import RxSwift
import ServerPB
import SKInfra

extension BTViewModel: BTEditEngine {
    
    /// 用户更新多行文本
    /// - Parameters:
    ///   - fieldID: field id
    ///   - attText: 当前富文本
    ///   - finish: 是否收起键盘结束输入
    func didModifyText(fieldID: String, attText: NSAttributedString, finish: Bool, editType: BTTextEditType?) {
        guard shouldAllowSubmit(of: fieldID) else {
            return
        }
        var segments = BTRichTextSegmentModel.segmentsWithAttributedString(attrString: attText)
        segments = segments.map { _item in
            var item = _item
            item.editType = editType
            // 历史遗留问题，多行文本调起at面板选择人员后缺少name字段，对转人员需求产生影响
            if item.mentionType == .user {
                var text = item.text
                let at = "@"
                if text.starts(with: at) {
                    text.removeFirst()
                    item.name = text
                }
            }
            return item
        }
        tableModel.update(textSegments: segments, forRecordID: currentRecordID, fieldID: fieldID)
        notifyModelUpdate()
        if finish {
            let trackInfo = BTTrackInfo()
            trackInfo.didClickDone = finish
            makeTrack(type: .text, trackInfo: trackInfo)
            jsModifyField(withID: fieldID, value: segments.toJSON())
        }
    }
    
    func didModifyURLContent(fieldID: String, modifyType: BTURLFieldModifyType) {
        guard shouldAllowSubmit(of: fieldID) else {
            return
        }
        var finish = false
        var segments = [BTRichTextSegmentModel]()
        switch modifyType {
        case let .editAtext(aText, link, _finish):
            /// 需要在这里做处理。
            segments = BTRichTextSegmentModel.segmentsWithAttributedString(attrString: aText)
            if _finish {
                if let segment = BTRichTextSegmentModel.getRealSegmentsForURLField(from: segments, originalLink: link) {
                    segments = [segment]
                } else {
                    segments = []
                }
            }
            finish = _finish
        case let .editBoard(segment):
            segments = [segment]
            finish = true
        }
        tableModel.update(textSegments: segments, forRecordID: currentRecordID, fieldID: fieldID)
        notifyModelUpdate()
        if finish {
            jsModifyField(withID: fieldID, value: segments.toJSON())
        }
    }
    
    func didFinishEditingWithoutModify(fieldID: String) {
        constructCardRequest(.onlyData)
    }

    /// 用户结束当前多行文本的编辑·
    /// - Parameter fieldID: field id
    func didEndModifyingText(fieldID: String) {

    }

    /// 用户结束日期选择
    func didFinishPickingDate(fieldID: String, date: Date?, trackInfo: BTTrackInfo) {
        if let tDate = date {
            makeTrack(type: .dateTime, trackInfo: trackInfo)
            let interval = tDate.timeIntervalSince1970 * 1000
            jsModifyField(withID: fieldID, value: interval)
        } else {
            //清空传递nil
            jsModifyField(withID: fieldID, value: nil)
        }
    }

    func deleteAttachment(data: BTAttachmentModel, inFieldWithID fieldID: String) {
        jsModifyField(withID: fieldID, editType: .delete, value: [data.toJSON()])
    }

    func didUploadAttachment(fieldID: String, data: [BTAttachmentModel]) {
        jsModifyField(withID: fieldID, editType: .add, value: data.toJSON())
    }

    func didUpdateCheckbox(inFieldWithID fieldID: String, toStatus status: Bool) {
        jsModifyField(withID: fieldID, value: status)
    }

    /// 用户点击某个选项
    func optionSelectionChanged(fieldID: String, options: [BTCapsuleModel], isSingleSelect: Bool, trackInfo: BTTrackInfo) {
        makeTrack(type: .dateTime, trackInfo: trackInfo)
        trackBitableEvent(eventType: DocsTracker.EventType.bitableOptionFieldPanelClick.rawValue,
                          params: ["click": "select_option",
                                   "target": "none",
                                   "isSingle": isSingleSelect ? "single_option" : "multi_option"])
//        trackOptionFieldClickEvent(type: "select_option", fieldIsSingle: isSingleSelect)
        let allIdentifiers = options.map { return $0.id }
        if mode == .addRecord {
            let dataArray = options.map { model in
                (model.id, BTOptionModel(id: model.id, name: model.text, color: model.color.id))
            }
            dataService?.holdDataProvider?.setDynamicOptionsFieldData(filedId: fieldID, data: Dictionary(uniqueKeysWithValues: dataArray))
        }
        if isSingleSelect {
            if allIdentifiers.count > 0 {
                jsModifyField(withID: fieldID, value: allIdentifiers[0])
            } else {
                jsModifyField(withID: fieldID, value: nil)
            }
        } else {
            if allIdentifiers.count > 0 {
                jsModifyField(withID: fieldID, value: allIdentifiers)
            } else {
                jsModifyField(withID: fieldID, value: nil)
            }
        }
    }

//    func trackOptionPanelClickSearchEvent(type: String, target: String, isSingleSelect: Bool) {
//        trackOptionFieldClickEvent(type: type, target: target, fieldIsSingle: isSingleSelect)
//    }
//
//    func trackOpenOptionPanelEvent() {
//        trackOptionPanelOpenEvent()
//    }

    func trackEvent(eventType: String, params: [String: Any]) {
        trackBitableEvent(eventType: eventType, params: params)
    }

    func didSelectUsers(fieldID: String, users: [BTUserModel], trackInfo: BTTrackInfo) {
        makeTrack(type: .dateTime, trackInfo: trackInfo)
        let data = users.isEmpty ? nil : ["users": users.toJSON()]
        jsModifyField(withID: fieldID, value: data)
    }
    
    func didSelectChatters(with fieldID: String,
                           chatterInfo: BTSelectChatterInfo,
                           trackInfo: BTTrackInfo,
                           noUpdateChatterData: Bool,
                           completion: ((BTChatterProtocol?, Error?) -> Void)?)  {
        let upload: ([BTChatterProtocol], String) -> Void = { chatters, type in
            if noUpdateChatterData {
                return
            }
            var chatters = chatters
            if UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel {
                chatters = chatters.map({ chatter in
                    if var chatterGroup = chatter as? BTGroupModel {
                        if chatterGroup.linkToken.isEmpty {
                            if let token = Self.chatterIDTokenMap[chatterGroup.chatterId] {
                                chatterGroup.linkToken = token
                            }
                        }
                        return chatterGroup
                    } else {
                        return chatter
                    }
                })
            }
            let data = chatters.isEmpty ? nil : [type: chatters.compactMap({ $0.toDictionary() })]
            self.jsModifyField(withID: fieldID, value: data)
        }
        let key: String
        switch chatterInfo.type {
        case .group:
            key = "groups"
            makeTrack(type: .group, trackInfo: trackInfo)
        case .user:
            key = "users"
            makeTrack(type: .user, trackInfo: trackInfo)
        }
        // chatters为空的时候 == currentChatter必然为nil
        if let currentChatter = chatterInfo.currentChatter as? BTGroupModel {
            fetchShareLinkToken(with: currentChatter.chatterId).subscribe(onNext: { token in
                var tokenChatter = currentChatter
                tokenChatter.linkToken = token
                Self.chatterIDTokenMap[currentChatter.chatterId] = token
                // 更新获取了token的chatter
                completion?(tokenChatter, nil)
                let tokenChatters = chatterInfo.chatters.map({ noTokenChatter in
                    if tokenChatter.chatterId == noTokenChatter.chatterId {
                        return tokenChatter
                    }
                    return noTokenChatter as? BTGroupModel ?? BTGroupModel()
                })
                upload(tokenChatters, key)
            }, onError: { error in
                // 换取失败直接上传了
                completion?(currentChatter, error)
                upload(chatterInfo.chatters, key)
                DocsLogger.btError("[BTViewModel] fetchShareLinkToken failed: \(error)")
            }).disposed(by: self.disposeBag)
        } else {
            completion?(chatterInfo.currentChatter, nil)
            upload(chatterInfo.chatters, key)
        }
        
    }

    func updateLinkedRecords(fieldID: String, linkedRecordIDs: [String], recordTitles: [String: String]) {
        dataService?.holdDataProvider?.setLinkFieldData(filedId: fieldID, recordTitles: recordTitles) // 对于记录新建，前端没有关联表数据，需要本地持有关联表标题数据
        jsModifyField(withID: fieldID, editType: .cover, value: linkedRecordIDs)
    }

    func addNewLinkedRecord(fromLocation: BTFieldLocation, toLocation: BTFieldLocation, value: [BTRichTextSegmentModel]?, resultHandler: ((Result<Any?, Error>) -> Void)?) {
        jsCreateAndLinkNewRecord(sourceLocation: fromLocation, targetLocation: toLocation, value: value?.toJSON(), resultHandler: resultHandler)
    }

    func cancelLinkage(fromFieldID: String, toRecordID: String) {
        jsModifyField(withID: fromFieldID, editType: .delete, value: [toRecordID])
    }

    /// 删除操作
    func deleteRecord(recordID: String) {
        jsDeleteRecord(recordID: recordID)
    }
    
    func didUpdateNumberField(fieldID: String, draft: String?) {
        tableModel.update(numberValueDraft: draft, recordID: currentRecordID, fieldID: fieldID)
        notifyModelUpdate()
    }

    func didModifyNumberField(fieldID: String, value: Double?, didClickDone: Bool) {
        let trackInfo = BTTrackInfo()
        trackInfo.didClickDone = didClickDone
        makeTrack(type: .number, trackInfo: trackInfo)
        jsModifyField(withID: fieldID, value: value)
    }
    
    func didModifyPhoneField(fieldID: String, value: BTPhoneModel, isFinish: Bool) {
        guard let currentEditingRecord = tableModel.getRecordModel(id: currentRecordID),
              currentEditingRecord.editable,
              let currentEditingField = currentEditingRecord.getFieldModel(id: fieldID),
              currentEditingField.editable
        else {
            DocsLogger.btInfo("==phone== has no \(currentRecordID) and \(fieldID) edit permission，not allow submit phone changeset")
            return
        }
        tableModel.update(phoneValues: [value], forRecordID: currentRecordID, fieldID: fieldID)
        notifyModelUpdate()
        if isFinish {
            makeTrack(type: .phone, trackInfo: BTTrackInfo())
            var result = value.toJSON()
            if value.fullPhoneNum.isEmpty {
                result = nil
            }
            DocsLogger.debug("==phone== didModifyPhoneField value: \(result)")
            jsModifyField(withID: fieldID, value: result)
        }
    }

    ///用户在选择面板选择通知
    func saveNotifyStrategy(notifiesEnabled: Bool) {
        dataService?.saveNotifyStrategy(notifiesEnabled: notifiesEnabled)
    }

    ///获取当前文档上次用户选择
    func obtainLastNotifyStrategy() -> Bool {
        return dataService?.obtainLastNotifyStrategy() ?? false
    }

    //前端执行native请求
    func executeCommands(command: BTCommands,
                         field: BTFieldCellProtocol?,
                         property: Any?,
                         extraParams: Any?,
                         resultHandler: @escaping (BTExecuteFailReson?, Error?) -> Void) {
        jsExecuteCommands(command: command,
                          field: field,
                          property: property,
                          extraParams: extraParams,
                          resultHandler: resultHandler)
    }

    //请求字段权限
    func getPermissionData(entity: String,
                           operation: OperationType,
                           recordID: String?,
                           fieldIDs: [String]?,
                           resultHandler: @escaping (Any?, Error?) -> Void) {
        jsGetPermission(entity: entity,
                        operation: operation,
                        recordID: recordID,
                        fieldIDs: fieldIDs,
                        resultHandler: resultHandler)
    }

    //获取bitable公共数据
    func getBitableCommonData(type: BTEventType,
                              fieldID: String,
                              extraParams: [String: Any]?,
                              resultHandler: @escaping (Any?, Error?) -> Void) {
        jsGetBitableCommonData(type: type,
                               fieldID: fieldID,
                               extraParams: extraParams,
                               resultHandler: resultHandler)
    }

    func asyncJsRequest(router: BTAsyncRequestRouter,
                        data: [String: Any]?,
                        overTimeInterval: Double?,
                        responseHandler: @escaping(Result<BTAsyncResponseModel, BTAsyncRequestError>) -> Void,
                        resultHandler: ((Result<Any?, Error>) -> Void)?) {
        jsAsyncRequest(router: router,
                       data: data,
                       overTimeInterval: overTimeInterval,
                       responseHandler: responseHandler,
                       resultHandler: resultHandler)
    }
    
    
    private func shouldAllowSubmit(of fieldID: String) -> Bool {
        guard let currentEditingRecord = tableModel.getRecordModel(id: currentRecordID), currentEditingRecord.editable,
              let currentEditingField = currentEditingRecord.getFieldModel(id: fieldID), currentEditingField.editable else {
            DocsLogger.btInfo("[SYNC] has no \(currentRecordID) and \(fieldID) edit permission，not allow submit changeset")
            return false
        }
        return true
    }
    
    // 根据chatID获取群分享token
    func fetchShareLinkToken(with chatID: String) -> Observable<String> {
        let isOversea: Bool = (ReleaseConfig.releaseChannel == "Oversea")
        guard let rustService = DocsContainer.shared.resolve(RustService.self) else {
            DocsLogger.btError("获取rustClient失败")
            return Observable.create {
                $0.onError(RCError.sdkError)
                return Disposables.create()
            }
        }
        var request = ServerPB_Chats_PullChatLinkTokenRequest()
        request.chatID = chatID
        request.isUnlimited = true
        request.appName = isOversea ? "Lark" : "Feishu"
        let res: Observable<RustPB.Im_V1_GetChatLinkTokenResponse> = rustService.sendPassThroughAsyncRequest(request, serCommand: .pullChatLinkToken)
        let token: Observable<String> = res.map { (response) -> String in
            return response.shareToken
        }
        return token
    }
}
