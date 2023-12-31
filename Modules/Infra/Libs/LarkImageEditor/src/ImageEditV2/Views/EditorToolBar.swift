//
//  EditorToolBar.swift
//  LarkImageEditor
//
//  Created by 王元洵 on 2021/7/30.
//

import UIKit
import Foundation

protocol EditorToolBar: UIView {
    func animateHideToolBar(completion: (() -> Void)?)
    func animateShowToolBar()
    func updateCurrentViewWidth(_ width: CGFloat)

    var heightForIphone: CGFloat { get }
    var heightForIpad: CGFloat { get }
}

protocol EditorToolBarDelegate: AnyObject {
    func changeWidth(with width: CGFloat, defaultWidth: CGFloat)
    func changeColor(with color: ColorPanelType)
    func finishButtonDidClicked(in toolbar: EditorToolBar)
    func sliderTimerTicked()
    func eventOccured(eventName: String, params: [String: Any])
}

extension EditorToolBar {
    func animateHideToolBar() { animateHideToolBar(completion: nil) }
}
