//
//  ChatSecurityAuditServiceImp.swift
//  LarkMessageCore
//
//  Created by 赵家琛 on 2020/12/1.
//

import LarkModel
import Foundation
import LarkMessengerInterface
import LarkContainer
import LarkSecurityAudit
import LarkAccountInterface

public final class ChatSecurityAuditServiceImp: ChatSecurityAuditService {
    private let securityAudit: SecurityAudit
    private let currentTenantId: String
    private let currentUserID: String

    public init(currentUserID: String, tenantId: String) {
        self.securityAudit = SecurityAudit()
        self.currentTenantId = tenantId
        self.currentUserID = currentUserID
        var event = Event()
        event.operator = OperatorEntity()
        event.operator.type = .entityUserID
        event.operator.value = currentUserID
        self.securityAudit.sharedParams = event
    }

    public func auditEvent(_ eventType: ChatSecurityAuditEventType, isSecretChat: Bool) {
        /// 密聊不上报
        guard !isSecretChat else { return }

        var event = Event()
        var eventObjects: [ObjectEntity] = []
        var drawerDic: [String: String] = ["opResult": String(SecurityEvent_OpResultValue.opSuccess.rawValue)]
        switch eventType {
        case .clickLink(let url, let chatId, let chatType):
            event.module = .moduleChat
            event.operation = .operationRead
            let link = getEntity(type: .entityLink, value: url)
            if let chatId = chatId {
                let chatId = getEntity(type: .entityChatID, value: chatId)
                eventObjects.append(chatId)
            }
            if let chatType = chatType {
                let chatId = getEntity(type: .entityChatID, value: chatType.typeDescription)
                eventObjects.append(chatId)
            }
            drawerDic["link"] = url
        case .saveImage(let key):
            /// 待截断的图片品质前缀范围
            let imageQualityPrefixs = ["origin:", "middle:", "thumbnail:"]
            var fixedKey = key
            for prefix in imageQualityPrefixs {
                fixedKey = fixedKey.replacingOccurrences(of: prefix, with: "", options: .regularExpression)
            }
            event.module = .moduleImimageAndVideo
            event.operation = .operationDownload
            let objectEntity = getEntity(type: .entityImage, value: fixedKey)
            eventObjects.append(objectEntity)
        case .saveVideo(let key):
            event.module = .moduleImimageAndVideo
            event.operation = .operationDownload
            let objectEntity = getEntity(type: .entityVideoIm, value: key)
            eventObjects.append(objectEntity)
        case .downloadFile(let key):
            event.module = .moduleImfile
            event.operation = .operationDownload
            let objectEntity = getEntity(type: .entityFileIm, value: key)
            eventObjects.append(objectEntity)
        case .fileOpenedWith3rdApp(let chatId, let chatType, let fileId, let fileType, let appId):
            event.module = .moduleImfile
            event.operation = .operationOpenWith3RdApp
            drawerDic["fileID"] = fileId
            drawerDic["fileType"] = fileType
            drawerDic["chatType"] = chatType.typeDescription
            drawerDic["appId"] = appId
            let chatIdObject = getEntity(type: .entityChatID, value: chatId)
            eventObjects.append(chatIdObject)
            let objectEntity = getEntity(type: .entityFileIm, value: fileId)
            eventObjects.append(objectEntity)
        case .chatPreviewfile(let chatId, let chatType, let fileId, let fileName, let fileType):
            event.module = .moduleIm
            event.operation = .operationImchatPreviewFile
            drawerDic["fileType"] = fileType
            drawerDic["fileID"] = fileId
            drawerDic["chatType"] = chatType.typeDescription
            drawerDic["fileName"] = fileName
            let chatIdObject = getEntity(type: .entityChatID, value: chatId)
            eventObjects.append(chatIdObject)
        case .saveToSpace(let chatId, let chatType, let fileId, let fileName, let fileType):
            event.module = .moduleIm
            event.operation = .operationImsaveToSpace
            drawerDic["fileType"] = fileType
            drawerDic["fileName"] = fileName
            drawerDic["chatType"] = chatType.typeDescription
            drawerDic["fileID"] = fileId
            let chatIdObject = getEntity(type: .entityChatID, value: chatId)
            eventObjects.append(chatIdObject)
        case .copy(let chatId, let chatType, let messageType):
            event.module = .moduleIm
            event.operation = .operationCopyContent
            drawerDic["messageType"] = messageType.getStringDescription()
            drawerDic["chatType"] = chatType.typeDescription
            let chatIdObject = getEntity(type: .entityChatID, value: chatId)
            eventObjects.append(chatIdObject)
        case .chatEditImage(let chatId, let chatType, let imageKey):
            event.module = .moduleIm
            event.operation = .operationImchatEditImage
            drawerDic["chatType"] = chatType.typeDescription
            drawerDic["imageID"] = imageKey
            let chatIdObject = getEntity(type: .entityChatID, value: chatId)
            eventObjects.append(chatIdObject)
        case .ocrResult(let length, let imageKey):
            event.module = .moduleImimageAndVideo
            event.operation = .operationImocr
            let object = getEntity(type: .entityImage, value: imageKey)
            eventObjects.append(object)
            drawerDic["OcrResultLength"] = "\(length)"
        case .chatPin(type: let chatPinAuditType):
            event.module = .moduleChat
            self.setParamsForChatPin(type: chatPinAuditType, event: &event, eventObjects: &eventObjects, drawerDic: &drawerDic)
        }
        event.operator.type = .entityUserID
        event.operator.value = currentUserID
        event.objects = eventObjects
        event.extend.commonDrawer = getDrawer(dic: drawerDic)
        event.tenantID = currentTenantId
        self.securityAudit.auditEvent(event)
    }

    private func setParamsForChatPin(type: ChatPinAuditEventType, event: inout Event, eventObjects: inout [ObjectEntity], drawerDic: inout [String: String]) {
        switch type {
        case .showChatPinList(let chatId):
            event.operation = .operationChatPinShowPinList
            let object = getEntity(type: .entityChatID, value: chatId)
            eventObjects.append(object)
            drawerDic["chatId"] = chatId
        case .copyContent(chatId: let chatId, pinId: let pinId):
            event.operation = .operationChatPinCopyURL
            let chatIdOb = getEntity(type: .entityChatID, value: chatId)
            eventObjects.append(chatIdOb)
            drawerDic["chatId"] = chatId
            drawerDic["chatPinId"] = "\(pinId)"
        case .clickBackToChat(chatId: let chatId, pinId: let pinId):
            event.operation = .operationChatPinBackToChat
            let chatIdOb = getEntity(type: .entityChatID, value: chatId)
            eventObjects.append(chatIdOb)
            drawerDic["chatId"] = chatId
            drawerDic["chatPinId"] = "\(pinId)"
        case .clickOpenUrl(chatId: let chatId, pinId: let pinId):
            event.operation = .operationChatPinOpenURL
            let chatIdOb = getEntity(type: .entityChatID, value: chatId)
            eventObjects.append(chatIdOb)
            drawerDic["chatId"] = chatId
            drawerDic["chatPinId"] = "\(pinId)"
        case .showChatPinInChat(chatId: let chatId, pinIds: let pinIds):
            event.operation = .operationChatPinShowInChat
            let chatIdOb = getEntity(type: .entityChatID, value: chatId)
            eventObjects.append(chatIdOb)
            var pinIdsStr: String = ""
            for pinId in pinIds {
                pinIdsStr += "\(pinId),"
            }
            if !pinIdsStr.isEmpty {
                pinIdsStr.removeLast()//移走最后的,
            }
            drawerDic["chatId"] = chatId
            drawerDic["chatPinIds"] = pinIdsStr
        }
    }

    private func getEntity(type: SecurityEvent_EntityType, value: String) -> ObjectEntity {
        var objectEntity = ObjectEntity()
        objectEntity.type = type
        objectEntity.value = value
        return objectEntity
    }

    private func getDrawer(dic: [String: String]) -> SecurityEvent_CommonDrawer {
        var drawer = SecurityEvent_CommonDrawer()
        var renderItems: [SecurityEvent_RenderItem] = []
        for item in dic {
            var renderItem = SecurityEvent_RenderItem()
            renderItem.key = item.key
            renderItem.value = item.value
            renderItem.renderTypeValue = .plainText
            renderItems.append(renderItem)
        }
        drawer.itemList = renderItems
        return drawer
    }
}

private extension LarkModel.Chat.TypeEnum {
    var typeDescription: String {
        self == .p2P ? "p2P" : "group"
    }
}

private extension LarkModel.Message.TypeEnum {
    func getStringDescription() -> String {
        switch self {
        case .text:
            return "text"
        case .unknown:
            return "unknown"
        case .post:
            return "post"
        case .file:
            return "file"
        case .image:
            return "image"
        case .system:
            return "system"
        case .audio:
            return "audio"
        case .email:
            return "email"
        case .shareGroupChat:
            return "shareGroupChat"
        case .sticker:
            return "sticker"
        case .mergeForward:
            return "mergeForward"
        case .calendar:
            return "calendar"
        case .card:
            return "card"
        case .media:
            return "media"
        case .shareCalendarEvent:
            return "shareCalendarEvent"
        case .hongbao:
            return "hongbao"
        case .generalCalendar:
            return "generalCalendar"
        case .videoChat:
            return "videoChat"
        case .location:
            return "location"
        case .commercializedHongbao:
            return "commercializedHongbao"
        case .shareUserCard:
            return "shareUserCard"
        case .todo:
            return "todo"
        case .folder:
            return "folder"
        case .diagnose:
            return "diagnose"
        case .vote:
            return ""
        @unknown default:
            return ""
        }
    }
}
