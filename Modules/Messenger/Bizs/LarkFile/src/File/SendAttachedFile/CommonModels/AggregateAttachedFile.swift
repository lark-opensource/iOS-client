//
//  File.swift
//  LarkFile
//
//  Created by ChalrieSu on 2018/9/19.
//

import Foundation
import Photos
import LarkFoundation
import LarkMessengerInterface

protocol AggregateAttachedFiles {
    var type: AttachedFileType { get }
    var displayName: String { get }
    var filesCount: Int { get }
    func fileAtIndex(_ index: Int) -> AttachedFile
}

extension AggregateAttachedFiles {
    var displayName: String {
        return type.displayName
    }
}
