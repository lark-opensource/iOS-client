//
//  InterpreterChannelSegmentedControl+Rx.swift
//  ByteView
//
//  Created by fakegourmet on 2020/10/26.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import RxSwift
import RxCocoa

extension Reactive where Base: InterpreterChannelSegmentedControl {
    /// Reactive wrapper for `selectedSegmentIndex` property.
    var selectedSegmentIndex: ControlProperty<Int> {
        return base.rx.controlProperty(
            editingEvents: [.allEditingEvents, .valueChanged],
            getter: { segmentedControl in
                segmentedControl.index
            },
            setter: { segmentedControl, value in
                segmentedControl.setIndex(value)
            })
    }

    var segments: Binder<([InterpreterChannelSegment], Int)> {
        return Binder(self.base) { (segmentedControl, arg1) -> Void in
            let (segments, defaultIndex) = arg1
            segmentedControl.segments = segments
            if defaultIndex > 0 {
                segmentedControl.setIndex(defaultIndex, animated: false, shouldSendValueChangedEvent: false)
            }
        }
    }
}
