//
//  SpringLoadedInteraction.swift
//  LarkInteraction
//
//  Created by 李晨 on 2020/3/24.
//

import UIKit
import Foundation
import LKCommonsLogging

public final class SpringLoadedInteraction: NSObject, Interaction {

    public typealias HandleBlock = (UISpringLoadedInteraction, UISpringLoadedInteractionContext) -> Void

    public typealias ShoulBeginBlock = (UISpringLoadedInteraction, UISpringLoadedInteractionContext) -> Bool

    public typealias DidFinishBlock = (UISpringLoadedInteraction) -> Void

    static var logger = Logger.log(SpringLoadedInteraction.self, category: "Lark.Interaction")

    private(set) lazy var behavior: SpringLoadedBehavior = SpringLoadedBehavior(self)
    private(set) lazy var effect: SpringLoadedEffect = SpringLoadedEffect(self)

    public private(set) lazy var springLoadedInteraction: UISpringLoadedInteraction = {
        let interaction = UISpringLoadedInteraction(
            interactionBehavior: self.behavior,
            interactionEffect: self.effect) { [weak self] (interaction, context) in
                self?.handler(interaction, context)
        }
        return interaction
    }()

    public var uiInteraction: UIInteraction {
        return self.springLoadedInteraction
    }

    public var handler: HandleBlock

    public var shouldBeginHandler: ShoulBeginBlock = { (_, _) in return true }

    public var didChangeHandler: HandleBlock?

    public var didFinishHandler: DidFinishBlock?

    public init(handler: @escaping HandleBlock) {
        self.handler = handler
        super.init()
    }
}

final class SpringLoadedBehavior: NSObject, UISpringLoadedInteractionBehavior {
    weak var interaction: SpringLoadedInteraction?

    init(_ interaction: SpringLoadedInteraction) {
        self.interaction = interaction
    }

    func shouldAllow(_ interaction: UISpringLoadedInteraction, with context: UISpringLoadedInteractionContext) -> Bool {
        return self.interaction?.shouldBeginHandler(interaction, context) ?? true
    }

    func interactionDidFinish(_ interaction: UISpringLoadedInteraction) {
        self.interaction?.didFinishHandler?(interaction)
    }
}

final class SpringLoadedEffect: NSObject, UISpringLoadedInteractionEffect {
    weak var interaction: SpringLoadedInteraction?

    init(_ interaction: SpringLoadedInteraction) {
        self.interaction = interaction
    }

    func interaction(
        _ interaction: UISpringLoadedInteraction,
        didChangeWith context: UISpringLoadedInteractionContext
    ) {
        self.interaction?.didChangeHandler?(interaction, context)
    }
}
