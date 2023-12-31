//
//  IMMentionTracker.swift
//  LarkIMMention
//
//  Created by jiangxiangrui on 2022/8/8.
//

import Foundation
import CommonCrypto

// 埋点展示用
enum PickerIMMentionTraker {
    /// 面板展示时
    case show
    /// 点击多选按钮切换模式
    case multiSelect
    /// 点击确认
    case mentionConfirm
}

#if canImport(LKCommonsTracker)
import LKCommonsTracker
#endif

public struct TrackerInfo {
    // 页面类型，“all，user，doc”
    var pageType: PageType
    // 选择来源， “recommmend，search”
    var chooseType: ChooseType
}

public enum PageType {
    case unknown
    case all
    case user
    case doc
}

public enum ChooseType {
    case unknown
    case recommend
    case search
}

final class IMMentionTraker {
    
    func imMentionTrakerPost(action: PickerIMMentionTraker, targer: String? = nil,
                             items: [IMMentionOptionType]? = nil) {
        // 埋点上传参数
        var click: String?
        var itemInfo: [ String : String ]
        var mentionObj: [String]
        
        var params: [AnyHashable : Any] = [:]
        switch action {
        case .show: break
        case .mentionConfirm:
            click = "mention_confirm"
            guard let items = items else { break }
            mentionObj = []
            for item in items {
                itemInfo = [:]
                
                switch item.type {
                case .chatter:
                    itemInfo["mention_type"] = "user"
                    if item.id == "all" {
                        itemInfo["mention_type"] = "all_user"
                    }
                case .document: itemInfo["mention_type"] = "doc"
                case .wiki: itemInfo["mention_type"] = "doc"
                default: break
                }
                
                itemInfo["mention_obj_id"] = item.id?.md5()
                
                switch item.trackerInfo.pageType {
                case .all: itemInfo["page_type"] = "all"
                case .user: itemInfo["page_type"] = "user"
                case .doc: itemInfo["page_type"] = "doc"
                default: break
                }
                
                switch item.trackerInfo.chooseType {
                case .search: itemInfo["choose_type"] = "search"
                case .recommend: itemInfo["choose_type"] = "recommend"
                default: break
                }
                mentionObj.append(dicValueString(itemInfo) ?? "" )
            }
            params["mention_obj"] = mentionObj.joined(separator: ",")

        case .multiSelect:
            click = "multi_select"
        }
        params["click"] = click
        params["target"] = targer
        
#if canImport(LKCommonsTracker)
        if action == .show {
            Tracker.post(TeaEvent("im_mention_panel_view"))
        } else {
            Tracker.post(TeaEvent("im_mention_panel_click", params: params))
        }
#else
        print("product_level : \(action), params: \(params)")
#endif
    }
    
}

func dicValueString(_ dic:[String : Any]) -> String?{
    let data = try? JSONSerialization.data(withJSONObject: dic, options: [])
    guard let data = data else { return "" }
    let str = String(data: data, encoding: String.Encoding.utf8)
    return str
}

extension String {
    func md5() -> String {
        guard let data = data(using: .utf8) else { return self }
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        #if swift(>=5.0)
        _ = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            return CC_MD5(bytes.baseAddress, CC_LONG(data.count), &digest)
        }
        #else
        _ = data.withUnsafeBytes { bytes in
            return CC_MD5(bytes, CC_LONG(data.count), &digest)
        }
        #endif

        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
