//
//  JiraPatternUtil.swift
//  SpaceKit
//
//  Created by lizechuang on 2020/1/7.
//

import Foundation

public final class JiraPatternUtil {
    static let PROTOCOLREGEX = "https?|s?ftp|ftps|nfs|ssh"
    static let CLOUDREGEX = ".+\\.atlassian"
    static let SERVERREGEX = ".*jira.*\\..+"
    static let TOP10DOMAIN = "com|cn|tk|de|net|org|uk|info|nl|ru"

    //判断是否为jira链接（普通链接+私有化部署链接）
    public static func checkIsJiraDomain(url: String) -> Bool {
        let urlRegex = "(\(PROTOCOLREGEX))?(\(CLOUDREGEX))|(\(SERVERREGEX))\\.(\(TOP10DOMAIN))"
//        let urlRegex = "(https?|s?ftp|ftps|nfs|ssh)?(.+\\.atlassian)|(.*jira.*\\..+)\\.(com|cn|tk|de|net|org|uk|info|nl|ru)"
        do {
            let regex = try NSRegularExpression(pattern: urlRegex)
            let urlStr = url as NSString
            let results = regex.matches(in: url, range: NSRange(location: 0, length: urlStr.length))
            let matchStr = results.map { urlStr.substring(with: $0.range) }
            return !matchStr.isEmpty
        } catch {
            return false
        }
    }

    //判断是否为普通jira链接
    public static func checkIsCommonJiraDomain(url: String) -> Bool {
        let urlRegex = "(\(PROTOCOLREGEX))?(\(CLOUDREGEX))\\.(\(TOP10DOMAIN))"
        do {
            let regex = try NSRegularExpression(pattern: urlRegex)
            let urlStr = url as NSString
            let results = regex.matches(in: url, range: NSRange(location: 0, length: urlStr.length))
            let matchStr = results.map { urlStr.substring(with: $0.range) }
            return !matchStr.isEmpty
        } catch {
            return false
        }
    }
}
