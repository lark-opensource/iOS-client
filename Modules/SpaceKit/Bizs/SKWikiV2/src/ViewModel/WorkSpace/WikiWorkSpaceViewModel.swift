//
//  WikiWorkSpaceViewModel.swift
//  SKWikiV2
//
//  Created by bytedance on 2021/3/30.
//
import SwiftyJSON
import UIKit
import EENavigator
import SKResource
import SKCommon
import SKFoundation
import SKUIKit
import RxSwift
import SKWorkspace

class WikiWorkSpaceViewModel {
    enum Action {
        case getSpacesError(error: Error, isMoreFetch: Bool)
        case updateSpaces(category: WorkSpaceCategory, space: WorkSpaceInfo)
    }
    
    private var getSpacesRequest: DocsRequest<JSON>?
    var bindAction: ((Action) -> Void)?
    private let size = 50
    
    func fetchData(with category: WorkSpaceCategory, lastLabel: String) {
        getSpacesRequest = WikiNetworkManager.shared.getWikiSpacesV2(lastLabel: lastLabel,
                                                                     size: size,
                                                                     type: category.typeValue,
                                                                     classId: nil) { [weak self] result in
            switch result {
            case .success(let res):
                DocsLogger.info("wiki.workspace.vm --- get space list success", extraInfo: ["count": res.spaces.count])
                self?.bindAction?(.updateSpaces(category: category, space: res))
            case .failure(let error):
                DocsLogger.error("wiki.workspace.vm --- get space list failed", error: error)
                self?.bindAction?(.getSpacesError(error: error, isMoreFetch: !lastLabel.isEmpty))
            }
        }
    }
}
