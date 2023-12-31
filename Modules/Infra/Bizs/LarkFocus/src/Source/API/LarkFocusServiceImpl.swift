//
//  LarkFocusServiceImpl.swift
//  LarkFocus
//
//  Created by 白镜吾 on 2023/2/9.
//

import Foundation
import LarkFocusInterface

public final class LarkFocusServiceImpl: FocusService {

    public func generateTagView() -> FocusTagViewAPI {
        let tagView = FocusTagView()
        return tagView
    }
}
