//
//  MentionLayoutManager.swift
//  LarkMention
//
//  Created by Yuri on 2022/5/26.
//

import Foundation
import UIKit

final class MentionLayoutManager {
    
    enum LayoutStyle {
        case pad
        case phone
    }
    
    struct MentionLayout {
        /// C屏为0，与屏幕同宽，R屏固定位375
        var width: CGFloat = 0
        var height: CGFloat = 0
        var contentHeight: CGFloat = 100
        var isPad: Bool = false
        var sizeClass: UIUserInterfaceSizeClass = .unspecified
    }
    
    var style: LayoutStyle = .phone
    var screenHeight: CGFloat = UIScreen.main.bounds.height
    var keyboardHeight: CGFloat?
    
    var layout: MentionLayout = MentionLayout()
    var didLayoutUpdateHandler: ((MentionLayout) -> Void)?
    
    var uiParam: MentionUIParameters
    
    init(uiParam: MentionUIParameters? = nil) {
        self.uiParam = uiParam ?? MentionUIParameters()
        self.keyboardHeight = self.uiParam.keyboardHeight
    }
    
    func compute() {
        computeLayout()
    }
    
    fileprivate func computeLayout() {
        if style == .pad {
            computePadLayout()
        } else {
            computePhoneLayout()
        }
    }
    
    private func computePadLayout(with contentHeight: CGFloat? = nil) {
        layout.width = 375
        if let contentHeight = contentHeight {
            layout.height = contentHeight
        }
        if let maxHeight = uiParam.maxHeight, maxHeight > 0 {
            layout.height = min(maxHeight, contentHeight ?? CGFloat.greatestFiniteMagnitude)
        }
    }
    
    private func computePhoneLayout(with contentHeight: CGFloat? = nil) {
        layout.width = 0
        let keyboardH: CGFloat = keyboardHeight ?? 0
        let limitHeight: CGFloat = screenHeight * 0.85
        layout.height = limitHeight
        layout.contentHeight = limitHeight - keyboardH
        if let maxHeight = uiParam.maxHeight, maxHeight > 0 {
            layout.height = min(maxHeight + keyboardH, layout.height)
            layout.contentHeight = layout.height - keyboardH
        }
        if let contentHeight = contentHeight {
            layout.height = min(contentHeight + keyboardH, layout.height)
            layout.contentHeight = layout.height - keyboardH
        }
    }
    
    func updateHeight(_ height: CGFloat? = nil) {
        if style == .pad {
            computePadLayout(with: height)
        } else {
            computePhoneLayout(with: height)
        }
        didLayoutUpdateHandler?(layout)
    }
}
