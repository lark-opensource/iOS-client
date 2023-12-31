//
//  File.swift
//  UniversalCard
//
//  Created by ByteDance on 2023/8/7.
//

import Foundation
import LarkStorageCore

public protocol UniversalCardModuleDependencyProtocol {
    typealias SDKTemplate = (data: Data, version: String, extraTiming: [AnyHashable: Any])
    func loadTemplate() -> SDKTemplate?
    func latestVersionCard(with path: String) -> AbsPath?
    var templateVersion: String? { get }
}
