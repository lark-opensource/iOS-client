//
//  main.swift
//  Pods
//
//  Created by 李晨 on 2020/1/6.
//

import Foundation
import AppContainer
import Swinject

func main() {
    BootLoader.shared.start(
        delegate: AppContainer.AppDelegate.self,
        config: AppConfig(env: .dev))

    _ = Assembler([
        DemoAssembly()
    ], container: BootLoader.container)
}
main()
