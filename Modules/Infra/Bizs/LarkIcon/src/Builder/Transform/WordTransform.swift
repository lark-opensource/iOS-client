//
//  WorkTransform.swift
//  LarkIcon
//
//  Created by huangzhikai on 2023/12/15.
//

import Foundation
import UniverseDesignColor
class WorkTransform: LarkIconTransformProtocol {
    private let word: String?
    private var color: UIColor?

    init(word: String?, color: UIColor? = UDColor.R50) {
        self.word = word
        self.color = color
    }

    func beginTransform(with context: CGContext, builderExtend: BuilderExtend) {
        
        guard let word = self.word else {
            return
        }
        
        let lableRect = CGRect(x: 0, y: 0, width: builderExtend.canvasSize.width, height: builderExtend.canvasSize.height)
        let label = UILabel(frame: lableRect)
        
        label.font = UIFont.systemFont(ofSize: label.frame.size.width / 1.77, weight: .medium)
        label.textAlignment = .center
        label.text = word
        label.textColor = self.color
        label.layer.render(in: context)

    }
    
}
