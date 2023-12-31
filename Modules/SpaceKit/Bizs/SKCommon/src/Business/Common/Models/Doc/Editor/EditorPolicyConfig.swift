//
//  EditorPolicyConfig.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/6/12.
//  

import SKFoundation
import SKInfra

public enum EditorAddToViewTime: String, Equatable {
    case viewDidLoad = "viewdidload"
    case viewWillAppear = "viewwillappear"
    case viewDidAppear = "viewdidappear"
    public static let `default` = EditorAddToViewTime.viewWillAppear
}

extension OpenAPI {
    public static var editorAddToViewTime: EditorAddToViewTime {
        get {
            let str = CCMKeyValue.globalUserDefault.string(forKey: UserDefaultKeys.editorAddToViewTimeKey) ?? ""
            return EditorAddToViewTime(rawValue: str) ?? EditorAddToViewTime.default
        }
        set {
            DocsLogger.info("set addtoview time to \(newValue.rawValue)", component: LogComponents.fileOpen)
            CCMKeyValue.globalUserDefault.set(newValue.rawValue, forKey: UserDefaultKeys.editorAddToViewTimeKey)
        }
    }
}
