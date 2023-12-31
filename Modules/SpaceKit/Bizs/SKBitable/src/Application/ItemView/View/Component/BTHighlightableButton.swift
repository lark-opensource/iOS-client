//
//  BTHighlightableButton.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/4/24.
//  


import Foundation
import SKUIKit

/// 为了解决在 cell 中轻点不高亮的问题： https://stackoverflow.com/questions/22924817/ios-delayed-touch-down-event-for-uibutton-in-uitableviewcell
class BTHighlightableButton: SKHighlightButton {

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        isHighlighted = true
        super.touchesBegan(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isHighlighted = false
        super.touchesEnded(touches, with: event)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isHighlighted = false
        super.touchesCancelled(touches, with: event)
    }
}
