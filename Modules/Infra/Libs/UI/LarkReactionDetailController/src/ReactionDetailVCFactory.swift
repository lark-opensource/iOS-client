//
//  ReactionDetailVCFactory.swift
//  LarkReactionDetailController
//
//  Created by 李晨 on 2019/6/17.
//

import Foundation
import UIKit

public final class ReactionDetailVCFactory {

    @available(*, deprecated, message: "please use create(message:dependency:)")
    public static func create(message: Message, delegate: ReactionDetailViewModelDelegate) -> UIViewController {
        return self.create(message: message, dependency: delegate)
    }

    public static func create(message: Message, dependency: ReactionDetailViewModelDependency) -> UIViewController {
        let vm = ReactionDetailViewModel(message: message, dependency: dependency)
        let vc = ReactionDetailController(viewModel: vm)
        return vc
    }
}
