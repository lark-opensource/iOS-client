//
//  EventDetailHeaderSpace.swift
//  Calendar
//
//  Created by Rico on 2021/3/16.
//

import CalendarFoundation
import Foundation
import UIKit

// MARK: - Space

final class EventDetailHeaderSpace: BaseSpace<EventDetailHeaderManager, EventDetailHeaderLayoutEngine> {

    let eventDetailState: EventDetailState

    init(viewController: UIViewController,
         componentProvider: EventDetailComponentProvider,
         eventDetailState: EventDetailState) {

        self.eventDetailState = eventDetailState
        super.init(manager: EventDetailHeaderManager(provider: componentProvider),
                   layoutEngine: EventDetailHeaderLayoutEngine(),
                   viewController: viewController)
    }

    override func loadComponents() {
        manager.generateComponents()
        manager.components.forEach { component in
            component.viewController = viewController
        }

    }
}

// MARK: - Manager
final class EventDetailHeaderManager: BaseManager {

    let provider: EventDetailComponentProvider

    init(provider: EventDetailComponentProvider) {
        self.provider = provider
        super.init()
    }

    func generateComponents() {
        var components: [ComponentType] = []
        if let c = provider.buildComponent(for: .header) {
            components.append(c)
        }
        self.components = components
        EventDetail.logDebug("Header space load component count: \(components.count)")
    }
}

// MARK: - Layout
final class EventDetailHeaderLayoutEngine: BaseLayoutEngine<BottomViewSharableKey> {

    override func layout(with views: [UIView]) {
        EventDetail.logDebug("Header space layout view (count: \(views.count))")
        if let view = views.first {
            view.snp.makeConstraints {
                $0.edges.equalToSuperview()
                $0.height.equalToSuperview()
            }
        }
    }
}
