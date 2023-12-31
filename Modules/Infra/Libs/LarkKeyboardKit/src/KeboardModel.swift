//
//  KeboardModel.swift
//  KeyboardKit
//
//  Created by 李晨 on 2019/10/17.
//

import UIKit
import Foundation

/// Keyboard Options in UIKeyboard notifications
public struct KeyboardOptions {

    /// Keyboard belongs to current app
    public let belongsToCurrentApp: Bool

    /// Keyboard animation start frame
    public let startFrame: CGRect

    /// Keyboard animation end frame
    public let endFrame: CGRect

    /// Keyboard animation curve
    public let animationCurve: UIView.AnimationCurve

    /// Keyboard animation duration
    public let animationDuration: Double

    /// Keyboard animation animation options
    public var animationOptions: UIView.AnimationOptions {
        switch self.animationCurve {
        case UIView.AnimationCurve.easeIn:
            return UIView.AnimationOptions.curveEaseIn
        case UIView.AnimationCurve.easeInOut:
            return UIView.AnimationOptions.curveEaseInOut
        case UIView.AnimationCurve.easeOut:
            return UIView.AnimationOptions.curveEaseOut
        case UIView.AnimationCurve.linear:
            return UIView.AnimationOptions.curveLinear
        @unknown default:
            return .init(rawValue: UInt(self.animationCurve.rawValue << 16))
        }
    }
}

/// Keyboard events that can happen. Translates directly to `UIKeyboard` notifications from UIKit.
public struct KeyboardEvent {
    /// event type
    public enum TypeEnum: CaseIterable {
        /// Event raised by UIKit's `.UIKeyboardWillShow`.
        case willShow

        /// Event raised by UIKit's `.UIKeyboardDidShow`.
        case didShow

        /// Event raised by UIKit's `.UIKeyboardWillShow`.
        case willHide

        /// Event raised by UIKit's `.UIKeyboardDidHide`.
        case didHide

        /// Event raised by UIKit's `.UIKeyboardWillChangeFrame`.
        case willChangeFrame

        /// Event raised by UIKit's `.UIKeyboardDidChangeFrame`.
        case didChangeFrame

        /// UIResponder keyboard notification name
        var notification: Notification.Name {
            switch self {
            case .willChangeFrame: return UIResponder.keyboardWillChangeFrameNotification
            case .didChangeFrame: return UIResponder.keyboardDidChangeFrameNotification
            case .willShow: return UIResponder.keyboardWillShowNotification
            case .didShow: return UIResponder.keyboardDidShowNotification
            case .willHide: return UIResponder.keyboardWillHideNotification
            case .didHide: return UIResponder.keyboardDidHideNotification
            }
        }
    }

    /// Keyboard event type
    public let type: TypeEnum

    /// Keyboard model
    public let keyboard: Keyboard

    /// Keyboard options
    public let options: KeyboardOptions
}

/// Keyboard Model
public struct Keyboard {

    /// Keyboard Type
    public enum TypeEnum {
        /// system keyboard
        case system
        /// hardware keyboard
        case hardware
        /// UIResponder custom inputView
        case customInputView
    }

    /// Keyboard Display Type
    public enum DisplayType {
        /// default display type
        case `default`
        /// float display type
        case float
        /// splitOrUnlock display type
        case splitOrUnlock
    }

    /// Keyboard type
    public var type: TypeEnum

    /// Keyboard Display Type
    public var displayType: DisplayType

    /// Keyboard belongs to current app
    public var belongsToCurrentApp: Bool

    /// Keyboard frame
    public var frame: CGRect

    /// Keyboard Accessory View Height
    public var inputAccessoryHeight: CGFloat
}

final class FirstResponderProxy {
    weak var firstResponder: UIResponder?

    init(firstResponder: UIResponder? = nil) {
        self.firstResponder = firstResponder
    }
}
