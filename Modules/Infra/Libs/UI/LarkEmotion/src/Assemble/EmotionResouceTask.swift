//
//  EmotionResouceTask.swift
//  LarkEmotion
//
//  Created by 李勇 on 2021/3/5.
//

import LarkEnv
import Foundation
import BootManager
import LarkContainer
import LarkSetting

// 拉取远端表情资源
public final class EmotionResouceTask: UserFlowBootTask, Identifiable {

    public override class var compatibleMode: Bool { EmotionSetting.userScopeCompatibleMode }

    public static var identify = "EmotionResouceTask"
    // 拉取远端表情资源：sdk会做缓存，并且有4小时的过期时间
    public override func execute(_ context: BootContext) {
        // 设置默认值，其他Demo工程不引LarkAssemble可以自己Mock
        EmotionResouce.shared.dependency = EmotionResouceDependencyImpl(resolver: self.userResolver)  
        DispatchQueue.global().async {
            // 本地兜底的表情资源需要根据语言来区分，服务端会下发所有语言的表情资源，SDK会根据当前设置的语言返回对应的资源
            EmotionResouce.shared.reloadResouces()
        }
    }
}
