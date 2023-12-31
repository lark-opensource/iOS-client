//
//  DefaultMyAIDependency.swift
//  ByteViewMod
//
//  Created by 陈乐辉 on 2023/8/3.
//

import Foundation
import ByteView
import RxSwift

final class DefaultMyAIDependency: MyAIDependency {
    /// 打开MyAI
    func openMyAIChat(with config: MyAIChatConfig, from: UIViewController) {}

    /// 检测MyAI是否onboarding
    func isMyAINeedOnboarding() -> Bool { false }

    /// 打开MyAI Onboarding
    func openMyAIOnboarding(from: UIViewController, completion: @escaping ((Bool) -> Void)) {}

    /// MyAI是否可用
    func isMyAIEnabled() -> Bool { false }

    func observeName(with disposeBag: DisposeBag, observer: @escaping ((String) -> Void)) {}
}
