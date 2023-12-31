//
//  DocsStringUtil.swift
//  SKInfra
//
//  Created by huangzhikai on 2023/4/11.
//

import Foundation

public final class DocsStringUtil {
    
    public static func getValue(from currentRevision: String, of key: String) -> String? {
        let lines = currentRevision
            .components(separatedBy: "\n")
            .filter { $0.hasPrefix("\(key):") }
        guard let targetLine = lines.first else { return nil }
        return targetLine.replacingOccurrences(of: "\(key):", with: "")
    }
    
}
