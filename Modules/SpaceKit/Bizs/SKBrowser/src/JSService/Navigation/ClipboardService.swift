//
//  ClipboardService.swift
//  SpaceKit
//
//  Created by Gill on 2019/1/11.
//

import Foundation
import SwiftyJSON
import SKCommon
import SKFoundation
import SKInfra

class ClipboardService: BaseJSService {
    
    //剪切板数据处理转化成特定key给前端
    static func convertPasteboard(encryptID: String?) -> [String: Any] {
        
        var dict: [String: Any] = [:]
        
        // 取剪切板public.html的数据
        if let pasteboardItems = SKPasteboard.items(with: encryptID, psdaToken: PSDATokens.Pasteboard.docs_edit_do_paste_get_items) {
            pasteboardItems.forEach({ (item) in
                let filtedItem = item.filter { (key, value) -> Bool in
                    DocsLogger.info("[getClipboard] key: \(key)")
                    if key != "public.html" {
                        return false
                    }
                    return JSONSerialization.isValidJSONObject([key: value])
                }
                dict.merge(other: filtedItem)
            })
        }
        
        // 取剪切板string的数据
        if let pasteboardString = SKPasteboard.string(with: encryptID, psdaToken: PSDATokens.Pasteboard.docs_edit_do_paste_get_string) {
            let item = ["public.utf8-plain-text": pasteboardString]
            
            let filtedItem = item.filter { (key, value) -> Bool in
                DocsLogger.info("[getClipboard] key: \(key)")
                return JSONSerialization.isValidJSONObject([key: value])
            }
            dict.merge(other: filtedItem)
        }
        
        return dict
    }
    
    //剪切板数据处理
    static func handlePasteboardItems(item: [String: Any]) -> [String: Any] {
        var newItem: [String: Any] = [:]
        for (key, value) in item {
            
            //特殊处理：处理粘贴板数据，如果value是NSURL，需要转化成String，要不无法粘贴到doc
            //原数据： "public.url": NSURL("https://xxxxx")
            //转换成： "public.utf8-plain-text": "https://xxxxx"
            
            if let temp = value as? NSURL {
                let newValue = temp.absoluteString as Any
                newItem["public.utf8-plain-text"] = newValue
            } else {
                newItem[key] = value
            }
        }
        return newItem
    }
}

extension ClipboardService: DocsJSServiceHandler {
    var handleServices: [DocsJSService] {
        return [.clipboardSetContent, .clipboardGetContent, .clipboardSetEncryptId]
    }

    func handle(params: [String: Any], serviceName: String) {
        DocsLogger.info("[ClipboardService] name: \(serviceName) ")
        
        if serviceName == DocsJSService.clipboardGetContent.rawValue {
            guard let callback = params["callback"] as? String else { return }
            var pointId: String? = params["encryptId"] as? String
            //空字符当成 nil 处理
            if let checkPointId = pointId, checkPointId.count == 0 {
                pointId = nil
            }
            let dict = ClipboardService.convertPasteboard(encryptID: pointId)
            
            model?.jsEngine.callFunction(DocsJSCallBack(callback), params: dict, completion: nil)
        } else if serviceName == DocsJSService.clipboardSetContent.rawValue {
            guard let text = params["text"] as? String else { return }
            guard let html = params["html"] as? String else { return }
            var needProtect = true
            // 比如评论链接不需要粘贴保护
            if let protect = params["protect"] as? Bool {
                needProtect = protect
            }
            var pointId: String? = params["encryptId"] as? String
            //空字符当成 nil 处理
            if let checkPointId = pointId, checkPointId.count == 0 {
                pointId = nil
            }
            let items = [["public.utf8-plain-text": text, "public.html": html]]
            // 系统会在 0.05s 之后又清空一遍剪贴板，因此需要延时处理一下
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_100) {
                //https://openradar.appspot.com/36063433
                //设置 paste.string 🈶️概率crash。。。
                if SKPasteboard.hasStrings {
                    _ = SKPasteboard.setStrings(nil, pointId: pointId,
                                               psdaToken: PSDATokens.Pasteboard.docs_edit_do_paste_set_strings,
                                          shouldImmunity: !needProtect)
                }
                let isSuccess = SKPasteboard.setItems(items,
                                      pointId: pointId,
                                    psdaToken: PSDATokens.Pasteboard.docs_edit_do_paste_set_items,
                               shouldImmunity: !needProtect)
                PermissionStatistics.shared.reportDocsCopyClick(isSuccess: isSuccess)
            }
        } else if serviceName == DocsJSService.clipboardSetEncryptId.rawValue {
            guard let encryptIds = params["encryptIds"] as? [String: String] else {
                return
            }
            encryptIds.forEach { (token, encryptId) in
                let pointId: String?
                if encryptId.isEmpty {
                    pointId = nil
                } else {
                    pointId = encryptId
                }
                ClipboardManager.shared.updateEncryptId(token: token, encryptId: pointId)
            }
        }
    }
}
