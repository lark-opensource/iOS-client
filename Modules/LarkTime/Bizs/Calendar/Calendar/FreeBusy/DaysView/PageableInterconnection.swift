//
//  PageableInterconnection.swift
//  Calendar
//
//  Created by linlin on 2018/5/21.
//  Copyright © 2018年 EE. All rights reserved.
//

import UIKit
import Foundation
import CalendarFoundation
import LarkDatePickerView

final class ScrollViewInterconnection {

    private var obvA: NSKeyValueObservation?
    private var obvB: NSKeyValueObservation?

    private var isInSingle: Bool = false

    init() {
    }

    func horizontalCompletelySynchronized(scrollViewA: UIScrollView,
                                          scrollViewB: UIScrollView) {
        self.obvA?.invalidate()
        self.obvB?.invalidate()

        self.obvA = scrollViewA
            .observe(\.contentOffset, options: [.new, .old]) { [weak self] (_, value) in
                guard let `self` = self,
                    let newValue = value.newValue?.x,
                    let oldValue = value.oldValue?.x,
                    !self.isInSingle,
                    oldValue != 0 else {
                        return
                }
                self.isInSingle = true
                scrollViewB.contentOffset = CGPoint(x: newValue, y: scrollViewB.contentOffset.y)
                scrollViewB.layoutIfNeeded()
                self.isInSingle = false
            }

        self.obvB = scrollViewB
            .observe(\.contentOffset, options: [.new, .old]) { [weak self] (_, value) in
                guard let `self` = self,
                    let newValue = value.newValue?.x,
                    let oldValue = value.oldValue?.x,
                    !self.isInSingle,
                    oldValue != 0 else {
                        return
                }
                self.isInSingle = true
                scrollViewA.contentOffset = CGPoint(x: newValue, y: scrollViewA.contentOffset.y)
                scrollViewA.layoutIfNeeded()
                self.isInSingle = false
            }
    }

}
