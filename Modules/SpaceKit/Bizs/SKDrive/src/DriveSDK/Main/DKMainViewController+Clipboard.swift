//
//  DKMainViewController+Clipboard.swift
//  SKDrive
//
//  Created by Weston Wu on 2023/10/30.
//

import Foundation
import SKUIKit
import RxRelay

extension DKMainViewController: ClipboardProtectProtocol {
    func getDocumentToken() -> String? {
        guard let hostModule = viewModel.hostModule else { return nil }
        return hostModule.hostToken ?? hostModule.fileInfoRelay.value.fileToken
    }
}
