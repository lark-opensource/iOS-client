//
//  RedPacketCoverViewModel.swift
//  LarkFinance
//
//  Created by JackZhao on 2021/11/11.
//

import Foundation
import RxSwift
import LKCommonsLogging
import LarkSDKInterface

final class RedPacketCoverViewModel {
    private static let logger = Logger.log(RedPacketCoverViewModel.self, category: "LarkFinace")
    typealias RedPacketPublishModel = Result<[RedPacketCoverCellViewModel], Error>

    private let bag = DisposeBag()
    private let pullHongbaoCoverList: () -> Observable<PullHongbaoCoverListResponse>
    private var dataSubject = PublishSubject<RedPacketPublishModel>()
    private let selectedCoverId: Int64?
    var coverIdToThemeTypeMap: [String: String] = [:]
    var coverItemCellTapHandler: (Int64) -> Void = { _ in }
    var dataObservable: Observable<RedPacketPublishModel> { dataSubject.asObservable() }

    init(selectedCoverId: Int64? = nil,
         pullHongbaoCoverList: @escaping () -> Observable<PullHongbaoCoverListResponse>) {
        self.pullHongbaoCoverList = pullHongbaoCoverList
        self.selectedCoverId = selectedCoverId
        // fetch data then inform of vc
        pullHongbaoCoverList()
            .subscribe(onNext: { [weak self] (res) in
                guard let self = self else { return }
                self.dataSubject.onNext(.success(self.transformModelFromRes(res)))
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                self.dataSubject.onNext(.failure(error))
                Self.logger.error("pullHongbaoCoverList error", error: error)
            }).disposed(by: self.bag)
    }

    private func transformModelFromRes(_ res: PullHongbaoCoverListResponse) -> [RedPacketCoverCellViewModel] {
        var recommedCoverModels = res.recommendCovers.map({ cover -> RedPacketCoverItemCellModel in
            coverIdToThemeTypeMap["\(cover.id)"] = "recommed"
            return RedPacketCoverItemCellModel(cover: cover, isShowBorder: cover.id == selectedCoverId)
        })
        var defaultCover = HongbaoCover()
        defaultCover.name = BundleI18n.LarkFinance.Lark_RedPacket_Theme_Default
        // insert defaut cover to first
        recommedCoverModels.insert(RedPacketCoverItemCellModel(cover: defaultCover,
                                                               isDefaultCover: true,
                                                               isShowBorder: selectedCoverId == nil),
                                   at: 0)
        let title = BundleI18n.LarkFinance.Lark_RedPacket_Theme_Recommend
        let recommedCoverListModel = RedPacketCoverCellViewModel(title: title,
                                                                 datas: recommedCoverModels,
                                                                 coverItemCellTapHandler: coverItemCellTapHandler)
        var coverListModels = res.categoryList.compactMap({ category -> RedPacketCoverCellViewModel? in
            if let coverList = res.covers[category.id] {
                let models = coverList.covers.map({ cover -> RedPacketCoverItemCellModel in
                    coverIdToThemeTypeMap["\(cover.id)"] = category.name
                    return RedPacketCoverItemCellModel(cover: cover, isShowBorder: cover.id == selectedCoverId)
                })
                return RedPacketCoverCellViewModel(title: category.name,
                                                   datas: models,
                                                   coverItemCellTapHandler: coverItemCellTapHandler)
            }
            assertionFailure("covers not found")
            return nil
        })
        // insert recommed cell to first
        coverListModels.insert(recommedCoverListModel, at: 0)
        return coverListModels
    }
}
