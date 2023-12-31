//
//  TeamInfoViewModel.swift
//  LarkTeam
//
//  Created by JackZhao on 2021/8/17.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import LarkCore
import LarkUIKit
import LarkModel
import EENavigator
import LarkContainer
import LarkSDKInterface
import LKCommonsLogging
import UniverseDesignToast
import UniverseDesignDialog
import LarkMessengerInterface
import RustPB

// 团队信息页ViewModel
final class TeamInfoViewModel: TeamBaseViewModel {

    var name = "TeamInfoPage"
    var title = BundleI18n.LarkTeam.Project_MV_SubtitleEditTeamInfo
    var rightItemInfo: (Bool, String) = (false, "")
    var rightItemEnableRelay: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: true)
    weak var fromVC: UIViewController?
    weak var targetVC: TeamBaseViewControllerAbility?
    private(set) var items: TeamSectionDatasource = []
    var reloadData: Driver<Void> { return _reloadData.asDriver(onErrorJustReturn: ()) }
    private var _reloadData = PublishSubject<Void>()

    private(set) var disposeBag = DisposeBag()
    private let teamAPI: TeamAPI
    private let pushTeams: Observable<PushTeams>
    private let scheduler = SerialDispatchQueueScheduler(internalSerialQueueName: "team.infoPage.scheduler")

    private var team: Team
    let navigator: EENavigator.Navigatable
    let userResolver: UserResolver
    private var teamAvatarMeta = RustPB.Basic_V1_AvatarMeta()

    init(team: Team,
         teamAPI: TeamAPI,
         pushTeams: Observable<PushTeams>,
         userResolver: UserResolver) {
        self.team = team
        self.teamAPI = teamAPI
        self.pushTeams = pushTeams
        self.userResolver = userResolver
        self.navigator = userResolver.navigator
    }

    func viewDidLoadTask() {
        // 发射初始化信号
        self.items = structureItems()
        _reloadData.onNext(())
        startToObserve()
    }

    func structureItems() -> TeamSectionDatasource {
        let sections = [
            self.teamInfoSection()
        ].compactMap { $0 == nil ? $0 : $0?.items.isEmpty == true ? nil : $0 }
        return sections
    }

    private func teamInfoSection() -> TeamSectionModel {
        return TeamSectionModel(items: [
            teamAvatarCellItem(),
            teamNameCellItem(),
            teamDescriptionItem()
        ].compactMap({ $0 }))
    }

    private func startToObserve() {
        let teamId = team.id

        let pushOb = pushTeams
            .flatMap { [weak self] push -> Observable<Void> in
                guard let self = self else { return .empty() }
                if let team = push.teams[teamId] {
                    self.team = team
                    return .just(())
                }
                return .empty()
            }

        Observable.merge([pushOb])
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.items = self.structureItems()
                self._reloadData.onNext(())
            }, onError: { error in
                TeamMemberViewModel.logger.error("teamlog/pushTeams error, error = \(error) ")
            }).disposed(by: self.disposeBag)

        teamAPI.pullAvatarMeta(teamID: teamId)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] response in
                guard let self = self else { return }
                let avatarMeta = response.avatarMeta
                self.teamAvatarMeta.type = Basic_V1_AvatarMeta.TypeEnum(rawValue: avatarMeta.type.rawValue) ?? .random
                self.teamAvatarMeta.color = avatarMeta.color
                self.teamAvatarMeta.text = avatarMeta.text
                self.teamAvatarMeta.borderColor = avatarMeta.borderColor
                self.teamAvatarMeta.backgroundColor = avatarMeta.backgroundColor
                self.teamAvatarMeta.styleType = Basic_V1_AvatarMeta.AvatarStyleType(rawValue: avatarMeta.styleType.rawValue) ?? .border
                self.teamAvatarMeta.centerColor = Int32(avatarMeta.centerColor)
                self.teamAvatarMeta.startColor = Int32(avatarMeta.startColor)
                self.teamAvatarMeta.endColor = Int32(avatarMeta.endColor)
                TeamMemberViewModel.logger.info("teamlog/pullAvatarMeta. \(teamId) color:\(avatarMeta.color), startColor:\(avatarMeta.startColor), endColor:\(avatarMeta.endColor)")
            }, onError: { error in
                TeamMemberViewModel.logger.error("teamlog/pullAvatarMeta. \(teamId)", error: error)
            }).disposed(by: self.disposeBag)
    }
}

// cellViewModel 组装的扩展
extension TeamInfoViewModel {
    // 团队头像
    private func teamAvatarCellItem() -> TeamCellViewModelProtocol? {
        return TeamAvatarCellViewModel(type: .default,
                                       cellIdentifier: TeamAvatarCell.lu.reuseIdentifier,
                                       style: .half,
                                       title: BundleI18n.LarkTeam.Project_MV_TeamProfilePicture,
                                       avatarKey: team.avatarKey,
                                       avatarId: String(team.id)) { [weak self] _ in
            self?.avatarTapped()
        }
    }

    // 团队名称
    private func teamNameCellItem() -> TeamCellViewModelProtocol? {
        let subTitle = NSAttributedString(string: team.name)
        return TeamNameCellViewModel(type: .default,
                                     cellIdentifier: TeamNameCell.lu.reuseIdentifier,
                                     style: .half,
                                     isShowArrow: true,
                                     title: BundleI18n.LarkTeam.Project_MV_AsteriskTeamName,
                                     subTitle: subTitle) { [weak self] _ in
            guard let self = self else { return }
            if let targetVC = self.targetVC {
                let body = TeamNameConfigBody(team: self.team, hasAccess: self.team.isTeamManagerForMe)
                self.navigator.push(body: body, from: targetVC)
            }
        }
    }

    // 团队描述
    private func teamDescriptionItem() -> TeamCellViewModelProtocol? {
        return TeamDescriptionCellViewModel(type: .default,
                                            cellIdentifier: TeamDescriptionCell.lu.reuseIdentifier,
                                            style: .full,
                                            title: BundleI18n.LarkTeam.Project_MV_TeamDescriptionHere,
                                            description: team.description_p) { [weak self] _ in
            guard let self = self else { return }
            if let vc = self.targetVC {
                self.navigator.push(body: TeamDescriptionBody(team: self.team), from: vc)
            }
        }
    }
}

// MARK: handler
extension TeamInfoViewModel {
    private func avatarTapped() {
        if team.isTeamManagerForMe {
            jumpToCustomizeAvatarController()
        } else {
            previewAvatar()
        }
    }

    private func previewAvatar() {
        let asset = LKDisplayAsset.createAsset(avatarKey: team.avatarKey, chatID: "\(team.defaultChatID)").transform()
        let body = PreviewImagesBody(assets: [asset],
                                     pageIndex: 0,
                                     scene: .normal(assetPositionMap: [:], chatId: nil),
                                     shouldDetectFile: false,
                                     canShareImage: false,
                                     canEditImage: false,
                                     canTranslate: Feature.imageViewerInOtherScenesTranslateEnable(userID: self.userResolver.userID),
                                     translateEntityContext: (nil, .other))
        if let from = self.targetVC {
            navigator.present(body: body, from: from)
        }
    }

    private func jumpToCustomizeAvatarController() {
        let defaultCenterIcon = Feature.avatarFG(userID: self.userResolver.userID) ? Resources.newStyle_team_icon : Resources.defalut_team_icon

        var body = TeamCustomizeAvatarBody(avatarKey: team.avatarKey,
                                       entityId: String(team.id),
                                       name: team.name,
                                       imageData: nil,
                                       avatarMeta: teamAvatarMeta,
                                           defaultCenterIcon: defaultCenterIcon)
        body.savedCallback = { [weak self] (image, meta, vc, _) in
            if let view = vc.view {
                UDToast.showLoading(with: BundleI18n.LarkTeam.Lark_Legacy_BaseUiLoading, on: view)
            }
            guard let self = self else { return }
            self.teamAvatarMeta = meta
            let data = image.pngData() ?? Data()
            let avatarEntity: TeamAvatarEntity = .customize(avatarData: data, avatarMeta: meta)
            self.teamAPI.patchTeamAvatarRequest(teamId: self.team.id, avatarEntity: avatarEntity)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak vc] _ in
                    if let window = vc?.view.window {
                        UDToast.showSuccess(with: BundleI18n.LarkTeam.Lark_Legacy_SaveSuccess, on: window)
                    }
                    vc?.dismiss(animated: true, completion: nil)
                }, onError: { [weak vc] error in
                    if let window = vc?.view.window {
                        UDToast.showFailure(with: BundleI18n.LarkTeam.Project_T_CantSetToast,
                                            on: window,
                                            error: error)
                    }
                    vc?.dismiss(animated: true, completion: nil)
                    TeamMemberViewModel.logger.error("teamlog/patchTeamAvatarRequest error, error = \(error) ")
                }).disposed(by: self.disposeBag)
        }
        if let from = self.targetVC {
            navigator.present(
                body: body,
                wrap: LkNavigationController.self,
                from: from,
                prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() }
            )
        }
    }
}

// MARK: cell or vm ailas
// 团队名称
typealias TeamNameCell = TeamInfoCell

typealias TeamNameCellViewModel = TeamInfoCellViewModel
