//
//  InlineAIBackgroudMaskView.swift
//  LarkInlineAI
//
//  Created by Guoxinyi on 2023/4/25.
//

import Foundation
import UIKit

protocol InlineAIBackgroudMaskViewDelegate: AnyObject {
    func didClickMaskErea(gesture: UIGestureRecognizer)
}

final class InlineAIBackgroudMaskView: InlineAIItemBaseView {
    
    weak var delegate: InlineAIBackgroudMaskViewDelegate?
    
    init(frame: CGRect, delegate: InlineAIBackgroudMaskViewDelegate?) {
        super.init(frame: frame)
        self.delegate = delegate
        self.backgroundColor = .clear
        
        let control = UIControl(frame: frame)
        self.addSubview(control)
        control.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.width.height.equalToSuperview()
        }
        control.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didClickMaskView(gesture:))))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    private func didClickMaskView(gesture: UIGestureRecognizer) {
        self.delegate?.didClickMaskErea(gesture: gesture)
    }
}
