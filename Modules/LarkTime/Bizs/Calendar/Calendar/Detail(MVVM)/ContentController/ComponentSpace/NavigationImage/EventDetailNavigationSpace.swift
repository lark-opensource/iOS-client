//
//  EventDetailNavigationSpace.swift
//  Calendar
//
//  Created by Rico on 2021/3/16.
//

import CalendarFoundation
import Foundation
import UIKit

// MARK: - Manager
final class EventDetailNavigationManager: BaseManager {

    let provider: EventDetailComponentProvider

    init(provider: EventDetailComponentProvider) {
        self.provider = provider
        super.init()
    }

    @ComponentBuilder
    func generateBottomActionComponents() -> [ComponentType] {
        provider.buildComponent(for: .navigation)
    }
}

// MARK: - Space
final class EventDetailNavigationSpace: BaseSpace<EventDetailNavigationManager, EventDetailNavigationLayoutEngine> {

    let state: EventDetailState

    init(viewController: UIViewController,
         componentProvider: EventDetailComponentProvider,
         state: EventDetailState) {

        self.state = state
        super.init(manager: EventDetailNavigationManager(provider: componentProvider),
                   layoutEngine: EventDetailNavigationLayoutEngine(),
                   viewController: viewController)
    }

    override func loadComponents() {
        let components = manager.generateBottomActionComponents()
        manager.components = components
        manager.components.forEach { component in
            component.viewController = viewController
        }
        EventDetail.logDebug("navigation space load component count: \(components.count)")
    }
}
