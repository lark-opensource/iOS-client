//
//  RedPacketResultView.swift
//  LarkFinance
//
//  Created by SuPeng on 4/1/19.
//

import Foundation
import UIKit

protocol RedPacketResultViewDelegate: AnyObject {
    func hitTestView(_ point: CGPoint, with event: UIEvent?) -> UIView?
}

final class RedPacketResultView: UIView {
    weak var delegate: RedPacketResultViewDelegate?

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return delegate?.hitTestView(point, with: event) ?? super.hitTest(point, with: event)
    }
}
