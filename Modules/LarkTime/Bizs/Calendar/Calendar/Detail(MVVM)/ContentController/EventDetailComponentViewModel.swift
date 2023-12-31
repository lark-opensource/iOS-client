//
//  EventDetailComponentViewModel.swift
//  Calendar
//
//  Created by Rico on 2021/10/21.
//

import Foundation
import LarkContainer

class EventDetailComponentViewModel: ModuleContextHolder, UserResolverWrapper {

    let context: EventDetailContext

    let userResolver: UserResolver

    init(context: EventDetailContext, userResolver: UserResolver) {
        self.context = context
        self.userResolver = userResolver
    }
}

protocol EventDetailComponentContext: ModuleContextHolder {

    associatedtype ViewModel: ModuleContextHolder where ViewModel.Context == Context

    var viewModel: ViewModel { get }
}

extension EventDetailComponentContext where ViewModel.Context == EventDetailContext {

    var context: ViewModel.Context { return viewModel.context }
}
