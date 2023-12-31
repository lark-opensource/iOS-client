//
//  SubFolderBaseModel.swift
//  SKSpace
//
//  Created by Weston Wu on 2023/2/21.
//

import Foundation
import SKFoundation
import SKCommon
import RxSwift
import SpaceInterface

// 抽离 V1 V2 的通用逻辑
struct SubFolderBaseModel {
    let networkAPI: FolderListAPI.Type
    let folderToken: String
    let pageCount: Int

    struct ListResponse {
        let dataDiff: FileDataDiff
        let pagingState: SpaceListContainer.PagingState
        let totalCount: Int
    }

    func refresh(sortOption: SpaceSortHelper.SortOption) -> Single<ListResponse> {
        queryList(lastLabel: nil, sortOption: sortOption)
    }

    func loadMore(lastLabel: String, sortOption: SpaceSortHelper.SortOption) -> Single<ListResponse> {
        queryList(lastLabel: lastLabel, sortOption: sortOption)
    }

    private func queryList(lastLabel: String?, sortOption: SpaceSortHelper.SortOption) -> Single<ListResponse> {
        networkAPI.queryList(folderToken: folderToken,
                             count: pageCount,
                             lastLabel: lastLabel,
                             sortOption: sortOption,
                             extraParams: ThumbnailUrlConfig.gridThumbnailSizeParams)
        .map { dataDiff in
            let pagingState: SpaceListContainer.PagingState
            let totalCount: Int
            if let pagingInfo = dataDiff.filePaingInfos[folderToken] {
                if pagingInfo.hasMore, let lastLabel = pagingInfo.lastLabel {
                    pagingState = .hasMore(lastLabel: lastLabel)
                } else {
                    pagingState = .noMore
                }
                totalCount = pagingInfo.total ?? dataDiff.folders[folderToken]?.count ?? 0
            } else {
                spaceAssertionFailure()
                pagingState = .noMore
                totalCount = dataDiff.folders[folderToken]?.count ?? 0
            }
            return ListResponse(dataDiff: dataDiff,
                                pagingState: pagingState,
                                totalCount: totalCount)
        }
    }
}
