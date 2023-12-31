//
//  UDIcon+Extension.swift
//  TangramService
//
//  Created by 袁平 on 2021/12/8.
//

import UIKit
import Foundation
import RustPB
import LarkDocsIcon

public extension Basic_V1_UDIcon {
    var udImage: UIImage? {
        if hasKey, !key.isEmpty {
            return URLPreviewUDIcon.getIconByKey(key, iconColor: color.color)
        }
        return nil
    }

    var unicodeImage: UIImage? {
        if hasUnicode, !unicode.isEmpty {
            return DocsIconManager.changeEmojiKeyToImage(key: unicode)
        }
        return nil
    }
}
