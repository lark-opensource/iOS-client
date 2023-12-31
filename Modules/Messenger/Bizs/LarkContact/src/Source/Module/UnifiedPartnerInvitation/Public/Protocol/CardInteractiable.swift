//
//  CardInteractiable.swift
//  LarkContact
//
//  Created by shizhengyu on 2020/10/29.
//

import Foundation
enum CardViewType {
    case qrcode
    case link
}

protocol CardInteractiable: AnyObject {
    /// 刷新
    func triggleRefreshAction(cardType: CardViewType)
}
