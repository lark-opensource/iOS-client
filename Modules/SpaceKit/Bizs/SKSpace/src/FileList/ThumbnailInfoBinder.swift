//
//  ThumbnailInfoBinder.swift
//  SKSpace
//
//  Created by huangzhikai on 2023/6/15.
//

import Foundation
import LarkDocsIcon
import RxSwift
import SKCommon
import SKInfra
import SKResource

// space列表图标类型，自定义缩略图显示逻辑
class ThumbnailInfoBinder: DocsIconCustomBinderProtocol {
    typealias Model = SpaceList.ThumbnailInfo
    
    func binder(model: SpaceList.ThumbnailInfo) -> RxSwift.Observable<UIImage> {
        let processer = SpaceListIconProcesser()
        let manager = DocsContainer.shared.resolve(SpaceThumbnailManager.self)
        let request = SpaceThumbnailManager.Request(token: model.token,
                                                    info: model.thumbInfo,
                                                    source: model.source,
                                                    fileType: model.fileType,
                                                    placeholderImage: model.placeholder,
                                                    failureImage: model.failedImage,
                                                    processer: processer)
        
        guard let manager = manager else {
            return .just(BundleResources.SKResource.Space.FileList.Grid.grid_cell_fail)
        }
        
        return manager.getThumbnail(request: request)
        
    }
    
}
