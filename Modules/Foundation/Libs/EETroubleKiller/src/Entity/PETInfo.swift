//
//  PETInfo.swift
//  EETroubleKiller
//
//  Created by Meng on 2019/5/13.
//

import UIKit

public enum Topic: String, Codable {
    case route

    case appear

    case toast
}

struct Event<Info: Codable>: Codable {
    var topic: Topic

    var domainKey: [String: String]

    var info: Info

    init(topic: Topic, domainKey: [String: String], info: Info) {
        self.topic = topic
        self.domainKey = domainKey
        self.info = info
    }
}

struct ObjectItem: Codable {
    var name: String
    var id: String

    init(_ instance: Any) {
        self.name = String.tkName(instance)
        self.id = String.tkId(instance)
    }
}

struct PInfo: Codable {
    var source: ObjectItem?

    var target: ObjectItem
}

struct TInfo: Codable {
    var text: String
}
