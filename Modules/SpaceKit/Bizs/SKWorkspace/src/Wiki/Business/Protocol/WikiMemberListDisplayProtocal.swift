//
//  WikiMemberListDisplayProtocal.swift
//  SKWorkspace
//
//  Created by majie.7 on 2023/5/19.
//

import Foundation


public protocol WikiMemberListDisplayProtocol {
    var displayName: String { get }
    var displayDescription: String { get }
    var displayIcon: UIImage? { get }
    var displayIconURL: URL? { get }
    var displayRole: String { get }
}
