//
//  FocusAPI.swift
//  LarkFocusInterface
//
//  Created by 白镜吾 on 2023/2/9.
//

import Foundation

public protocol FocusService {
    func generateTagView() -> FocusTagViewAPI
}
