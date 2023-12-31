//
//  CodablePathBody.swift
//  ByteViewInterface
//
//  Created by kiri on 2023/6/29.
//

import Foundation
import EENavigator

public protocol CodablePathBody: CodablePlainBody {
    static var path: String { get }
}

public extension CodablePathBody {
    static var pattern: String { "/\(path)" }
}
