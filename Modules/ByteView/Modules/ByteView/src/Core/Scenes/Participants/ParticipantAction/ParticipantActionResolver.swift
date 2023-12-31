//
//  ParticipantActionResolver.swift
//  ByteView
//
//  Created by wulv on 2023/6/12.
//

import Foundation
import ByteViewNetwork

protocol ParticipantActionUserInfo {
    var display: String { get }
    var original: String { get }
}

extension ParticipantUserInfo: ParticipantActionUserInfo {
    var display: String { name }
    var original: String { originalName }
}

struct ParticipantActionContext {
    let source: ParticipantActionSource
    let participant: Participant
    let lobbyParticipant: LobbyParticipant?
    let userInfo: ParticipantActionUserInfo
    let meeting: InMeetMeeting
    let inMeetContext: InMeetViewContext

    struct UserInfo: ParticipantActionUserInfo {
        let displayName: String
        let originalName: String

        var display: String { displayName }
        var original: String { originalName }
    }
}

protocol ParticipantActionComponent {
    init(resolver: ParticipantActionResolver, id: ParticipantActionType)
}

class ParticipantActionResolver {
    let context: ParticipantActionContext
    weak var provider: ParticipantActionProvider?
    private let registry: ParticipantActionRegistry
    private let lock = NSRecursiveLock()
    private var cache: [ParticipantActionType: ParticipantAction] = [:]

    init(context: ParticipantActionContext, service: ParticipantActionProvider?) {
        self.context = context
        self.provider = service
        self.registry = ParticipantActionRegistry(source: context.source)
    }

    func getActions() -> [ParticipantActionSection] {
        var actions: [ParticipantActionSection] = []
        registry.sections.forEach {
            var section = ParticipantActionSection(rows: [], factorys: [])
            $0.factorys.forEach { factory in
                let action = resolve(factory)
                if action.show {
                    section.factorys.append(factory)
                    section.rows.append(action)
                }
            }
            if !section.rows.isEmpty {
                actions.append(section)
            }
        }
        return actions
    }

    private func resolve(_ id: ParticipantActionType) -> ParticipantAction? {
        guard let factory = registry.sections.flatMap(\.factorys).first(where: { $0.id == id }) else { return nil }
        return resolve(factory)
    }

    private func resolve(_ factory: ParticipantActionFactory) -> ParticipantAction {
        assertMain()
        lock.lock()
        defer { lock.unlock() }
        let id = factory.id
        if let obj = cache[id] {
            return obj
        }
        let obj = factory.create(self)
        cache[id] = obj
        return obj
    }
}

struct ParticipantActionFactory {
    let id: ParticipantActionType
    let action: ParticipantAction.Type

    init<Action: ParticipantAction>(_ action: Action.Type, id: ParticipantActionType) {
        self.id = id
        self.action = action
    }

    func create(_ resolver: ParticipantActionResolver) -> ParticipantAction {
        return action.init(resolver: resolver, id: id)
    }
}

final class ParticipantActionRegistry {
    let source: ParticipantActionSource
    let sections: [ParticipantActionSection]
    init(source: ParticipantActionSource) {
        self.source = source
        switch source {
            /// 目前各入口的顺序是一样的
        case .grid, .single, .allList, .attendeeList, .searchList:
            self.sections = ParticipantActionRegistry.defaultOrdered()
        case .invitee:
            self.sections = ParticipantActionRegistry.inviteeOrdered()
        case .lobby:
            self.sections = ParticipantActionRegistry.lobbyOrdered()
        }
    }
}
