//
//  MeetingDetailComponentResolver.swift
//  ByteViewTab
//
//  Created by fakegourmet on 2022/11/30.
//

import Foundation

class MeetingDetailComponentResolver {

    private var cache: [String: MeetingDetailComponent] = [:]

    func resolve(_ type: MeetingDetailComponent.Type) -> MeetingDetailComponent? {
        let id = String(describing: type)
        if let component = cache[id] {
            return component
        } else {
            let component = type.init()
            cache[id] = component
            return component
        }
    }
}
