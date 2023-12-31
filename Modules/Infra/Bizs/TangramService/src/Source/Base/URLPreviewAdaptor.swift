//
//  URLPreviewAdaptor.swift
//  TangramService
//
//  Created by 袁平 on 2022/4/18.
//

import Foundation
public struct URLPreviewAdaptor {
    private static let prefix = "LocalPreview_"
    private static var bucket: Int32 = 0

    public static func uniqueID() -> String {
        let id = OSAtomicIncrement32(&bucket)
        return "\(prefix)\(id)"
    }

    public static func isLocalTemplate(templateID: String) -> Bool {
        return templateID.hasPrefix(prefix)
    }
}
