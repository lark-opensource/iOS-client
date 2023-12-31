//
//  URL+OpenPluginSandbox.swift
//  OPPlugin
//
//  Created by 王飞 on 2022/7/8.
//
import OPPluginManagerAdapter

extension String {
    var isTTFileURL: Bool {
        hasPrefix(BDP_TTFILE_SCHEME)
    }
    
    var isHTTPURL: Bool {
        hasPrefix("http://") || hasPrefix("https://")
    }
}
