//
//  LauncherTask.swift
//  Launcher
//
//  Created by nine on 2019/12/30.
//  Copyright © 2019 nine. All rights reserved.
//

import Foundation

public protocol LauncherTask {
    var name: String? { get set }
    func main()
}
