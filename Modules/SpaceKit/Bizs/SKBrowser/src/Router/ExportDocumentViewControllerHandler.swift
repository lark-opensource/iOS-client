//
//  ExportDocumentViewControllerHandler.swift
//  SKBrowser
//
//  Created by lizechuang on 2020/11/20.
//

import Foundation
import SKCommon
import LarkUIKit
import EENavigator

public final class ExportDocumentViewControllerHandler: TypedRouterHandler<ExportDocumentViewControllerBody> {
    override public func handle(_ body: ExportDocumentViewControllerBody, req _: EENavigator.Request, res: Response) {
        let viewModel = ExportDocumentViewModel(titleText: body.titleText,
                                                docsInfo: body.docsInfo,
                                                hostSize: body.hostSize,
                                                isFromSpaceList: body.isFromSpaceList,
                                                hideLongPicAlways: body.hideLongPicAlways,
                                                isSheetCardMode: body.isSheetCardMode,
                                                isEditor: body.isEditor,
                                                hostViewController: body.hostViewController,
                                                module: body.module,
                                                containerID: body.containerID,
                                                containerType: body.containerType,
                                                popoverSourceFrame: body.popoverSourceFrame,
                                                padPopDirection: body.padPopDirection,
                                                sourceView: body.sourceView,
                                                proxy: body.proxy)
        let exportDocumentVC = ExportDocumentViewController(viewModel: viewModel)
        if body.needFormSheet {
            exportDocumentVC.modalPresentationStyle = .formSheet
        } else {
            exportDocumentVC.modalPresentationStyle = .overFullScreen
        }
        res.end(resource: exportDocumentVC)
    }
}
