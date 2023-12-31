//
//  Resources.swift
//  LarkFinance
//
//  Created by ChalrieSu on 2018/6/28.
//

import Foundation
import UIKit
import UniverseDesignIcon
import UniverseDesignEmpty

final class Resources {
    private static func image(named: String) -> UIImage {
        return UIImage(named: named, in: LarkFinanceBundle, compatibleWith: nil) ?? UIImage()
    }
    static let balance = Resources.image(named: "balance")
    static let hongbao_close = Resources.image(named: "hongbao_close")
    static let red_packet_open = Resources.image(named: "red_packet_open")
    static let red_packet_open_highlight = Resources.image(named: "red_packet_open_highlight")
    static let red_packet_back = Resources.image(named: "red_packet_back").ud.withTintColor(UIColor.ud.Y200.alwaysLight)
    static let red_packet_result_close = Resources.image(named: "red_packet_result_close")
    static let red_packet_close = UDIcon.getIconByKey(.closeOutlined, size: CGSize(width: 19, height: 19)).ud.withTintColor(UIColor.ud.R600.alwaysLight)
    static let red_patcket_year = UDIcon.getIconByKey(.downOutlined, size: CGSize(width: 12, height: 12)).ud.withTintColor(UIColor.ud.iconN1)
    static let wallet_top = Resources.image(named: "wallet_top")
    static let wallet_help = Resources.image(named: "wallet_help")
    static let wallet_secure = Resources.image(named: "wallet_secure")
    static let wallet_transaction = Resources.image(named: "wallet_transaction")
    static let wallet_bank_card = Resources.image(named: "wallet_bank_card")
    static let hongbao_open_bottom = Resources.image(named: "hongbao_open_bottom")
    static let hongbao_card_background = Resources.image(named: "hongbao_card_background")
    static let hongbao_open_top = Resources.image(named: "hongbao_open_top")
    static let hongbao_result_avatar_border = Resources.image(named: "hongbao_result_avatar_border")
    static let hongbao_result_bottom_shadow = Resources.image(named: "hongbao_result_bottom_shadow")
    static let hongbao_result_mask = Resources.image(named: "hongbao_result_mask")
    static let warning = Resources.image(named: "warning")
    static let exclusiveReceiveAvatarBorder = Resources.image(named: "exclusive_receive_avatar_border")
    static let right_arrow = UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 13, height: 13)).ud.withTintColor(UIColor.ud.iconN2)
}
