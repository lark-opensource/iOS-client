//
//  CCMWikiSearchSpaceRecommendProvider.swift
//  CCMMod
//
//  Created by Weston Wu on 2023/6/8.
//

#if MessengerMod
import Foundation
import LarkSearchCore
import LarkModel
import RxSwift
import SKWorkspace
import RustPB

protocol WikiSpaceRecommendAPI {
    func getWikiSpaceRecommend(size: Int, lastLabel: String?) -> Single<WorkSpaceInfo>
}

extension WikiNetworkManager: WikiSpaceRecommendAPI {
    func getWikiSpaceRecommend(size: Int, lastLabel: String?) -> Single<WorkSpaceInfo> {
        rxGetWikiSpacesV2(lastLabel: lastLabel ?? "", size: size, type: nil, classId: nil)
    }
}

class CCMWikiSearchSpaceRecommendProvider: PickerRecommendLoadable {

    private static let recommendCount = 50

    enum WikiSearchSpaceRecommendError: Error {
        case unExpectedLoadMore
    }

    private var hasMore: Bool = false
    private var lastLabel: String?

    private let disposeBag = DisposeBag()
    private let api: WikiSpaceRecommendAPI

    init(api: WikiSpaceRecommendAPI = WikiNetworkManager.shared) {
        self.api = api
    }

    func load() -> Observable<PickerRecommendResult> {
        api.getWikiSpaceRecommend(size: Self.recommendCount, lastLabel: nil)
            .do(onSuccess: { [weak self] info in
                guard let self else { return }
                self.hasMore = info.hasMore
                self.lastLabel = info.lastLabel
            })
            .map(Self.convert(info:))
            .asObservable()

    }
    func loadMore() -> Observable<PickerRecommendResult> {
        guard hasMore, let lastLabel else {
            return .error(WikiSearchSpaceRecommendError.unExpectedLoadMore)
        }
        return api.getWikiSpaceRecommend(size: Self.recommendCount, lastLabel: lastLabel)
            .do(onSuccess: { [weak self] info in
                guard let self else { return }
                self.hasMore = info.hasMore
                self.lastLabel = info.lastLabel
            })
            .map(Self.convert(info:))
            .asObservable()
    }

    static func convert(info: WorkSpaceInfo) -> PickerRecommendResult {
        let items = info.spaces.map { space -> PickerItem in
            var wikiSpaceMeta = Search_V2_WikiSpaceMeta()
            wikiSpaceMeta.spaceID = space.spaceID
            wikiSpaceMeta.spaceName = space.displayTitle
            wikiSpaceMeta.description_p = space.displayDescription
            let descriptionIsEmpty = space.wikiDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            let pickerMeta = PickerWikiSpaceMeta(title: space.displayTitle,
                                                 desc: descriptionIsEmpty ? nil : space.wikiDescription,
                                                 meta: wikiSpaceMeta)
            let meta = PickerItem.Meta.wikiSpace(pickerMeta)
            return PickerItem(meta: meta)
        }
        return PickerRecommendResult(items: items, hasMore: info.hasMore, isPage: true)
    }
}

#endif
