//
//  TranslateLifeCycleService.swift
//  LarkChat
//
//  Created by chenyanjie on 2023/8/22.
//

import Foundation
import LarkMessageBase
import LarkContainer
import LarkMessengerInterface

public final class TranslateLifeCycleService: PageService {
    private let translateService: NormalTranslateService?
    public init(translateService: NormalTranslateService?) {
        self.translateService = translateService
    }

    public func pageDeinit() {
        if let translateService = self.translateService, translateService.enableDetachResultDic() {
            if !translateService.detachResultDic.isEmpty {
                translateService.detachResultDic.removeAll()
            }
        }
    }
}
