//
//  AppDelegate.swift
//  SpaceDemo
//
//  Created by CharlieSu on 10/11/19.
//  Copyright © 2019 Bytedance.Inc. All rights reserved.
//

import RxSwift
import Swinject
import LarkPerf
import BootManager
import AppContainer
import LarkContainer
import LarkLocalizations
import LarkAssembler
import LKLoadable
import CCMMod
import LarkOPInterface
import LKTracing
import RunloopTools
import SKCommon
import SKSpace
import SKBrowser
import SKDrive
import SKDoc
import SKBitable
import SKMindnote
import SKSheet
import SpaceKit
import SKComment
import SKWikiV2
import SKSlides
import SKPermission
import SKFoundation

final class LarkMainAssembly: FlowBootTask, Identifiable {
    static var identify = "LarkMainAssembly"

    override var runOnlyOnce: Bool { return true }
    
    let demoTask = DemoRegistTask()

    override func execute(_ context: BootContext) {
        let assemblies: [LarkAssemblyInterface] = [
            BaseAssembly(),
            WebAssembly(),
            ECOInfraDependencyAssembly(),
        ]
        _ = Assembler(assemblies: assemblies, container: BootLoader.container)
        BootLoader.assemblyLoaded = true
        
        demoTask.execute(context)
    }
}

func spaceDemoMain() {
    
    //单测统一注册一次
    if DocsSDK.isBeingTest {
        LarkContainer.implicitResolver = Container.shared
        
        let modules: [ModuleService] = [
            CommonModule(),
            SpaceModule(),
            BrowserModule(),
            DriveModule(),
            DriveSDKModule(),
            DocModule(),
            SheetModule(),
            SlidesModule(),
            BitableModule(),
            MindNoteModule(),
            SpaceKitModule(),
            WikiModuleV2(),
            CommentModule(),
            PermissionModule()
        ]
        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: true)
        let mgr = userResolver.docs.moduleManager
        mgr.registerModules(modules)
    }
    
    LanguageManager.supportLanguages =
        (Bundle.main.infoDictionary!["SUPPORTED_LANGUAGES"] as! [String]).map { Lang(rawValue: $0) }

    LKLoadableManager.run(appMain)
    NewBootManager.register(LarkMainAssembly.self)
    NewBootManager.register(InitIdleLoadTask.self)

    RunloopDispatcher.enable = true
    BootLoader.shared.start(delegate: AppDelegate.self, config: .default)
}

spaceDemoMain()

class InitIdleLoadTask: FlowBootTask, Identifiable {

    static var identify: TaskIdentify = "IdleLoadTask"

    override func execute(_ context: BootContext) {
        LKLoadableManager.run(LKLoadable.runloopIdle)
    }
}
