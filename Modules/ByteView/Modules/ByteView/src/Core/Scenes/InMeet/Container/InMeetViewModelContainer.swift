//
//  InMeetViewModelContainer.swift
//  ByteView
//
//  Created by kiri on 2021/5/19.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon
import ByteViewTracker

protocol InMeetViewModelResolver: AnyObject {
    var meeting: InMeetMeeting { get }
    var viewContext: InMeetViewContext { get }
    func resolve<ViewModel: InMeetViewModelComponent>(_ type: ViewModel.Type) -> ViewModel?
}

extension InMeetViewModelResolver {
    /// 只用在类型可被推断的情况下
    func resolve<ViewModel: InMeetViewModelComponent>() -> ViewModel? {
        resolve(ViewModel.self)
    }
}

protocol InMeetViewModelComponent {
    init(resolver: InMeetViewModelResolver)
}

protocol InMeetViewModelSimpleComponent: InMeetViewModelComponent {
    init(meeting: InMeetMeeting)
}

extension InMeetViewModelSimpleComponent {
    init(resolver: InMeetViewModelResolver) {
        self.init(meeting: resolver.meeting)
    }
}

protocol InMeetViewModelSimpleContextComponent: InMeetViewModelComponent {
    init(meeting: InMeetMeeting, context: InMeetViewContext)
}

extension InMeetViewModelSimpleContextComponent {
    init(resolver: InMeetViewModelResolver) {
        self.init(meeting: resolver.meeting, context: resolver.viewContext)
    }
}

final class InMeetViewModelContainer {
    let resolver: InMeetViewModelResolver
    private let meeting: InMeetMeeting
    private let context: InMeetViewContext
    private let configs = InMeetRegistry.shared.viewModelConfigs
    private var cache: [ObjectIdentifier: InMeetViewModelComponent] = [:]
    private var scope: InMeetViewScope = .global

    private lazy var logDescription = metadataDescription(of: self)
    init(meeting: InMeetMeeting, context: InMeetViewContext) {
        self.meeting = meeting
        self.context = context
        let resolver = InMeetViewModelResolverImpl(meeting: meeting, context: context)
        self.resolver = resolver
        resolver.container = self
        Logger.ui.info("init \(logDescription)")
    }

    deinit {
        Logger.ui.info("deinit \(logDescription)")
    }

    func resolveNonLazyObjects() {
        configs.forEach { (_, config) in
            if !config.isLazy {
                _ = resolve(config)
            }
        }
    }

    fileprivate func resolve<T: InMeetViewModelComponent>(_ type: T.Type) -> T? {
        if let config = configs[ObjectIdentifier(type)] {
            return resolve(config) as? T
        }
        return nil
    }

    fileprivate func resolve(_ config: InMeetViewModelConfig) -> InMeetViewModelComponent {
        assertMain()
        let id = config.id
        if let obj = cache[id] {
            return obj
        }
        let obj = config.create(resolver: resolver)
        cache[id] = obj
        return obj
    }
}

struct InMeetViewModelConfig: CustomStringConvertible {
    let id: ObjectIdentifier
    let isLazy: Bool
    let componentType: InMeetViewModelComponent.Type
    let description: String

    init<ViewModel: InMeetViewModelComponent>(_ vmType: ViewModel.Type, isLazy: Bool) {
        self.id = ObjectIdentifier(vmType)
        self.isLazy = isLazy
        self.componentType = vmType
        self.description = "\(vmType)"
    }

    func create(resolver: InMeetViewModelResolver) -> InMeetViewModelComponent {
        let obj = componentType.init(resolver: resolver)
        Logger.ui.info("create viewmodel success: \(self.description)")
        MemoryLeakTracker.addAssociatedItem(obj as AnyObject, name: self.description, for: resolver.meeting.sessionId)
        return obj
    }
}

private class InMeetViewModelResolverImpl: InMeetViewModelResolver {
    let meeting: InMeetMeeting
    let viewContext: InMeetViewContext
    weak var container: InMeetViewModelContainer?
    private lazy var logDescription = metadataDescription(of: self)
    init(meeting: InMeetMeeting, context: InMeetViewContext) {
        self.meeting = meeting
        self.viewContext = context
        Logger.ui.info("init \(logDescription)")
    }

    deinit {
        Logger.ui.info("deinit \(logDescription)")
    }

    func resolve<ViewModel: InMeetViewModelComponent>(_ type: ViewModel.Type) -> ViewModel? {
        container?.resolve(type) as? ViewModel
    }
}
