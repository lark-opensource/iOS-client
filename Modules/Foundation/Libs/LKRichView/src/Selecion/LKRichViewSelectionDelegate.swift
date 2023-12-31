//
//  LKRichViewSelectionDelegate.swift
//  LKRichView
//
//  Created by 白言韬 on 2022/1/6.
//

import UIKit
import Foundation

public protocol LKRichViewSelectionDelegate: AnyObject {
    func willDragCursor(_ view: LKRichView)
    func didDragCursor(_ view: LKRichView)
    func handleCopyByCommand(_ view: LKRichView, text: NSAttributedString?)
}

extension LKRichViewSelectionDelegate {
    func willDragCursor(_ view: LKRichView) { }
    func didDragCursor(_ view: LKRichView) { }
    func handleCopyByCommand(_ view: LKRichView, text: NSAttributedString?) {}
}
