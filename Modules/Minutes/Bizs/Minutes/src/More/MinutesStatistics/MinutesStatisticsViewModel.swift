//
//  MinutesStatisticsViewModel.swift
//  Minutes
//
//  Created by sihuahao on 2021/7/5.
//

import Foundation
import MinutesFoundation
import MinutesNetwork
import LarkTimeFormatUtils

class MinutesStatisticsViewModel {

    let minutes: Minutes

    init(minutes: Minutes) {
        self.minutes = minutes
    }

    func requestMoreDetailsInformation(catchError: Bool, successHandler: ((MoreDetailsInfo) -> Void)?, failureHandler: (() -> Void)?) {
        minutes.fetchMoreDetails(catchError: catchError) { [weak self] result in
            guard let wSelf = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let moreDetailsInfo):
                    successHandler?(moreDetailsInfo)
                case .failure(let error):
                    DispatchQueue.main.async {
                        failureHandler?()
                    }
                }
            }
        }
    }

    func configCellInfo( moreDetailsInfo: MoreDetailsInfo?) -> [CellInfo] {

        var cellsInfo: [CellInfo] = []

        var ownerTitle = BundleI18n.Minutes.MMWeb_G_MoreDetails_Owner_Tab
        var leftImageName = minutes.info.basicInfo?.ownerInfo?.avatarURL ?? ""
        var rightLabelText = minutes.info.basicInfo?.ownerInfo?.userName ?? ""

        let originCellInfoOwner = OriginCellInfo(titleLabelText: ownerTitle,
                                             hasUrl: true,
                                             leftImageName: leftImageName,
                                             rightLabelText: rightLabelText)

        var createTitle = BundleI18n.Minutes.MMWeb_G_MoreDetails_Created_Tab
        var iconImage = ""
        var createdTimeText = DateFormat.getLongLocalizedDate(timeInterval: TimeInterval(minutes.info.basicInfo?.startTime ?? 0))

        let originCellInfoTime = OriginCellInfo(titleLabelText: createTitle,
                                             hasUrl: false,
                                             leftImageName: iconImage,
                                             rightLabelText: createdTimeText)

        var viewStatsTitle = BundleI18n.Minutes.MMWeb_G_MoreDetails_ViewStats_Tab
        var hasStatistics = minutes.basicInfo?.hasStatistics
        var userView = moreDetailsInfo?.userView
        var pageView = moreDetailsInfo?.pageView
        var viewerCountTab = BundleI18n.Minutes.MMWeb_G_MoreDetails_ViewerCount_Tab
        var viewCountTab = BundleI18n.Minutes.MMWeb_G_MoreDetails_ViewCount_Tab

        let statisticsCellInfoViewStats = StatisticsCellInfo(titleLabelText: viewStatsTitle,
                                                          hasStatistics: hasStatistics,
                                                          leftlabelNum: userView,
                                                          rightLabelNum: pageView,
                                                          leftBottomLabelText: viewerCountTab,
                                                          rightBottomLabelText: viewCountTab,
                                                             isSingle: false)

        var interactStatsTitle = BundleI18n.Minutes.MMWeb_G_MoreDetails_InteractStats_Tab
        var reactionUserNum = moreDetailsInfo?.reactionUserNum
        var commentNum = moreDetailsInfo?.commentNum
        var reactionCountTab = BundleI18n.Minutes.MMWeb_G_MoreDetails_ReactionCount_Tab
        var commentCountTab = BundleI18n.Minutes.MMWeb_G_MoreDetails_CommentCount_Tab

        let statisticsCellInfoInteractStats = StatisticsCellInfo(titleLabelText: interactStatsTitle,
                                                                 hasStatistics: true,
                                                                 leftlabelNum: commentNum,
                                                                 rightLabelNum: -1,
                                                                 leftBottomLabelText: commentCountTab,
                                                                 rightBottomLabelText: "",
                                                                 isSingle: true)

        cellsInfo.append(originCellInfoOwner)
        cellsInfo.append(originCellInfoTime)
        cellsInfo.append(statisticsCellInfoViewStats)
        cellsInfo.append(statisticsCellInfoInteractStats)
        return cellsInfo
    }
}
