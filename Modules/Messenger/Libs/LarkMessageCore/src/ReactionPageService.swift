//
//  ReactionPageService.swift
//  LarkMessageCore
//
//  Created by 强淑婷 on 2020/2/14.
//

import Foundation
import LarkMessageBase
import Swinject
import LarkSDKInterface

public final class ReactionPageService: PageService {
    private let service: ReactionService?

    public init(service: ReactionService?) {
        self.service = service
    }

    public func pageWillAppear() {
    }
}
