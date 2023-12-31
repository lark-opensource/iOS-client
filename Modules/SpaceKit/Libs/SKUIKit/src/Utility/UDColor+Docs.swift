//
//  UDColor+Docs.swift
//  SKUIKit
//
//  Created by lijuyou on 2022/3/30.
//  


import Foundation
import SKFoundation
import UniverseDesignColor
import UIKit

extension UDColor: SKExtensionCompatible {}

extension SKExtension where Base == UDColor {
    
    //ccmtoken-color-bitable-brand
    public static var bitableBrand: UIColor {
        return #colorLiteral(red: 0.7083181739, green: 0.4779424071, blue: 0.9381451607, alpha: 1) //#A45EEB
    }
}

public extension UDColor.Name {
    static let ccmMessageCardBgBodyThumbnail = UDColor.Name("ccmtoken-message-card-bg-body-thumbnail")
    static let ccmMessageCardParagraphBgBody = UDColor.Name("ccmtoken-message-card-paragraph-bg-body")
    static let ccmMessageCardParagraphBgBodyThumbnail = UDColor.Name("ccmtoken-message-card-paragraph-bg-body-thumbnail")
}

public struct UDCCMColorTheme {

    public static var ccmMessageCardBgBodyThumbnail: UIColor {
        UDColor.getValueByKey(.ccmMessageCardBgBodyThumbnail) ?? UDColor.N00 & UDColor.rgb(0xE0E0E0)
    }

    public static var ccmMessageCardParagraphBgBody: UIColor {
        UDColor.getValueByKey(.ccmMessageCardParagraphBgBody) ?? UDColor.N50 & UDColor.N200
    }

    public static var ccmMessageCardParagraphBgBodyThumbnail: UIColor {
        UDColor.getValueByKey(.ccmMessageCardParagraphBgBodyThumbnail) ?? UDColor.N50 & UDColor.rgb(0xD8D8D9)
    }
}

public struct UDCCMBizColor: UDBizColor {

    public init() {}

    public func getValueByToken(_ token: String) -> UIColor? {
        let tokenName = UDColor.Name(token)
        switch tokenName {
        case .ccmMessageCardBgBodyThumbnail:
            return UDCCMColorTheme.ccmMessageCardBgBodyThumbnail
        case .ccmMessageCardParagraphBgBody:
            return UDCCMColorTheme.ccmMessageCardParagraphBgBody
        case .ccmMessageCardParagraphBgBodyThumbnail:
            return UDCCMColorTheme.ccmMessageCardParagraphBgBodyThumbnail
        default:
            return nil
        }
    }
}
