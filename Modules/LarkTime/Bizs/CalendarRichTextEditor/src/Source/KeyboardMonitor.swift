//
//  RichTextKeyboardMonitor.swift
//  SpaceKit
//
//  Created by weidong fu on 2018/12/11.
//

import UIKit
import Foundation

protocol KeyboardMonitorDelegate: AnyObject {
    var richTextView: UIView { get }
    var richTextInputAccessory: UIView? { get }
    func keyboardMonitor(_ monitor: KeyboardMonitor, didChange keyboardInfo: KeyBoadInfo)
    func updateWebViewOldContentOffset()
    func setWebViewScroll(isEnable: Bool)
}

struct KeyBoadInfo {

    let height: CGFloat
    let isShow: Bool
    let trigger: String

    init(height: CGFloat, isShow: Bool, trigger: String) {
        self.height = height
        self.isShow = isShow
        self.trigger = trigger
    }
}

final class KeyboardMonitor {
    weak var delegate: KeyboardMonitorDelegate?
    let keyboard: Keyboard = Keyboard()
    let toolbarHeight = 44
    var keyboardShowTime: Int = 0
    init() {
        keyboard.on(events: [.didHide, .willShow, .willHide, .didShow]) { [weak self] (options) in
            self?.handleKeyboardEvent(options)
        }
    }

    func start() { keyboard.start() }

    func stop() { keyboard.stop() }

    func handleKeyboardEvent(_ options: Keyboard.KeyboardOptions) {
        guard let richTextView = delegate?.richTextView, richTextView.frame.size.height > 0 else { return }
        let innerHeight = fixKeyboardHeight(options.endFrame.size.height, richTextView)

        switch options.event {
        case .willShow:
            handleWillShowEvent(options, fixedInnerHeight: innerHeight)
        case .willHide:
            if !keyboard.isHiding {
                keyboardShowTime = 0
                delegate?.setWebViewScroll(isEnable: true)
            }
        case .didHide:
            delegate?.setWebViewScroll(isEnable: true)
            let keyboardInfo = KeyBoadInfo(height: innerHeight,
                                               isShow: false,
                                               trigger: "editor")
            delegate?.keyboardMonitor(self, didChange: keyboardInfo)
        case .willChangeFrame:
            delegate?.setWebViewScroll(isEnable: true)
            let keyboardInfo = KeyBoadInfo(height: innerHeight,
                                               isShow: true,
                                               trigger: "editor")
            delegate?.keyboardMonitor(self, didChange: keyboardInfo)
        default:
            return
        }
    }

    private func handleWillShowEvent(_ options: Keyboard.KeyboardOptions, fixedInnerHeight: CGFloat) {
        delegate?.setWebViewScroll(isEnable: true)
        let keyboardInfo = KeyBoadInfo(height: fixedInnerHeight,
                                           isShow: true,
                                           trigger: "editor")
        delegate?.keyboardMonitor(self, didChange: keyboardInfo)
    }

    private func fixKeyboardHeight(_ keyboardHeight: CGFloat, _ richTextView: UIView) -> CGFloat {
        var keyboardHeight = keyboardHeight
        if let inputAccessoryView = delegate?.richTextInputAccessory {
            keyboardHeight -= inputAccessoryView.frame.height
        }
        keyboardHeight += 44
        let innerHeight = richTextView.frame.size.height - keyboardHeight
        Logger.info("RichText 键盘高度修正结果:\(keyboardHeight)  \(richTextView.frame.size.height) innerHeight:\(innerHeight)  ")
        return innerHeight
    }
}
