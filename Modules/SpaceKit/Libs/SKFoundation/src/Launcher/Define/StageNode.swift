//
//  KickOffAbility.swift
//  Launcher
//
//  Created by nine on 2019/12/31.
//  Copyright © 2019 nine. All rights reserved.
//

import Foundation

public protocol AsyncStageNode: StageNode {
    var isLeisureStage: Bool { get }
}

public protocol StageNode {
    var finishCallBack: (() -> Void)? { get set }
    var state: StageState { get set }
    var identifier: String { get set }
    func kickoff()
    func shutdown()
}
