//
//  WikiInteractionHandler+Create.swift
//  SKWikiV2
//
//  Created by Weston Wu on 2022/7/28.
//

import Foundation
import SKFoundation
import SKCommon
import RxSwift
import SpaceInterface
import SKInfra
import SwiftyJSON

extension DocsType {
    var offlineCreateInWikiEnable: Bool {
        switch self {
        case .docX, .sheet, .mindnote:
            return true
        default:
            return false
        }
    }
}

// 创建节点相关逻辑
extension WikiInteractionHandler {
    public enum CreateType: Equatable {
        case document(type: DocsType, template: TemplateModel? = nil)
        // 上传图片 or 文件
        case upload(isImage: Bool)
    }
    typealias CreateEnableChecker = (CreateType) -> Bool
    typealias CreatePickerHandler = (CreateType) -> Void

    // 为单测抽出来使用
    struct CreateConfig {
        let docxEnable: Bool
        let mindnoteEnable: Bool
        let bitableEnable: Bool
        let createDocEnable: Bool
        let bitableSurveyEnable: Bool

        static var fg: CreateConfig {
            CreateConfig(docxEnable: LKFeatureGating.createDocXEnable,
                         mindnoteEnable: LKFeatureGating.mindnoteEnable,
                         bitableEnable: LKFeatureGating.bitableEnable,
                         createDocEnable: !UserScopeNoChangeFG.LJY.disableCreateDoc,
                         bitableSurveyEnable: UserScopeNoChangeFG.PXR.baseWikiSpaceHasSurveyEnable)
        }
    }

    func makeCreatePicker(enableChecker: CreateEnableChecker,
                          handler: @escaping CreatePickerHandler) -> WikiCreateViewController {
        let items = Self.createItems(enableChecker: enableChecker, completion: handler)
        let controller = WikiCreateViewController(items: items)
        return controller
    }

    func updateCreatePicker(picker: WikiCreateViewController,
                            enableChecker: CreateEnableChecker,
                            handler: @escaping CreatePickerHandler) {
        let items = Self.createItems(enableChecker: enableChecker, completion: handler)
        picker.update(items: items)
    }
    
    private func generateFakeTokenFor() -> String {
        let ownerType = SettingConfig.singleContainerEnable ? singleContainerOwnerTypeValue : defaultOwnerType
        let userId = User.current.info?.userID ?? ""
        let fakeToken = "fake_" + userId + "_W_" + Int64(Date().timeIntervalSince1970 * 1000).description + "_ownerType" + ownerType.description
        return fakeToken
    }

    // 返回新建的节点，如果在 shortcut 上创建，还会返回 shortcut 本体的节点
    public func confirmCreate(meta: WikiTreeNodeMeta,
                              template: TemplateModel? = nil,
                              type: DocsType,
                              allowOfflineCreate: Bool = true) -> Single<(WikiServerNode, WikiServerNode?)> {
        if meta.originIsExternal {
            DocsLogger.error("cannot create node on external shortcut")
            spaceAssertionFailure("cannot create node on external shortcut")
        }

        let offlineCreateEnable: Bool = {
            guard allowOfflineCreate else { return false }
            guard meta.spaceID == MyLibrarySpaceIdCache.get(),
                  meta.nodeType == .mainRoot else {
                // 文档库根目录支持离线创建
                return false
            }
            if DocsNetStateMonitor.shared.isReachable {
                // 有网时还需要判断 FG、类型是否支持离线创建
                guard type.offlineCreateInWikiEnable else {
                    return false
                }
                return true
            } else {
                return type.offlineCreateInWikiEnable
            }
        }()
        if offlineCreateEnable {
            let fakeToken = generateFakeTokenFor()
            let fakeMeta = WikiTreeNodeMeta(wikiToken: fakeToken, spaceId: meta.spaceID, objToken: fakeToken, docsType: type, title: "")
            let fakeNode = WikiServerNode(meta: fakeMeta, sortID: Double.greatestFiniteMagnitude, parent: meta.wikiToken)
            
            // 添加到spaceDB
            let nodeToken = fakeToken
            let curTime = Date().timeIntervalSince1970
            let userId = User.current.info?.userID ?? ""
            let nodeInfo: [String: Any] = ["name": fakeMeta.title,
                                           "obj_token": fakeToken,
                                           "token": nodeToken,
                                           "create_uid": userId,
                                           "owner_id": userId,
                                           "edit_uid": userId,
                                           // 如果有兼容问题需要转Int64, 请在NodeTable和Nodel 一起转
                                           "edit_time": curTime,
                                           "add_time": curTime,
                                           "create_time": curTime,
                                           "open_time": curTime,
                                           "activity_time": curTime,
                                           "my_edit_time": curTime,
                                           "parent": "",
                                           "type": DocsType.wiki.rawValue,
                                           "node_type": 0]
            let extra: [String: Any] = ["wiki_subtype": type.rawValue, "wiki_sub_token": fakeToken, "wiki_space_id": MyLibrarySpaceIdCache.get() ?? ""]
            
            let fakeEntry = WikiEntry(type: .wiki, nodeToken: fakeToken, objToken: fakeToken)
            fakeEntry.updatePropertiesFrom(JSON(nodeInfo))
            fakeEntry.updateExtraValue(extra)
            fakeEntry.updateOwnerType(singleContainerOwnerTypeValue)
            let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self)
            dataCenterAPI?.insert(fakeEntry: fakeEntry, folderToken: "")
            // 对于离线新建的，必须要同步
            if  DocsNetStateMonitor.shared.isReachable == false {
                dataCenterAPI?.updateNeedSyncState(objToken: fakeToken, type: .wiki, needSync: true, completion: nil)
            }
            
            return .just((fakeNode, nil))
        }
        
        let spaceID = meta.originSpaceID ?? meta.spaceID
        let parentToken = meta.originWikiToken ?? meta.wikiToken
        let createResponse = networkAPI.createNode(spaceID: spaceID,
                                                   parentWikiToken: parentToken,
                                                   template: template,
                                                   objType: type,
                                                   synergyUUID: synergyUUID)
        if meta.isShortcut {
            let metaResponse = networkAPI.getNodeMetaInfo(wikiToken: parentToken)
            return Single.zip(createResponse, metaResponse).map { ($0, $1) }
        } else {
            return createResponse.map { ($0, nil) }
        }
    }

    static func createItems(enableChecker: CreateEnableChecker,
                            config: CreateConfig = .fg,
                            completion: @escaping CreatePickerHandler) -> [WikiCreateItem] {
        var items: [WikiCreateItem] = []

        let docType = CreateType.document(type: .doc)
        let docItem = WikiCreateItem.docs(enable: enableChecker(docType)) {
            completion(docType)
        }

        let wikiDocXCreateEnable = config.docxEnable
        if wikiDocXCreateEnable {
            let docXType = CreateType.document(type: .docX)
            items.append(.docX(enable: enableChecker(docXType)) {
                completion(docXType)
            })
        } else {
            items.append(docItem)
        }

        let sheetType = CreateType.document(type: .sheet)
        let sheetItem = WikiCreateItem.sheet(enable: enableChecker(sheetType)) {
            completion(sheetType)
        }
        items.append(sheetItem)

        if config.bitableSurveyEnable, let template = TemplateModel.createBlankSurvey(templateSource: .wikiHomepageLarkSurvey) {
            ///多维表格
            if config.bitableEnable {
                let bitableType = CreateType.document(type: .bitable)
                let bitableItem = WikiCreateItem.bitable(enable: enableChecker(bitableType)) {
                    completion(bitableType)
                }
                items.append(bitableItem)
            }
            ///问卷
            let bitableType = CreateType.document(type: .bitable, template:template)
            let surveyItem = WikiCreateItem.bitableSurvey(enable: enableChecker(bitableType)) {
                completion(bitableType)
            }
            items.append(surveyItem)
            ///思维笔记
            if config.mindnoteEnable {
                let mindnoteType = CreateType.document(type: .mindnote)
                let mindnoteItem = WikiCreateItem.mindnote(enable: enableChecker(mindnoteType)) {
                    completion(mindnoteType)
                }
                items.append(mindnoteItem)
            }
        } else {
            ///思维笔记
            if config.mindnoteEnable {
                let mindnoteType = CreateType.document(type: .mindnote)
                let mindnoteItem = WikiCreateItem.mindnote(enable: enableChecker(mindnoteType)) {
                    completion(mindnoteType)
                }
                items.append(mindnoteItem)
            }
            ///多维表格
            if config.bitableEnable {
                let bitableType = CreateType.document(type: .bitable)
                let bitableItem = WikiCreateItem.bitable(enable: enableChecker(bitableType)) {
                    completion(bitableType)
                }
                items.append(bitableItem)
            }
        }
        
        if config.createDocEnable, wikiDocXCreateEnable {
            items.append(docItem)
        }

        let uploadImageType = CreateType.upload(isImage: true)
        let uploadImageItem = WikiCreateItem.uploadImage(enable: enableChecker(uploadImageType)) {
            completion(uploadImageType)
        }
        items.append(uploadImageItem)

        let uploadFileType = CreateType.upload(isImage: false)
        let uploadFileItem = WikiCreateItem.uploadFile(enable: enableChecker(uploadFileType)) {
            completion(uploadFileType)
        }
        items.append(uploadFileItem)
        return items
    }
}
