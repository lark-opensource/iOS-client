//
//  LarkAvatar+DocsIcon.swift
//  LarkBizAvatar
//
//  Created by huangzhikai on 2023/7/5.
//

import Foundation
import RxSwift
import UniverseDesignIcon
import LarkDocsIcon
import LarkContainer
import RustPB


public struct DocsIconBinderModel: LarkAvatarCustommModelProtocol {
    
    public static var modelName: String {
        return "LarkDocsIcon.LarkAvatar." + String(describing: DocsIconBinderModel.self)
    }
    
    public var iconInfo: String
    public var docsUrl: String
    public let userResolver: UserResolver
    public var docType: Basic_V1_DocFeed.TypeEnum
    public init(iconInfo: String, docsUrl: String, docType: Basic_V1_DocFeed.TypeEnum, userResolver: UserResolver) {
        self.userResolver = userResolver
        self.iconInfo = iconInfo
        self.docsUrl = docsUrl
        self.docType = docType
    }
}

public class LarkAvatarDocsIconBinder: LarkAvatarCustomBinderProtocol {
    
    public typealias Model = DocsIconBinderModel
    
    public init() {}
    
    public func binder(model: DocsIconBinderModel) -> Observable<UIImage> {
        var shape: IconShpe = .CIRCLE
        let featureGating = try? Container.shared.getCurrentUserResolver().resolve(type: DocsIconFeatureGating.self)
        if featureGating?.btSquareIcon ?? false, model.docType == .bitable {
            shape = .SQUARE
        }
        
        //后续业务进行用户态改造
        let docsIconManager = try? model.userResolver.resolve(assert: DocsIconManager.self)
        return docsIconManager?.getDocsIconImageAsync(iconInfo: model.iconInfo, url: model.docsUrl, shape: shape) ?? .just(UIImage())
    }
}

