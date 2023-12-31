//
//  FocusTagViewProtocol.swift
//  LarkFocusInterface
//
//  Created by 白镜吾 on 2023/1/6.
//

import Foundation
import UIKit
import RustPB

public protocol FocusTagViewAPI: UIView {
    func config(with focusStatus: RustPB.Basic_V1_Chatter.ChatterCustomStatus)
}
