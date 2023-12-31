//
//  ContactRouterBody.swift
//  LarkContact
//
//  Created by lizhiqiang on 2019/5/22.
//

import Foundation
import EENavigator
import LarkSDKInterface

typealias NextFunc = (CreateGroupNameViewController, String) -> Void
struct GroupNameVCBody: PlainBody {
    static var pattern: String = "//client/contact/groupname"

    let chatAPI: ChatAPI
    let nextFunc: NextFunc?
    let groupName: String
    let isTopicGroup: Bool

    init(chatAPI: ChatAPI, groupName: String, isTopicGroup: Bool, nextFunc: @escaping NextFunc) {
        self.chatAPI = chatAPI
        self.nextFunc = nextFunc
        self.groupName = groupName
        self.isTopicGroup = isTopicGroup
    }
}
