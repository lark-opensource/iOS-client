//
//  MailMetricPushHandler.swift
//  LarkMail
//
//  Created by tefeng liu on 2021/7/22.
//

import Foundation
import RustPB
import LarkFoundation
import AppReciableSDK
import LarkContainer
import LarkSDKInterface
import LKCommonsLogging
import LarkRustClient

extension String: ReciableEventable {
    public var eventKey: String {
        return self
    }
}

final class MailMetricsPushHandler: UserPushHandler {
    let logger = Logger.log(MailMetricsPushHandler.self, category: "Module.Mail")


    func process(push: MailMetricsResponse) throws {
//        // if simulator ignore it. if you want to debug. delete it if you need
//        if LarkFoundation.Utils.isSimulator {
//            return
//        }

        for event in push.slardar {
            if let appreciable = event.metric.appreciable {
                switch appreciable {
                case .error(_):
                    if let scene = sceneMapper(scene: event.category.scene) {
                        let eventPB = eventMapper(event: event.metric.event)
                        var params = [String: Any]()
                        params.merge(other: event.category.strExtra)
                        params.merge(other: event.category.intExtra)
                        let errorParams = ErrorParams(biz: .Mail,
                                                      scene: scene,
                                                      eventable: eventPB,
                                                      errorType: errorTypeMapper(errorType: event.metric.error.errorType),
                                                      errorLevel: errorLevelMapper(errorLevel: event.metric.error.level),
                                                      errorCode: Int(event.metric.error.errorCode),
                                                      userAction: nil,
                                                      page: event.category.page,
                                                      errorMessage: event.category.strExtra["mail_status"] ?? "",
                                                      extra: Extra(isNeedNet: event.category.isNeedNet,
                                                                   latencyDetail: event.metric.latency.detail,
                                                                   metric: nil,
                                                                   category: params,
                                                                   extra: nil))
                        AppReciableSDK.shared.error(params: errorParams)
                    }
                case .latency(_):
                    if let scene = sceneMapper(scene: event.category.scene) {
                        let eventPB = eventMapper(event: event.metric.event)
                        var params = [String: Any]()
                        params.merge(other: event.category.strExtra)
                        params.merge(other: event.category.intExtra)
                        let costParams = TimeCostParams(biz: .Mail,
                                                        scene: scene,
                                                        eventable: eventPB,
                                                        cost: Int(event.metric.latency.timeCost),
                                                        page: event.category.page,
                                                        extra: Extra(isNeedNet: event.category.isNeedNet,
                                                                     latencyDetail: event.metric.latency.detail,
                                                                     metric: nil,
                                                                     category: params,
                                                                     extra: nil))
                        print("MailMetricsPushHandler time cost \(costParams)")
                        AppReciableSDK.shared.timeCost(params: costParams)
                    }
                @unknown default:
                    assert(false)
                }
            }
        }
    }

    private func sceneMapper(scene: Int32) -> Scene? {
        switch scene {
        case SceneMapper.MailFMP:
            return .MailFMP
        case SceneMapper.MailRead:
            return .MailRead
        case SceneMapper.MailSearch:
            return .MailSearch
        case SceneMapper.MailDraft:
            return .MailDraft
        case SceneMapper.MailNetwork:
            return .MailNetwork
        default:
            return nil
        }
    }

    private enum SceneMapper {
        static let MailFMP: Int32 = 40
        static let MailRead: Int32 = 41
        static let MailSearch: Int32 = 42
        static let MailDraft: Int32 = 43
        static let MailNetwork: Int32 = 59
    }

    private func eventMapper(event: String) -> ReciableEventable {
        switch event {
        case "mail_received_message":
            return Event.mailReceivedMessage
        case "mail_thread_action":
            return Event.mailThreadAction
        case "mail_network_record":
            return Event.mailNetworkRecord
        case "mail_label_unread_count":
            return Event.mailLabelUnreadCount
        default:
            return event
        }
    }

    private func errorTypeMapper(errorType: Int32) -> ErrorType {
        switch errorType {
        case 0:
            return .Unknown
        case 1:
            return .Network
        case 2:
            return .SDK
        case 3:
            return .Other
        default:
            return .Unknown
        }
    }

    private func errorLevelMapper(errorLevel: Int32) -> ErrorLevel {
        switch errorLevel {
        case 1:
            return .Fatal
        case 2:
            return .Exception
        default:
            return .Fatal
        }
    }
}
