//
//  EventCardView.swift
//  Calendar
//
//  Created by heng zhu on 2019/6/23.
//

import UIKit
import Foundation
import CalendarFoundation

public final class EventCardView: UIView {
    public var onTapped: ((EventCardView) -> Void)?

    #if !LARK_NO_DEBUG
    public var convenientDebug: (() -> Void)?
    #endif

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        #if !LARK_NO_DEBUG
        if FG.canDebug,
           event?.allTouches?.count == 2 {
            self.convenientDebug?()
            return
        }
        #endif
        self.onTapped?(self)
    }
}
