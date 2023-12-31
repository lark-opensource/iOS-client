//
//  ParticipantBaseLabel.swift
//  ByteView
//
//  Created by wulv on 2022/7/20.
//

import Foundation

class ParticipantBaseLabel: PaddingLabel {
    private var cacheBgColor: UIColor?

    override var isHighlighted: Bool {
        willSet {
            guard #available(iOS 13.0, *) else {
                if backgroundColor != .clear {
                    cacheBgColor = backgroundColor
                }
                return
            }
        }
        didSet {
            guard #available(iOS 13.0, *) else {
                if isHighlighted, let cacheBgColor = cacheBgColor {
                    backgroundColor = cacheBgColor
                }
                return
            }
        }
    }
}
