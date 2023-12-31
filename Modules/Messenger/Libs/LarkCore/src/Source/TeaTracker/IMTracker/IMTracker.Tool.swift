//
//  IMTracker.Tool.swift
//  LarkMessageCore
//
//  Created by 李勇 on 2021/5/10.
//

import Foundation
import LarkModel
import LarkAccountInterface
import LarkFeatureGating
import RustPB
import LKCommonsTracker
import LarkMessengerInterface

/// 此处存放一些基本参数如chat_type、message_type等的生成逻辑，Messenger里各业务埋点用到这些参数的都统一从此处获取
public extension IMTracker {
    struct Base {
        public static func chatType(_ chat: LarkModel.Chat) -> String {
            // 单聊
            if chat.type == .p2P { return "single" }
            // 话题群
            if chat.chatMode == .threadV2 { return "topic" }
            // 群聊
            return "group"
        }

        public static func memberType(_ chat: LarkModel.Chat) -> String {
            /// 单聊
            if chat.type == .p2P { return "normal_member" }
            // 群主
            if chat.ownerId == AccountServiceAdapter.shared.currentChatterId { return "group_owner" }  // TODO: 用户隔离: 外部的传递链太广了，等改完了再来清理
            // 管理员
            if chat.isGroupAdmin { return "group_admin" }
            // 机器人
            if chat.chatter?.type == .bot { return "bot" }
            // 普通成员
            return "normal_member"
        }

        public static func chatTypeDetail(_ chat: LarkModel.Chat) -> String {
            if chat.type == .p2P {
                if chat.chatterId == AccountServiceAdapter.shared.currentChatterId { // TODO: 用户隔离: 外部的传递链太广了，等改完了再来清理
                    // 和自己单聊
                    return "to_myself_single"
                } else if chat.isSingleBot {
                    // bot单聊
                    return "single_bot"
                } else if chat.isP2PAi {
                    // MyAI单聊
                    return "single_ai"
                }
                // 普通单聊
                return "single_normal"
            }
            // 和自己群聊
            if chat.type == .group, chat.userCount == 1 { return "to_myself_group" }
            // 值班群
            if chat.isOncall { return "on_call" }
            // 会议群
            if chat.isMeeting { return "meeting" }
            // 部门群
            if chat.isDepartment { return "department" }
            // 话题群
            if chat.chatMode == .threadV2 { return "topic" }
            // 客服群
            if chat.isCustomerService { return "customer_service" }
            // 全员群
            if chat.isTenant { return "all_staff" }
            // 普通群
            return "classic"
        }

        public static func messageType(_ type: LarkModel.Message.TypeEnum) -> String {
            switch type {
            case .post: return "post"
            case .file: return "file"
            case .text: return "text"
            case .image: return "image"
            case .system: return "system"
            case .audio: return "audio"
            case .email: return "email"
            case .shareGroupChat: return "shareGroupChat"
            case .sticker: return "sticker"
            case .mergeForward: return "mergeForward"
            case .calendar: return "calendar"
            case .card: return "card"
            case .media: return "media"
            case .shareCalendarEvent: return "shareCalendarEvent"
            case .hongbao: return "hongbao"
            case .generalCalendar: return "generalCalendar"
            case .videoChat: return "videoChat"
            case .location: return "location"
            case .commercializedHongbao: return "commercializedHongbao"
            case .shareUserCard: return "shareUserCard"
            case .todo: return "todo"
            case .folder: return "folder"
            case .vote: return "vote"
            @unknown default: break
            }

            return "unknown"
        }

        public static func messageType(_ message: LarkModel.Message) -> String {
            return IMTracker.Base.messageType(message.type)
        }
    }
}

/// 新方案里有的Event需要上传msg_id、chat_id等Message、Chat相关属性，并且这些Event要求上传的属性都一样
/// 所以此处封装了Message、Chat等Messenger业务方相关属性构造方法，方便大家使用
public extension IMTracker {
    struct Param {
        /// doc：是否需要添加doc相关属性
        public static func message(_ msg: LarkModel.Message,
                                   doc: Bool = false,
                                   docUrl: String = "") -> [AnyHashable: Any] {
            var params: [AnyHashable: Any] = [:]
            params["msg_id"] = msg.id
            params["cid"] = msg.cid
            params["msg_type"] = IMTracker.Base.messageType(msg)
            if doc {
                if docUrl.isEmpty {
                    params += IMTracker.Param.doc(msg)
                } else {
                    params += IMTracker.Param.docWithUrl(docUrl, msg)
                }
            }
            return params
        }

        // 特化获取某一个url的doc打点参数
        // 添加doc参数：is_single_doc file_id file_type
        private static func docWithUrl(_ url: String, _ msg: LarkModel.Message) -> [AnyHashable: Any] {
            // 是否有Doc内容
            if let docEntity = (msg.content as? TextContent)?.docEntity ?? (msg.content as? PostContent)?.docEntity {
                var fileToken: String = ""
                var fileTokens: [String] = []
                var fileType: String = ""

                docEntity.elementEntityRef.values.forEach { entity in
                    fileTokens.append(entity.token)
                    if url == entity.docURL {
                        fileToken = entity.token
                        switch entity.docType {
                        case .doc:
                            fileType = "doc"
                        case .sheet:
                            fileType = "sheet"
                        case .mindnote:
                            fileType = "mindnote"
                        case .docx:
                            fileType = "docx"
                        case .bitable:
                            fileType = "bitable"
                        case .slide:
                            fileType = "slide"
                        case .slides:
                            fileType = "slides"
                        case .file:
                            fileType = "file"
                        case .unknown, .wiki:
                            fileType = "others"
                        case .folder, .catalog, .shortcut:
                            fileType = "others" // FIXME: use unknown default setting to fix warning
                        @unknown default:
                            fileType = "others"
                        }
                    }
                }

                if fileType.isEmpty || fileToken.isEmpty {
                    return ["file_id": "none", "file_type": "none", "is_single_doc": "false"]
                }

                let isSingleDoc: Bool = (fileTokens.count == 1)
                return ["file_id": fileToken, "file_type": fileType, "is_single_doc": isSingleDoc ? "true" : "false"]
            }
            return ["file_id": "none", "file_type": "none", "is_single_doc": "false"]
        }

        // 添加doc参数：is_single_doc file_id file_type
        private static func doc(_ msg: LarkModel.Message) -> [AnyHashable: Any] {
            // 是否有Doc内容
            if let docEntity = (msg.content as? TextContent)?.docEntity ?? (msg.content as? PostContent)?.docEntity {
                var fileTokens: [String] = []
                var fileTypes: [String] = []
                docEntity.elementEntityRef.values.forEach { entity in
                    fileTokens.append(entity.token)
                    switch entity.docType {
                    case .doc:
                        fileTypes.append("doc")
                    case .sheet:
                        fileTypes.append("sheet")
                    case .mindnote:
                        fileTypes.append("mindnote")
                    case .docx:
                        fileTypes.append("docx")
                    case .bitable:
                        fileTypes.append("bitable")
                    case .slide:
                        fileTypes.append("slide")
                    case .slides:
                        fileTypes.append("slides")
                    case .file:
                        fileTypes.append("file")
                    case .unknown, .wiki:
                        fileTypes.append("others")
                    case .folder, .catalog, .shortcut: // FIXME: use unknown default setting to fix warning
                        fileTypes.append("others")
                    @unknown default:
                        fileTypes.append("others")
                    }
                }
                let isSingleDoc: Bool = (fileTokens.count == 1)
                return ["file_id": fileTokens.joined(separator: ","), "file_type": fileTypes.joined(separator: ","), "is_single_doc": isSingleDoc ? "true" : "false"]
            }
            return ["file_id": "none", "file_type": "none", "is_single_doc": "false"]
        }

        public static func chat(_ chat: LarkModel.Chat) -> [AnyHashable: Any] {
            var params: [AnyHashable: Any] = [:]
            params["chat_id"] = chat.id
            params["chat_type"] = IMTracker.Base.chatType(chat)
            params["member_type"] = IMTracker.Base.memberType(chat)
            params["chat_type_detail"] = IMTracker.Base.chatTypeDetail(chat)
            params["group_name_length"] = chat.name.count
            params["member_count"] = chat.userCount
            params["group_description_length"] = chat.description.count
            if chat.type == .p2P {
                params["bot_count"] = chat.isSingleBot ? 1 : 0
            } else {
                params["bot_count"] = max(chat.chatterCount - chat.userCount, 0)
            }
            // 如果是MyAI场景，需要上传shadow_id
            if chat.isP2PAi {
                params["shadow_id"] = chat.chatter?.id ?? ""
            }
            params["is_inner_group"] = chat.isCrossTenant ? "false" : "true"
            params["is_public_group"] = chat.isPublic ? "true" : "false"
            if chat.type == .p2P, chat.isSingleBot, let id = chat.chatter?.openAppId, !id.isEmpty {
                params["bot_id"] = id
            } else {
                params["bot_id"] = "none"
            }
            params["group_mode"] = chat.displayInThreadMode ? "thread" : "normal"
            return params
        }

        public static func chatSceneDic(_ fromWhereValue: String?) -> [AnyHashable: Any] {
            guard let fromWhere = ChatFromWhere(fromValue: fromWhereValue) else { return [:] }
            switch fromWhere {
            case .myAIChatMode:
                return ["scene": "im_chat_mode_view"]
            case .vcMeeting:
                return ["scene": "vc_chat_view"]
            default:
                return ["scene": "im_chat_view"]
            }
        }
    }
}

/// 新方案提出了公参的概念，上传Event时需要携带某些类型的公参，比如：消息公参、会话公参等
/// 这些公参生成逻辑统一放在LKCommonsTracker，这些方法都重新定义了对应的入参，比如消息公参需要入参类型为MxModel，不把Message作为入参是因为
/// 其他业务方不一定能提供Message模型，此处是存放Messenger业务方转为对应入参的逻辑，比如会把Message转为MxModel
public extension IMTracker {
    struct Transform {
        public static func message(_ msg: LarkModel.Message) -> TeaMessageSceneModel {
            return TeaMessageSceneModel(
                messageId: msg.id,
                cid: msg.cid,
                messageType: IMTracker.Base.messageType(msg)
            )
        }

        public static func chat(_ chat: LarkModel.Chat) -> TeaChatSceneModel {
            return TeaChatSceneModel(
                chatId: chat.id,
                chatType: IMTracker.Base.chatType(chat),
                chatTypeDetail: IMTracker.Base.chatTypeDetail(chat),
                memberType: IMTracker.Base.memberType(chat),
                isInnerGroup: chat.isCrossTenant ? "false" : "true",
                isPublicGroup: chat.isPublic ? "true" : "false"
            )
        }
    }
}
