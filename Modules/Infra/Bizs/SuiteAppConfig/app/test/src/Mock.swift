//
//  Mock.swift
//  SuiteAppConfigDevEEUnitTest
//
//  Created by liuwanlin on 2020/3/4.
//

import Foundation
import RustPB
import SwiftProtobuf
import RxSwift
import LarkRustClient

// swiftlint:disable function_body_length
func mockConfig() -> Basic_V1_AppConfigV2 {
    let features: [String: [String: Any]] = [
        "push": [
            "isOn": false
        ],
        "navi": [
            "isOn": true,
            "traits": """
            {
                "tabs": [
                    {
                        "id": 1,
                        "key": "conversation",
                        "name": {
                            "zh_CN": "消息",
                            "en_US": "Messages",
                            "ja_JP": "メッセージ"
                        },
                        "desc": {
                            "zh_CN": "",
                            "en_US": "",
                            "ja_JP": ""
                        },
                        "primaryOnly": true,
                        "logo": {
                            "primary_default": "https://sf1-ttcdn-tos.pstatp.com/obj/ttfe/lark/navs/navs-default/iconChatSolid_2x.png",
                            "primary_selected": "https://sf1-ttcdn-tos.pstatp.com/obj/ttfe/lark/navs/navs-selected/iconChatSolid_2x.png",
                            "secretary_default": "https://sf1-ttcdn-tos.pstatp.com/obj/ttfe/lark/navs/navs-secretary/iconChatSolid_2x.png",
                            "secretary_bgcolor": "#3370ff"
                        },
                        "appType": "native",
                        "platforms": [
                            {
                                "type": "iOS",
                                "minVersion": "3.11.0"
                            },
                            {
                                "type": "Android",
                                "minVersion": "3.11.0"
                            }
                        ]
                    }, {
                        "id": 2,
                        "key": "calendar",
                        "name": {
                            "zh_CN": "日历",
                            "en_US": "Calendar",
                            "ja_JP": "カレンダー"
                        },
                        "desc": {
                            "zh_CN": "",
                            "en_US": "",
                            "ja_JP": ""
                        },
                        "primaryOnly": false,
                        "logo": {
                            "primary_default": "https://sf1-ttcdn-tos.pstatp.com/obj/ttfe/lark/navs/navs-default/iconCalendarSolid_2x.png",
                            "primary_selected": "https://sf1-ttcdn-tos.pstatp.com/obj/ttfe/lark/navs/navs-selected/iconCalendarSolid_2x.png",
                            "secretary_default": "https://sf1-ttcdn-tos.pstatp.com/obj/ttfe/lark/navs/navs-secretary/iconCalendarSolid_2x.png",
                            "secretary_bgcolor": "#ff8800"
                        },
                        "appType": "native",
                        "platforms": [
                            {
                                "type": "iOS",
                                "minVersion": "3.11.0"
                            },
                            {
                                "type": "Android",
                                "minVersion": "3.11.0"
                            }
                        ]
                    }, {
                        "id": 4,
                        "key": "space",
                        "name": {
                            "zh_CN": "云空间",
                            "en_US": "Drive",
                            "ja_JP": "クラウド"
                        },
                        "desc": {
                            "zh_CN": "",
                            "en_US": "",
                            "ja_JP": ""
                        },
                        "primaryOnly": false,
                        "logo": {
                            "primary_default": "https://sf1-ttcdn-tos.pstatp.com/obj/ttfe/lark/navs/navs-default/iconSpaceSolid_2x.png",
                            "primary_selected": "https://sf1-ttcdn-tos.pstatp.com/obj/ttfe/lark/navs/navs-selected/iconSpaceSolid_2x.png",
                            "secretary_default": "https://sf1-ttcdn-tos.pstatp.com/obj/ttfe/lark/navs/navs-secretary/iconSpaceSolid_2x.png",
                            "secretary_bgcolor": "#3370ff"
                        },
                        "appType": "native",
                        "platforms": [
                            {
                                "type": "iOS",
                                "minVersion": "3.11.0"
                            },
                            {
                                "type": "Android",
                                "minVersion": "3.11.0"
                            }
                        ]
                    }, {
                        "id": 6,
                        "key": "contact",
                        "name": {
                            "zh_CN": "联系人",
                            "en_US": "Contacts",
                            "ja_JP": "連絡先"
                        },
                        "desc": {
                            "zh_CN": "",
                            "en_US": "",
                            "ja_JP": ""
                        },
                        "primaryOnly": false,
                        "logo": {
                            "primary_default": "https://sf1-ttcdn-tos.pstatp.com/obj/ttfe/lark/navs/navs-default/iconAddressListSolid_2x.png",
                            "primary_selected": "https://sf1-ttcdn-tos.pstatp.com/obj/ttfe/lark/navs/navs-selected/iconAddressListSolid_2x.png",
                            "secretary_default": "https://sf1-ttcdn-tos.pstatp.com/obj/ttfe/lark/navs/navs-secretary/iconAddressListSolid_2x.png",
                            "secretary_bgcolor": "#ffc60a"
                        },
                        "appType": "native",
                        "platforms": [
                            {
                                "type": "iOS",
                                "minVersion": "3.11.0"
                            },
                            {
                                "type": "Android",
                                "minVersion": "3.11.0"
                            }
                        ]
                    }
                ]
            }
            """
        ],
        "sso": [
            "isOn": false
        ],
        "urgent.urgentList": [
            "isOn": false
        ],
        "feed.shortcut": [
            "isOn": false
        ],
        "feed.list": [
            "isOn": true,
            "traits": """
            {"dataTimeLimit": 64800}
            """
        ],
        "thread": [
            "isOn": false
        ],
        "message.pull": [
            "isOn": true,
            "traits": """
            {"dataTimeLimit": 64800}
            """
        ],
        "chat.hongbao": [
            "isOn": false
        ],
        "secrectChat": [
            "isOn": false
        ],
        "search.secrectChat": [
            "isOn": true
        ],
        "pin.sidebar": [
            "isOn": false
        ],
        "favorite": [
            "isOn": false
        ],
        "chat.messageAction": [
             "isOn": false
        ],
        "chat.groupNotice": [
             "isOn": false
        ],
        "chat.groupShareHistory": [
            "isOn": false
        ],
        "chat.enterLeaveGroupHistory": [
            "isOn": false
        ],
        "helpdesk": [
            "isOn": false
        ],
        "search.helpdesk": [
            "isOn": false
        ],
        "bots": [
            "isOn": false
        ],
        "search.bots": [
            "isOn": false
        ],
        "apps": [
            "isOn": false
        ],
        "search": [
            "isOn": true,
            "traits": """
            {"dataTimeLimit": 64800}
            """
        ],
        "search.apps": [
            "isOn": false
        ],
        "event.minutes": [
            "isOn": false
        ],
        "event.chat": [
            "isOn": false
        ],
        "event.video": [
            "isOn": false
        ],
        "event.description": [
            "isOn": false
        ],
        "event.attachment": [
            "isOn": false
        ],
        "event.reminder": [
            "isOn": false
        ],
        "search.event": [
            "isOn": false
        ],
        "ccm.folder": [
            "isOn": false
        ],
        "ccm.star": [
            "isOn": false
        ],
        "ccm.offline": [
            "isOn": false
        ],
        "ccm.pin": [
            "isOn": false
        ],
        "ccm.wiki": [
            "isOn": false
        ],
        "leanMode": [
            "isOn": true,
            "traits": """
            {
                "specializeProfile": true,
                "specializeContact": true,
                "clearDataTimeInterval": 3600
            }
            """
        ]
    ]

    var section = Basic_V1_AppConfigV2.Section()
    section.features = features.mapValues({ (feature) -> Basic_V1_AppConfigV2.FeatureConf in
        var ff = Basic_V1_AppConfigV2.FeatureConf()
        ff.isOn = (feature["isOn"] as? Bool)!
        if let traits = feature["traits"] as? String {
            ff.traits = traits
        }
        return ff
    })

    var config = Basic_V1_AppConfigV2()
    config.section = section

    return config
}
// swiftlint:enable function_body_length

enum SimpleError: Error {
    case fakeResponse
}

class MockRustClient: RustService {
    func eventStream<R>(request: Message, config: Basic_V1_RequestPacket.BizConfig?, traceID: String, spanID: String) -> Observable<R> where R: Message {
        return .just(.init())
    }

    func register(serverPushCmd cmd: ServerCommand, handler: @escaping (Data) -> Void) -> Disposable {
        return Disposables.create()
    }

    func eventStream<R>(request: Message, config: Basic_V1_RequestPacket.BizConfig?) -> Observable<R> where R: Message {
        return .empty()
    }

    func eventStream<R>(_ request: RequestPacket, event handler: @escaping (ResponsePacket<R>?, Bool) -> Void) -> Disposable where R: Message {
        return Disposables.create()
    }

    func async<R>(_ request: RequestPacket, callback: @escaping (ResponsePacket<R>) -> Void) where R: Message {

    }

    func async(_ request: RequestPacket, callback: @escaping (ResponsePacket<Void>) -> Void) {

    }

    func sync<R>(_ request: RequestPacket) -> ResponsePacket<R> where R: Message {
        return ResponsePacket(contextID: "fakeid", result: .failure(SimpleError.fakeResponse))
    }

    func sync(_ request: RequestPacket) -> ResponsePacket<Void> {
        return ResponsePacket(contextID: "fakeid", result: .failure(SimpleError.fakeResponse))
    }

    func register(pushCmd cmd: Command, handler: @escaping (Data) -> Void) -> Disposable {
        return Disposables.create()
    }

    func register<R>(pushCmd cmd: Command) -> Observable<R> where R: Message {
        return .empty()
    }

    func unregisterPushHanlders() {

    }

    func dispose() {

    }

    func barrier(allowRequest: @escaping (RequestPacket) -> Bool, enter: @escaping (@escaping () -> Void) -> Void) {

    }

    func sendAsyncRequest<R: SwiftProtobuf.Message>(_ request: SwiftProtobuf.Message) -> Observable<R> {
        if request is Im_V1_PullAllAppConfigV2Request {
            return Observable<R>.create { (observer) -> Disposable in
                DispatchQueue.main.async {
                    var response = Im_V1_PullAllAppConfigV2Response()
                    response.config = mockConfig()
                    observer.onNext((response as? R)!)
                }
                return Disposables.create()
            }
        }
        fatalError("Not supported requet [\(R.self)]")
    }

}
