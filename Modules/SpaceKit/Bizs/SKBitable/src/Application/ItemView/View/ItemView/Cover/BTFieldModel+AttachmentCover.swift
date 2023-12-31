//
//  BTFieldModel+AttachmentCover.swift
//  SKBitable
//
//  Created by 刘焱龙 on 2023/8/12.
//

import Foundation

extension BTFieldModel {
    var isAttachment: Bool {
        return compositeType.type == .attachment
    }
}
