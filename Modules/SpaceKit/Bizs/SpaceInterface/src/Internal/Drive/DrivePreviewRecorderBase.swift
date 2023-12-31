//
//  DrivePreviewRecorderBase.swift
//  SpaceInterface
//
//  Created by ByteDance on 2023/4/13.
//  从DriveInterface迁移

import Foundation
import RxSwift

public protocol DrivePreviewRecorderBase: AnyObject {
    var stackEmptyStateChanged: Observable<Bool> { get }
}
