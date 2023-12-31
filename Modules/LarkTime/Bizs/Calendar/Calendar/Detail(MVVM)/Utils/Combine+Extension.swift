//
//  Combine+Extension.swift
//  Calendar
//
//  Created by Rico on 2021/4/20.
//

import Foundation
import LarkCombine

extension Publisher where Failure == Never {

    public func assignUI<Root>(to keyPath: ReferenceWritableKeyPath<Root, Output>,
                               on object: Root) -> AnyCancellable {
        return self
            .receive(on: DispatchQueue.main.ocombine)
            .assign(to: keyPath, on: object)
    }
}
