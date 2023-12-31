//
//  VersionHelper.swift
//  OPSDK
//
//  Created by Nicholas Tau on 2020/11/12.
//

import Foundation

public final class VersionHelper{
    
    //versionFirst > versionSecond : return 1;
    //versionFirst = versionSecond : return 0;
    //versionFirst < versionSecond : return -1;
    //if version is invalid format or nil, we consider the version should be lowest
    //but it they're all invalid, we treat them as the same version, return 0
    public static func compareVersions(versionFirst: String?, versionSecond: String?) -> Int{
        let  versionANumber = iosVerion2Int(str: versionFirst ?? "0")
        let  versionBNumber = iosVerion2Int(str: versionSecond ?? "0")
        if (versionANumber > versionBNumber) {
            return 1;
        } else if (versionANumber < versionBNumber) {
            return -1;
        }
        return 0;
    }
    
    /*-----------------------------------------------*/
    //                  Utils - 工具
    /*-----------------------------------------------*/
    private static func iosVerion2Int(str: String) -> Int{
        var parts = str.components(separatedBy: ".")
        if(parts.count == 3){
            parts.append("0")
        }
        if (parts.count != 4){
            return -1
        }
        var iversion = 0
        var ratio = 1
        for (index, value) in parts.enumerated().reversed(){
            let partInt = Int(value) ?? 0
            iversion += ratio * partInt
            ratio = ratio * 100
        }
        return iversion
    }
    
    //1093101 -> 1.1.1.1 类似处理
    public static func versionStringWithContent(content: String) -> String{
        var contentNS = content.trimmingCharacters(in: .whitespacesAndNewlines) as NSString
        if isValidVersion(version:content as String) {
            if contentNS.length < 7 {
                contentNS = ("0000000" as NSString).replacingCharacters(in:NSMakeRange(7 - contentNS.length, contentNS.length),  with: content) as NSString
                var forthStr = contentNS.substring(with: NSMakeRange(contentNS.length - 2, 2)) as NSString
                var thirdStr = contentNS.substring(with: NSMakeRange(contentNS.length - 4, 2)) as NSString
                var secondStr = contentNS.substring(with: NSMakeRange(contentNS.length - 6, 2)) as NSString
                var firstStr = contentNS.substring(to: contentNS.length - 6) as NSString

                forthStr = NSNumber(value: forthStr.integerValue).stringValue as NSString
                thirdStr = NSNumber(value: thirdStr.integerValue).stringValue as NSString
                secondStr = NSNumber(value: secondStr.integerValue).stringValue as NSString
                firstStr = NSNumber(value: firstStr.integerValue).stringValue as NSString

                let version = "\(firstStr).\(secondStr).\(thirdStr).\(forthStr)"
                let versionCode = iosVerion2Int(str: version)
                return versionCode > 0 ? version : "-1"
            }
        }
        return "-1";
    }
    
    private static func isValidVersion(version: String) -> Bool
    {
        if (version.isEmpty||version.count==0) {
            return false;
        }
        let versionSet = CharacterSet.init(charactersIn: version)
        return CharacterSet.decimalDigits.isSuperset(of: versionSet)
    }
}
