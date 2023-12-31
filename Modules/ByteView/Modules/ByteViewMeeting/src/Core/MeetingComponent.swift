//
//  MeetingComponent.swift
//  ByteViewMeeting
//
//  Created by kiri on 2022/5/31.
//

import Foundation
import ByteViewCommon
import ByteViewTracker

/// MeetingSession维护的组件，组件可根据MeetingState或MeetingComponentScope来约束其生命周期
/// - 注册组件使用 `MeetingComponentRegistry.shared.registerComponent`
public protocol MeetingComponent: AnyObject {
    /// 初始化组件。组件可持有MeetingSession，不会造成循环引用
    init?(session: MeetingSession, event: MeetingEvent, fromState: MeetingState)
    /// 为了不依赖deinit释放资源，故有此回调
    func willReleaseComponent(session: MeetingSession, event: MeetingEvent, toState: MeetingState)
}

public extension MeetingSession {
    func component<T: MeetingComponent>(for componentType: T.Type) -> T? {
        let id = Int(bitPattern: ObjectIdentifier(componentType))
        if let obj = MeetingComponentCache.shared.getComponent(id: id, session: self) {
            return obj as? T
        }
        return nil
    }
}

public enum MeetingComponentScope: Hashable {
    case session

    fileprivate var states: Set<MeetingState> {
        switch self {
        case .session:
            return MeetingComponentScope.allStates
        }
    }

    private static let allStates = Set(MeetingState.allCases)
}

public final class MeetingComponentRegistry {
    public static func shared(for sessionType: MeetingSessionType) -> MeetingComponentRegistry {
        switch sessionType {
        case .vc:
            return .vc
        }
    }

    public func registerComponent<T: MeetingComponent>(_ type: T.Type, state: MeetingState...) {
        registerComponent(type, states: Set(state))
    }

    public func registerComponent<T: MeetingComponent>(_ type: T.Type, scope: MeetingComponentScope) {
        registerComponent(type, states: scope.states)
    }

    private func registerComponent<T: MeetingComponent>(_ type: T.Type, states: Set<MeetingState>) {
        let id = Int(bitPattern: ObjectIdentifier(type))
        #if DEBUG || ALPHA
        if let obj = self.configs.first(where: { $0.id == id }) {
            fatalError("duplicate component: \(obj)")
        }
        #endif
        let logDescription = "\(type)"
        self.configs.append(MeetingComponentConfig(id: id, scope: states, factory: {
            T.init(session: $0, event: $1, fromState: $2)
        }, logDescription: logDescription))
    }

    let sessionType: MeetingSessionType
    @RwAtomic
    fileprivate var configs: [MeetingComponentConfig] = []
    private init(sessionType: MeetingSessionType) {
        self.sessionType = sessionType
    }
}

/// 不用map存，以免频繁lock
private extension MeetingComponentRegistry {
    static let vc = MeetingComponentRegistry(sessionType: .vc)
}

private struct MeetingComponentConfig {
    let id: Int
    let scope: Set<MeetingState>
    let factory: (MeetingSession, MeetingEvent, MeetingState) -> MeetingComponent?
    let logDescription: String
}

/// 代持会议组件，避免和MeetingSession循环引用
final class MeetingComponentCache {
    static let shared = MeetingComponentCache()
    private let lock = NSRecursiveLock()
    private var sessionCaches: [String: MeetingComponentSessionCache] = [:]

    func getComponent(id: Int, session: MeetingSession) -> MeetingComponent? {
        lock.lock()
        defer { lock.unlock() }
        if let config = session.componentConfigs.first(where: { $0.id == id }), let cache = sessionCaches[session.sessionId] {
            return cache.getComponent(config: config, session: session)
        }
        return nil
    }

    func createSessionCache(_ sessionId: String) {
        lock.lock()
        defer { lock.unlock() }
        sessionCaches[sessionId] = MeetingComponentSessionCache()
    }

    func leaveSession(session: MeetingSession) {
        lock.lock()
        defer { lock.unlock() }
        sessionCaches.removeValue(forKey: session.sessionId)?.leave(session: session)
    }

    func exchangeScope(event: MeetingEvent, leave: MeetingState, enter: MeetingState, session: MeetingSession, onLeave: () -> Void) {
        lock.lock()
        defer { lock.unlock() }
        sessionCaches[session.sessionId]?.exchangeScope(event: event, leave: leave, enter: enter, session: session, onLeave: onLeave)
    }

    func enter(state: MeetingState, session: MeetingSession) {
        lock.lock()
        defer { lock.unlock() }
        sessionCaches[session.sessionId]?.enter(state: state, session: session)
    }
}

private class MeetingComponentSessionCache {
    private var components: [Int: MeetingComponent] = [:]
    private var scope: Set<MeetingState> = [.start]

    func getComponent(config: MeetingComponentConfig, session: MeetingSession) -> MeetingComponent? {
        if config.scope.isDisjoint(with: scope) {
            return nil
        }
        if let obj = components[config.id] {
            return obj
        }
        /// 部分场景（callkit下）使用component时可能还没创建，这时resolve一下
        /// - 仅start状态做这种初始化，其他状态需要依赖状态机流转
        if config.scope.contains(.start), session.state != .end,
           let component = config.createComponent(session, event: .createSession, from: .start) {
            components[config.id] = component
            return component
        }
        return nil
    }

    func enter(state: MeetingState, session: MeetingSession) {
        scope.insert(state)
        session.componentConfigs.forEach { config in
            if config.scope.contains(state), components[config.id] == nil, let component = config.createComponent(session, event: .createSession, from: .start) {
                components[config.id] = component
            }
        }
    }

    func leave(session: MeetingSession) {
        assert(session.state == .end, "leave session from active session! \(session)")
        let configs = session.componentConfigs
        components.forEach { (id, component) in
            component.releaseComponent(session: session, config: configs.first(where: { $0.id == id }), event: .destroySession, to: .end)
        }
    }

    func exchangeScope(event: MeetingEvent, leave: MeetingState, enter: MeetingState, session: MeetingSession, onLeave: () -> Void) {
        self.scope.remove(leave)
        self.scope.insert(enter)
        let scope = self.scope
        let configs = session.componentConfigs
        configs.forEach { config in
            if config.scope.contains(leave), config.scope.isDisjoint(with: scope) {
                components.removeValue(forKey: config.id)?.releaseComponent(session: session, config: config, event: event, to: enter)
            }
        }
        onLeave()
        configs.forEach { config in
            if config.scope.contains(enter), components[config.id] == nil,
               let component = config.createComponent(session, event: event, from: leave) {
                components[config.id] = component
            }
        }
    }
}

private extension MeetingComponentConfig {
    func createComponent(_ session: MeetingSession, event: MeetingEvent, from: MeetingState,
                         file: String = #fileID, function: String = #function, line: Int = #line) -> MeetingComponent? {
        let t0 = CACurrentMediaTime()
        let obj = factory(session, event, from)
        // nolint-next-line: magic number
        let duration = round((CACurrentMediaTime() - t0) * 1e6) / 1e3
        Logger.meeting.info("\(session) create component: \(logDescription), duration = \(duration)ms", file: file, function: function, line: line)
        return obj
    }
}

private extension MeetingComponent {
    func releaseComponent(session: MeetingSession, config: MeetingComponentConfig?, event: MeetingEvent, to: MeetingState,
                          file: String = #fileID, function: String = #function, line: Int = #line) {
        assert(config != nil, "config is nil! component is \(self)")
        let sessionTag = session.description
        let componentTag = config?.logDescription ?? "\(self)"
        Logger.meeting.info("\(sessionTag) release component: \(componentTag)", file: file, function: function, line: line)
        willReleaseComponent(session: session, event: event, toState: to)
        MemoryLeakTracker.addAssociatedItem(self, name: componentTag, for: session.sessionId)
        MemoryLeakTracker.addJob(event: .warning(.leak_object).category(.meeting).subcategory(rawValue: "meeting_component").params([
            .env_id: session.sessionId, .from_source: componentTag
        ]), file: file, function: function, line: line) { [weak self] in self != nil }
    }
}

private extension MeetingSession {
    var componentConfigs: [MeetingComponentConfig] {
        MeetingComponentRegistry.shared(for: sessionType).configs
    }
}

private extension MeetingEvent {
    static let createSession: MeetingEvent = .init(name: "_createSession")
    static let destroySession: MeetingEvent = .init(name: "_destroySession")
}
