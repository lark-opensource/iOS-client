//
//  UniqueNameUtil.swift
//  SKFoundation
//
//  Created by zengsenyuan on 2022/5/25.
//

import Foundation

public struct UniqueNameUtil {
    
    public static func makeUniqueName(extention: String?) -> String {
        if let extention = extention {
            return makeUniqueId() + "." + extention
        } else {
            return makeUniqueId()
        }
    }
    
    public static func makeUniqueImageName() -> String {
        let imageNamePrefix = "photo_"
        let imageNameSuffix = ".JPG"
        return imageNamePrefix + getTimeStamp() + imageNameSuffix
    }
    
    public static func makeUniqueNewImageName() -> String {
        let imageNamePrefix = "photo_"
        let imageNameSuffix = ".JPEG"
        return imageNamePrefix + getTimeStamp() + imageNameSuffix
    }

    public static func makeUniqueVideoName() -> String {
        return makeUniqueName(extention: ".MOV")
    }

    public static func makeUniqueId() -> String {
        let rawUUID = UUID().uuidString
        let uuid = rawUUID.replacingOccurrences(of: "-", with: "")
        return uuid.lowercased()
    }

    private static func getTimeStamp() -> String {
        let time = Int64(Date().timeIntervalSince1970 * 1000)
        return String(time)
    }
}
