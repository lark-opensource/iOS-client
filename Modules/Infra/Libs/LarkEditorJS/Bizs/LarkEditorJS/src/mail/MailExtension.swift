//
//  MailExtension.swift
//  LarkEditorJS
//
//  Created by tefeng liu on 2020/5/28.
//

import Foundation

// 业务方自行增加接口例如：
public class MailExtension<BaseType> {
    var base: BaseType
    init(_ base: BaseType) {
        self.base = base
    }
}
public protocol MailExtensionCompatible {
    associatedtype MailCompatibleType
    var mail: MailCompatibleType { get }
    static var mail: MailCompatibleType.Type { get }
}
public extension MailExtensionCompatible {
    var mail: MailExtension<Self> {
        return MailExtension(self)
    }
    static var mail: MailExtension<Self>.Type {
        return MailExtension.self
    }
}

extension LarkEditorJS: MailExtensionCompatible {}

public extension MailExtension where BaseType == LarkEditorJS {
    public static func getEditorHtmlPath() -> String {
        return CommonJSUtil.executeFilesPath + "/mail_editor_index.html"
    }
    public static func getEditorHtmlPathOld() -> String {
        return CommonJSUtil.executeFilesPath + "/mail_editor_index_old.html"
    }
}
