//
//  CustomView.swift
//  LarkSuspendableDev
//
//  Created by bytedance on 2021/1/10.
//

import Foundation
import UIKit

class VideoView: UIView {

    init() {
        super.init(frame: .zero)
        backgroundColor = .black
        print("\(address) created")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        print("\(address) destroyed")
    }

    var address: String {
        return "<\(String(reflecting: type(of: self))): "
            + "\(Unmanaged.passUnretained(self).toOpaque())>"
    }
}
