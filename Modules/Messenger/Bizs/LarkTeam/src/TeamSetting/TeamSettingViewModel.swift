//
//  TeamSettingViewModel.swift
//  LarkTeam
//
//  Created by JackZhao on 2021/7/9.
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

// 团队设置页ViewModel
final class TeamSettingViewModel: TeamBaseViewModel {
    var name = "TeamSettingPage"
    var title = BundleI18n.LarkTeam.Project_T_ManageYourTeams
    var rightItemInfo: (Bool, String) = (false, "")
    var rightItemEnableRelay: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: true)
    weak var fromVC: UIViewController?
    weak var targetVC: TeamBaseViewControllerAbility?
    var reloadData: Driver<Void> {
        return _reloadData.asDriver(onErrorJustReturn: ())
    }
    var _reloadData = PublishSubject<Void>()
    var items: TeamSectionDatasource = []

    let teamAPI: TeamAPI
    let pushTeams: Observable<PushTeams>
    let pushItems: Observable<PushItems>
    let currentUserId: String
    let teamMembersMaxCount: Int
    let disposeBag = DisposeBag()
    // init status for track
    let initMemberCount: Int32
    let initAddGroupHash: Int
    let initAddMemberHash: Int

    var team: Team
    var memberList: [TeamMemberHorizItem] = []
    var needReGetData = false
    let navigator: EENavigator.Navigatable

    init(team: Team,
         teamMembersMaxCount: Int,
         currentUserId: String,
         teamAPI: TeamAPI,
         pushTeams: Observable<PushTeams>,
         pushItems: Observable<PushItems>,
         navigator: EENavigator.Navigatable) {
        self.team = team
        self.teamMembersMaxCount = teamMembersMaxCount
        self.currentUserId = currentUserId
        self.teamAPI = teamAPI
        self.pushTeams = pushTeams
        self.pushItems = pushItems
        self.initMemberCount = team.memberCount
        self.initAddGroupHash = team.setting.addTeamChatPermission.hashValue
        self.initAddMemberHash = team.setting.addMemberPermission.hashValue
        self.navigator = navigator
    }

    func viewDidLoadTask() {
        // 发射初始化信号
        self.fireRefresh()
        startToObserve()
        trackView()
    }

    func viewWillAppearTask() {
        if self.needReGetData {
            getTeamMembers()
            self.needReGetData = false
        }
    }

    func viewWillDisappearTask() {
        self.needReGetData = true
    }

    func closeItemClick() {
        trackExit()
        self.targetVC?.dismiss(animated: true, completion: nil)
    }
}
