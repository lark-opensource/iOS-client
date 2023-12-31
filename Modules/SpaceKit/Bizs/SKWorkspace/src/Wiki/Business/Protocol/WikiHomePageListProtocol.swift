//
//  WikiHomePageListProtocol.swift
//  SKWorkspace
//
//  Created by majie.7 on 2023/5/19.
//

import Foundation
import SKCommon


public protocol WikiHomePageListProtocol {
    var displayName: String { get }
    var displayIcon: UIImage? { get }
    var displayIconURL: URL? { get }
    var subtitleContent: String { get }
    var enable: Bool { get }
    var upSyncStatus: UpSyncStatus { get }
    var syncStatusImage: UIImage? { get }
}
