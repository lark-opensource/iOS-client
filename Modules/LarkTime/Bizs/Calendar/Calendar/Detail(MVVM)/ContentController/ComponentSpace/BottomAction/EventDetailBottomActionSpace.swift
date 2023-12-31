//
//  EventDetailBottomActionSpace.swift
//  Calendar
//
//  Created by Rico on 2021/4/25.
//

import Foundation
import UIKit
import CalendarFoundation

// MARK: - Space

final class EventDetailBottomActionSpace: BaseSpace<EventDetailBottomManager, EventDetailBottomLayoutEngine> {

    init(viewController: UIViewController,
         componentProvider: EventDetailComponentProvider) {

        super.init(manager: EventDetailBottomManager(provider: componentProvider),
                   layoutEngine: EventDetailBottomLayoutEngine(viewController: viewController),
                   viewController: viewController)
    }

    override func loadComponents() {
        manager.generateBottomActionComponents()
        manager.components.forEach { component in
            component.viewController = viewController
        }
    }

    func reloadComponents() {
        loadComponents()
    }
}

// MARK: - Manager
final class EventDetailBottomManager: BaseManager {

    let provider: EventDetailComponentProvider

    var bottomAction: ComponentType?

    init(provider: EventDetailComponentProvider) {
        self.provider = provider
        super.init()
    }

    func generateBottomActionComponents() {
        var components: [ComponentType?] = []

        if provider.shouldLoadComponent(for: .bottomAction) {
            if bottomAction == nil {
                // 新建component
                bottomAction = provider.buildComponent(for: .bottomAction)
            } else {
                // do nothing
            }
        } else {
            if bottomAction == nil {
                // do nothing
            } else {
                // 删除
                bottomAction = nil
            }
        }
        components.append(bottomAction)
        self.components = components.compactMap { $0 }
        EventDetail.logInfo("bottom action build component. bottomAction: \(bottomAction != nil)")
    }
}

// MARK: - Layout

enum BottomViewSharableKey {
    case bottomActionBar
}

protocol BottomViewSharable {
    func provideView(for key: BottomViewSharableKey) -> UIView?
}

final class EventDetailBottomLayoutEngine: BaseLayoutEngine<BottomViewSharableKey> {

    weak var viewController: UIViewController?

    init(viewController: UIViewController) {
        self.viewController = viewController
    }

    override func layout(with views: [UIView]) {
        EventDetail.logInfo("bottom action layout view. count: \(views.count)")
        if let view = views.first,
           let viewController = viewController {
            view.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }
        }
    }

    override func view(for key: BottomViewSharableKey, in components: [ComponentType]) -> UIView? {
        for component in components {
            if let c = component as? BottomViewSharable {
                return c.provideView(for: key)
            }
        }
        return nil
    }
}
