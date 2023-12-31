//
//  UDOCIconBridge.swift
//  TTMicroApp
//
//  Created by ChenMengqi on 2022/6/28.
//

import Foundation
import UniverseDesignIcon

@objc public enum UDOCIConKey: Int, CaseIterable {
    case UDOCIConKeyCloseOutlined
    case UDOCIConKeyCloseMoreOutlined
    case UDOCIConKeyRightBoldOulined
}

@objc
open class UDOCIconBridge: NSObject {
    @objc static public func getIconByKey(key: UDOCIConKey) -> UIImage {
        if key ==  .UDOCIConKeyCloseOutlined {
            return UDIcon.getIconByKey(.closeOutlined)
        } else if(key == .UDOCIConKeyCloseMoreOutlined){
            return UDIcon.getIconByKey(.moreOutlined)
        } else if(key == .UDOCIConKeyRightBoldOulined) {
            return UDIcon.getIconByKey(.rightOutlined)
        }
        assert(false, "should get a right key for icon")
        return UIImage()
    }
    
    @objc static public func getIconByKey(_ key: UDOCIConKey, renderingMode: UIImage.RenderingMode = .automatic, iconColor: UIColor? = nil) -> UIImage {
        var mappedkey: UniverseDesignIcon.UDIconType
        if key ==  .UDOCIConKeyCloseOutlined {
            mappedkey = .closeOutlined
        } else if(key == .UDOCIConKeyCloseMoreOutlined){
            mappedkey = .moreOutlined
        } else if(key == .UDOCIConKeyRightBoldOulined) {
            mappedkey = .rightBoldOutlined
        } else {
            assert(false, "should get a right key for icon")
            return UIImage()
        }
        
        return UDIcon.getIconByKey(mappedkey,renderingMode: renderingMode,iconColor: iconColor)
    }
    
    @objc static public func closeOutlined() -> UIImage {
        return UDIcon.closeOutlined.ud.withTintColor(UIColor.ud.iconN1)
    }
    
    @objc static public func leftOutlined() -> UIImage {
        return UDIcon.leftOutlined.ud.withTintColor(UIColor.ud.iconN1)
    }
}
