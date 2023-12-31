//
//  AssociateAppViewModel.swift
//  SKBrowser
//
//  Created by huangzhikai on 2023/10/23.
//

import Foundation
import LarkContainer
import SKCommon
import TangramService
import RxSwift
import LarkModel
import RustPB

class AssociateAppViewModel {
    public let userResolver: LarkContainer.UserResolver
    public var references: [AssociateAppModel.ReferencesModel] = []
    public init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }
    
    func getAssociateInfo(referencesModel: AssociateAppModel.ReferencesModel) -> RxSwift.Observable<[String : LarkModel.InlinePreviewEntity]> {
        
        guard let previewAPI = try? userResolver.resolve(assert: URLPreviewAPI.self) else {
            return .empty()
        }
        
        guard let previeToken = referencesModel.previeToken else {
            return .empty()
        }
        var preview = Basic_V1_PreviewHangPoint()
        preview.previewID = previeToken
        preview.needLocalPreview = referencesModel.needLocalPreview ?? false
        preview.isLazyLoad = referencesModel.isLazyLoad ?? false
        preview.url = referencesModel.url ?? ""
        
        return previewAPI.getPreviewByHangPoints(hangPoints: [preview], previewID2SourceIds: [:]).map { inlinePreviewEntity, _ in
            inlinePreviewEntity
        }
    }
}
