//
//  ListEditViewModel.swift
//  Todo
//
//  Created by baiyantao on 2022/11/15.
//

import Foundation
import RxSwift
import RxCocoa
import UniverseDesignInput

final class ListEditViewModel {
    enum Scene {
        case create
        case edit(content: String)
    }

    var isTextFieldActive: (() -> Bool)?

    // MARK: dependencies
    let scene: Scene

    // MARK: view drivers
    let rxIsSaveEnable = BehaviorRelay<Bool>(value: false)
    let rxTextFieldStatus = BehaviorRelay<UDInputStatus>(value: .normal)

    init(scene: Scene) {
        self.scene = scene
        doUpdateText(content())
    }

    func content() -> String? {
        switch scene {
        case .edit(let content):
            return content
        case .create:
            return nil
        }
    }

    func doUpdateText(_ str: String?) {
        let isActive = isTextFieldActive?() ?? false
        guard let str = str, !str.isEmpty else {
            rxIsSaveEnable.accept(false)
            rxTextFieldStatus.accept(isActive ? .activated : .normal)
            return
        }
        if str.count > 100 {
            rxIsSaveEnable.accept(false)
            rxTextFieldStatus.accept(.error)
        } else {
            rxIsSaveEnable.accept(true)
            rxTextFieldStatus.accept(isActive ? .activated : .normal)
        }
    }
}
