//
//  Utils.swift
//  LarkStorageAssembly
//
//  Created by 李昊哲 on 2022/11/3.
//

#if !LARK_NO_DEBUG
import Foundation
import LarkStorage

let globalPrefix = "LarkStorage"
let spacePrefix = "Space-"
let domainPrefix = "Domain-"
let spaceUserPrefix = "User_"

let udRegex = try? NSRegularExpression(pattern: #"^lark_storage\.(.*?)\.plist$"#)
let mmRegex = try? NSRegularExpression(pattern: #"^lark_storage\.(.*?)$"#)
let keyRegex = try? NSRegularExpression(pattern: #"^lskv\.space_.*?\.domain_(.*?)\.(.*)$"#)

func getRootPath(type: RootPathType.Normal) -> String {
    let dir: FileManager.SearchPathDirectory
    switch type {
    case .temporary:
        return (NSTemporaryDirectory() as NSString).standardizingPath
    case .document:
        dir = .documentDirectory
    case .library:
        dir = .libraryDirectory
    case .cache:
        dir = .cachesDirectory
    }
    return NSSearchPathForDirectoriesInDomains(dir, .userDomainMask, true)[0]
}

func substring(_ text: String, withNSRange range: NSRange) -> Substring {
    guard range.location != NSNotFound else {
        return ""
    }
    let from16 = text.utf16.index(text.utf16.startIndex, offsetBy: range.location,
                                  limitedBy: text.utf16.endIndex) ?? text.utf16.endIndex
    let to16 = text.utf16.index(from16, offsetBy: range.length,
                                limitedBy: text.utf16.endIndex) ?? text.utf16.endIndex

    guard let fromIndex = String.Index(from16, within: text),
          let toIndex = String.Index(to16, within: text)
    else {
        return ""
    }

    return text[fromIndex..<toIndex]
}

func makeNSRange(_ text: String) -> NSRange {
    NSRange(location: 0, length: text.count)
}

func checkCurrentUser(space: String) -> Bool {
    if space.hasPrefix(spaceUserPrefix) {
        let userId = space.dropFirst(spaceUserPrefix.count)
        if let curUserId = KVStores.getCurrentUserId?(), curUserId == userId {
            return true
        }
    }
    return false
}
#endif
