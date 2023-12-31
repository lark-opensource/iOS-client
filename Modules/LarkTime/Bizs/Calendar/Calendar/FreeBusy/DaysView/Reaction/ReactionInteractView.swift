//
//  ReactionInteractView.swift
//  Calendar
//
//  Created by zhouyuan on 2018/9/17.
//  Copyright © 2018年 EE. All rights reserved.
//

import UIKit
import Foundation
import CalendarFoundation

final class ReactionInteractView: UIView {

    var contentInset: UIEdgeInsets = UIEdgeInsets.zero

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let resultView = super.hitTest(point, with: event)
        if resultView === self {
            return nil
        }
        return resultView
    }
}
