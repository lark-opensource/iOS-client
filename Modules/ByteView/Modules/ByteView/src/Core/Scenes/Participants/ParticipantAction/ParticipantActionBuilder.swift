//
//  ParticipantActionBuilder.swift
//  ByteView
//
//  Created by wulv on 2023/6/14.
//

import Foundation

struct ParticipantActionSection {
    var rows: [ParticipantAction]
    var factorys: [ParticipantActionFactory]
}

final class ParticipantActionBuilder {
    private var sections: [ParticipantActionSection] = []

    @discardableResult func section() -> Self {
        sections.append(ParticipantActionSection(rows: [], factorys: []))
        return self
    }

    @discardableResult func row<Action: ParticipantAction>(_ id: ParticipantActionType, action: Action.Type) -> Self {
        let factory = ParticipantActionFactory(action, id: id)
        sections[sections.count - 1].factorys.append(factory)
        return self
    }

    func build() -> [ParticipantActionSection] {
        self.sections = sections.filter { !$0.factorys.isEmpty }
        return self.sections
    }
}
