//
//  EventDetailNavigationLayoutEngine.swift
//  Calendar
//
//  Created by Rico on 2021/3/16.
//

import CalendarFoundation
import Foundation
import UIKit

// MARK: - Layout

enum NavigationViewSharableKey {
    case navigationBar
}

protocol NavigationViewSharable {
    func provideView(for key: NavigationViewSharableKey) -> UIView?
}

final class EventDetailNavigationLayoutEngine: BaseLayoutEngine<NavigationViewSharableKey> {

    override func layout(with views: [UIView]) {
        EventDetail.logDebug("navigation space layout view (count: \(views.count))")
        views.forEach {
            $0.snp.edgesEqualToSuperView()
        }
    }

    override func view(for key: NavigationViewSharableKey, in components: [ComponentType]) -> UIView? {
        for component in components {
            if let c = component as? NavigationViewSharable {
                return c.provideView(for: key)
            }
        }
        return nil
    }
}
