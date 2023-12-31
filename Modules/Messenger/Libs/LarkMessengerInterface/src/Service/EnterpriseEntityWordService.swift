//
//  EnterpriseEntityWordService.swift
//  LarkMessengerInterface
//
//  Created by ZhangHongyun on 2021/1/7.
//

import UIKit
import Foundation
import RustPB
import LarkMessageBase
import ServerPB
import LarkRichTextCore
import LarkFoundation
import LKCommonsLogging
import LarkSecurityAudit
import LarkModel
import EditTextView

public enum ShowEnterpriseTopicResult {
    case susscces
    case noResult
    case disabledByAdmin
    case fail
}
public enum LingoPageEnum: String {
    case LingoCard = "lingo_card" // 卡片主页
    case MutipleSelection = "mutiple_selection" // 多释义选择面板
}

public enum SpaceType: Int {
  case UNKNOWN = 0
  case DOC = 1
  case IM = 2
}

public enum PassThroughType: String {
    case ignore // 通知端上整个词条（红色和虚线高亮）
    case close // 关闭卡片
    case docClick
    case pin // 点击选中优先展示的释义
    case unPin // 卡片中取消pin释义
}

/// 输入框内企业百科高亮服务
public protocol LingoHighlightService {
    func setupLingoHighlight(chat: LarkModel.Chat?,
                             fromController: UIViewController?,
                             inputTextView: LarkEditTextView?,
                             getMessageId: (() -> String)?)
}

public protocol EnterpriseEntityWordService {

    /// 获取实体词信息并展示实体词卡片
    /// - Parameters:
    ///   - abbrId:               实体词id
    ///   - query:                实体词
    ///   - chatId:               触发实体词的会话
    ///   - targetVC:             当前VC
    ///   - callback:             结果的回调
    ///   - clientArgs
    ///   - analysisParams
    ///   - passThroughAction:    透传动作的回调
    ///   - didTapApplink:        点击 Applink 的回调（如果未实现，默认走 Navigator 的 push 方法）

    // swiftlint:disable:next function_parameter_count
    func showEnterpriseTopic(abbrId: String,
                             query: String,
                             chatId: String?,
                             sense: ServerPB_Enterprise_entitiy_GetEnterpriseTopicRequest.Scene,
                             targetVC: UIViewController?,
                             completion: ((ShowEnterpriseTopicResult) -> Void)?,
                             clientArgs: String?,
                             analysisParams: String?,
                             passThroughAction: ((String) -> Void)?,
                             didTapApplink: ((URL) -> Void)?)

    /// IM中获取实体词信息并展示实体词卡片
    /// - Parameters:
    ///   - abbrId:      实体词id
    ///   - query:       实体词
    ///   - chatId:      触发实体词的会话
    ///   - msgId:       触发实体词的消息id
    ///   - triggerInfo: 触发实体词的气泡及其位置信息
    ///   - targetVC:    当前VC
    ///   - callback:    结果的回调
    func showEnterpriseTopicForIM(abbrId: String,
                                  query: String,
                                  chatId: String?,
                                  msgId: String?,
                                  sense: ServerPB_Enterprise_entitiy_GetEnterpriseTopicRequest.Scene,
                                  targetVC: UIViewController?,
                                  clientArgs: String?,
                                  completion: ((ShowEnterpriseTopicResult) -> Void)?,
                                  passThroughAction: ((String) -> Void)?)

    /// 消失实体词卡片
    func dismissEnterpriseTopic(animated: Bool, completion: (() -> Void)?)

    /// 获取消息气泡中实体词高亮
    func abbreviationHighlightEnabled() -> Bool
}

extension EnterpriseEntityWordService {
    public func showEnterpriseTopic(abbrId: String,
                                    query: String,
                                    chatId: String?,
                                    sense: ServerPB_Enterprise_entitiy_GetEnterpriseTopicRequest.Scene,
                                    targetVC: UIViewController?,
                                    completion: ((ShowEnterpriseTopicResult) -> Void)?,
                                    clientArgs: String? = nil,
                                    analysisParams: String? = nil,
                                    passThroughAction: ((String) -> Void)? = nil,
                                    didTapApplink: ((URL) -> Void)? = nil) {
        showEnterpriseTopic(abbrId: abbrId,
                            query: query,
                            chatId: chatId,
                            sense: sense,
                            targetVC: targetVC,
                            completion: completion,
                            clientArgs: clientArgs,
                            analysisParams: analysisParams,
                            passThroughAction: passThroughAction,
                            didTapApplink: didTapApplink)
    }

    public func dismissEnterpriseTopic(animated: Bool) {
        dismissEnterpriseTopic(animated: animated, completion: nil)
    }
}

public final class AbbreviationV2Processor {

    private static let logger = Logger.log(AbbreviationV2Processor.self, category: "EnterpriseEntityWord.AbbreviationV2Processor")

    public static func filterAbbreviation(abbreviation: RustPB.Basic_V1_Abbreviation?,
                                           typedElementRefs: [String: RustPB.Basic_V1_ElementRefs]?,
                                           tenantId: String,
                                           userId: String) -> [String: AbbreviationInfoWrapper] {
        var result: [String: AbbreviationInfoWrapper] = [:]
        let abbreviationInfo = abbreviation?.getAbbreviationMap(nil)

         if typedElementRefs == nil {
            if let abbreviationInfo = abbreviationInfo {
                for (elementId, abbreInfo) in abbreviationInfo {
                    var wrapper = AbbreviationInfoWrapper()
                    wrapper.abbres = abbreInfo
                    result[elementId] = wrapper
                }
            }
            return result
        }
        if let elementRefs = typedElementRefs?["baike"]?.elementRefs {
            for (elementId, refs) in elementRefs {
                var wrapper = AbbreviationInfoWrapper()
                var allowRefs: [RustPB.Basic_V1_Ref] = []
                for ref in refs.refs {
                    let baikeEntityMeta = ref.baikeEntityMeta
                    if let versionString = baikeEntityMeta.platformDisableOption["ios"] {
                        if Semver.isVersionDisabled(appVersion: Utils.appVersion, disabledVersion: versionString) {
                            Self.logger.info("version is disabled, appVersion:\(Utils.appVersion), disabledVersion:\(versionString)")
                            continue
                        }
                    }
                    if isBaikeEntityMetaAllowed(baikeEntityMeta: baikeEntityMeta, tenantId: tenantId, userId: userId) {
                        allowRefs.append(ref)
                    }

                }
                allowRefs.sorted {
                    return $0.span.start > $1.span.start
                }
                wrapper.refs = allowRefs
                wrapper.abbres = abbreviationInfo?[elementId]
                result[elementId] = wrapper
            }
        }
        return result
    }

    private static func isBaikeEntityMetaAllowed(baikeEntityMeta: Basic_V1_BaikeEntityMeta,
                                                 tenantId: String,
                                                 userId: String) -> Bool {
        func checkUserRepoAuthority(id: String) -> AuthResult {
            let securityAudit = SecurityAudit()
            var object = ServerPB_Authorization_CustomizedEntity()
            object.id = id
            object.entityType = "BAIKEREPO"
            return securityAudit.checkAuth(permType: .baikeRepoView, object: object)
        }

        if baikeEntityMeta.isAllowAll {
            Self.logger.info("all is allowed")
            return true
        }
        if let ids = baikeEntityMeta.allowedTypedIds["tenant"]?.ids, ids.contains(tenantId) {
            Self.logger.info("tenant is allowed")
            return true
        }
        if let ids = baikeEntityMeta.allowedTypedIds["user"]?.ids, ids.contains(userId) {
            Self.logger.info("user is allowed")
            return true
        }
        if let ids = baikeEntityMeta.allowedTypedIds["repo"]?.ids {
            for repoId in ids {
                if checkUserRepoAuthority(id: repoId) == .allow {
                    Self.logger.info("authority allowed")
                    return true
                }
            }
        }
        return false
    }

    public static func getAbbrId(wrapper: AbbreviationInfoWrapper,
                                           query: String) -> String? {
        var id: String?
        if let refs = wrapper.refs {
            for ref in refs where ref.matchedWord == query {
                id = ref.baikeEntityMeta.id
                break
            }
        }
        if id == nil, let abbre = wrapper.abbres?.first {
            id = abbre.abbrID
        }
        return id
    }
}
