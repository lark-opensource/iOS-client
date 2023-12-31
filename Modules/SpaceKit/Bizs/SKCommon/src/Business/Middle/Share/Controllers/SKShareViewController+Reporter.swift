//
//  SKShareViewController+Reporter.swift
//  SKBrowser
//
//  Created by CJ on 2021/1/4.
//

import Foundation
import SKFoundation

extension SKShareViewController {
    func reportClickPermissionSetting() {
        let eventParams = ["file_type": viewModel.shareEntity.type.name,
                           "file_id": DocsTracker.encrypt(id: viewModel.shareEntity.objToken)]
         DocsTracker.log(enumEvent: .clickFilePermSetWithin, parameters: eventParams)
    }
    
    func reportClickLinkshareSetting() {
        let eventParams = ["file_type": viewModel.shareEntity.type.name,
                           "file_id": DocsTracker.encrypt(id: viewModel.shareEntity.objToken)]
         DocsTracker.log(enumEvent: .clickLinkshareSetting, parameters: eventParams)
    }
}
