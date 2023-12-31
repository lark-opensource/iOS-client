//
//  DirectoryHelper.swift
//  DocsTabs
//
//  Created by weidong fu on 19/1/2018.
//

import Foundation
import SKResource

public struct DirectoryHelper {
    public static func getController(with context: DirectoryUtilContext) -> DirectoryUtilController {
        let vc = DirectoryUtilController(context: context)
        if let destinationName = context.desFile?.name {
            vc.navigationBar.title = destinationName
        } else {
            vc.navigationBar.title = BundleI18n.SKResource.Doc_List_Space
        }
        return vc
    }
}
