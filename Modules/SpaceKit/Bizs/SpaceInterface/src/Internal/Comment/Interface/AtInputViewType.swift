//
//  AtInputViewType.swift
//  SpaceInterface
//
//  Created by huayufan on 2023/3/28.
//  


import Foundation

public protocol AtInputViewType: UIView {
    var focusType: AtInputFocusType { get }
    var isSelectingImage: Bool { get }
    var commentWrapper: CommentWrapper?  { get }
    func clearAllContent()
    func shrinkTextView(maxHeight: CGFloat)
    func textViewResignFirstResponder()
    func textViewIsFirstResponder() -> Bool
    func textviewBecomeFirstResponder()
    func forceVoiceButtonHidden(isHidden: Bool)
    func update(imageList: [CommentImageInfo], attrText: NSAttributedString)
}

public struct AtInputViewInitParams {
    public var dependency: AtInputTextViewDependency?
    public var font: UIFont
    public var ignoreRotation: Bool
    public init(dependency: AtInputTextViewDependency?, font: UIFont, ignoreRotation: Bool) {
        self.dependency = dependency
        self.font = font
        self.ignoreRotation = ignoreRotation
    }
}
