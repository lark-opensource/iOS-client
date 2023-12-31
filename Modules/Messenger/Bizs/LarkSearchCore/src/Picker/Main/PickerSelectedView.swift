//
//  PickerSelectedView.swift
//  LarkSearchCore
//
//  Created by Yuri on 2023/5/23.
//

import Foundation
import LarkModel

class PickerSelectedView: SelectedView {
    init(style: PickerFeatureConfig.MultiSelection.PickerSelectedViewStyle,
         delegate: SelectedViewDelegate,
         supportUnfold: Bool = true) {
        var type: UniversalPickerType = .defaultType
        switch style {
        case .folder:
            type = .folder
        case .label(let handler):
            type = .label(handler)
        default: break
        }
        super.init(frame: .zero, delegate: delegate, supportUnfold: supportUnfold, pickType: type)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
