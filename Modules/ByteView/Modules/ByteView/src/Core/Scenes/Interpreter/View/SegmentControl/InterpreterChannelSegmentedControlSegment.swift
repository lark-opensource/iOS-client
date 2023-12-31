//
//  InterpreterChannelSegmentedControlSegment.swift
//  ByteView
//
//  Created by fakegourmet on 2020/10/25.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

protocol InterpreterChannelSegment {
    /// If provided, `InterpreterChannelSegmentedControl` will use its value to calculate an `intrinsicContentSize` based on this.
    var intrinsicContentSize: CGSize? { get }
    /// The view to be shown for the normal or unselected state.
    var normalView: UIView { get }
    /// The view to be shown for the active or selected state.
    var selectedView: UIView { get }
}
