//
//  KeyBoardItemsSource.swift
//  LarkOpenPlatform
//
//  Created by 李论 on 2020/1/6.
//

import UIKit
import RxSwift
import EEMicroAppSDK
import LarkOPInterface

public protocol KeyBoardItemSourceApp {
    var app: AuthorizedApp? { get set }
    mutating func setTappedBlock(tap: @escaping (() -> Void))
}

struct KeyBoardItem: KeyBoardItemProtocol & KeyBoardItemSourceApp {
    public var app: AuthorizedApp?
    public var customViewBlock: ((UIView) -> Void)?
    public var icon: UIImage
    public var isShowDot: Bool = false
    public var selectIcon: UIImage?
    public var tapped: () -> Void
    public var text: String
    ///500 ～ 1500，`default` == 1000
    public var priority: Int
    public var badge: String?

    public mutating func setTappedBlock(tap: @escaping (() -> Void)) {
        tapped = tap
    }
}
