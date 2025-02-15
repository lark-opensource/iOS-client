//
//  InterpreterChannelSegmentedControl+UIPointerInteractionDelegate.swift
//  ByteView
//
//  Created by fakegourmet on 2020/10/25.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit

@available(iOS 13.4, *)
extension InterpreterChannelSegmentedControl: UIPointerInteractionDelegate {
    func pointerInteraction(_ interaction: UIPointerInteraction,
                            regionFor request: UIPointerRegionRequest,
                            defaultRegion: UIPointerRegion) -> UIPointerRegion? {
        let closestIndexToRequestRegion = closestIndex(toPoint: request.location)
        let view = (closestIndexToRequestRegion == index) ? indicatorView : pointerInteractionViews[closestIndexToRequestRegion]
        pointerInteractionView = view
        return .init(rect: view.frame)
    }

    func pointerInteraction(_ interaction: UIPointerInteraction,
                            styleFor region: UIPointerRegion) -> UIPointerStyle? {
        guard let view = pointerInteractionView else {
            return nil
        }

        if view === indicatorView {
            return .init(effect: .lift(.init(view: view)))
        }
        return .init(effect: .highlight(.init(view: view)))
    }
}
