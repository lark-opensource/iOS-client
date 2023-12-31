//
//  CreateTeamViewModel.swift
//  LarkTeam
//
//  Created by JackZhao on 2021/7/5.
//

import UIKit
import Foundation
import RustPB
import LarkTab
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
import LarkSetting

final class CreateTeamViewModel: TeamBaseViewModel {
    var name = "CreateTeamPage"
    var title = BundleI18n.LarkTeam.Project_MV_CustomizeYourTeam
    var leftItemInfo: String? = BundleI18n.LarkTeam.Lark_Legacy_Cancel
    var rightItemEnableRelay: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: true)
    var rightItemInfo: (Bool, String) = (true, BundleI18n.LarkTeam.Project_T_CreateButton)
    weak var fromVC: UIViewController?
    weak var targetVC: TeamBaseViewControllerAbility?
    var reloadData: Driver<Void> { return _reloadData.asDriver(onErrorJustReturn: ()) }
    private var _reloadData = PublishSubject<Void>()
    private(set) var items: TeamSectionDatasource = []
    private var isCreating: Bool

    private let disposeBag = DisposeBag()
    private(set) var checkNameDisposeBag = DisposeBag()
    private let teamAPI: TeamAPI
    private let currentUserId: String
    private let defaultAvatar: TeamAvatarMeta

    private var teamAvatarData: Data?
    private var teamAvatarMeta: RustPB.Basic_V1_AvatarMeta
    private var createTeamMode: Chat.ChatMode = .threadV2
    private var successCallback: ((Basic_V1_Team) -> Void)?

    // 团队名称输入框viewModel
    lazy var teamNameInputItem: TeamInputCellViewModel = {
        let attributedTitle = NSMutableAttributedString(string: BundleI18n.LarkTeam.Project_T_PutTeamNameHere)
        attributedTitle.append(NSAttributedString(string: " *", attributes: [.foregroundColor: UIColor.ud.colorfulRed]))
        return TeamInputCellViewModel(
            type: .input,
            cellIdentifier: TeamInputCell.lu.reuseIdentifier,
            style: .full,
            title: attributedTitle,
            maxCharLength: TeamConfig.inputMaxLength,
            placeholder: BundleI18n.LarkTeam.Project_T_GiveMeAName,
            errorToast: BundleI18n.LarkTeam.Project_T_TeamCannotNameEmpty,
            reloadWithAnimation: { [weak self] animated in
                self?.targetVC?.reloadWithAnimation(animated)
            })
    }()

    // 团队描述输入框viewModel
    lazy var teamDescriptionInputItem: TeamDescriptionInputViewModel = {
        let attributedTitle = NSMutableAttributedString(string: BundleI18n.LarkTeam.Project_MV_TeamDescriptionHere)
        attributedTitle.append(NSAttributedString(string: " *", attributes: [.foregroundColor: UIColor.ud.colorfulRed]))
        return TeamDescriptionInputViewModel(
            type: .input,
            cellIdentifier: TeamDescriptionInputCell.lu.reuseIdentifier,
            style: .full,
            title: attributedTitle,
            maxCharLength: TeamConfig.descriptionInputMaxLength,
            placeholder: BundleI18n.LarkTeam.Project_MV_SetTeamDescribe,
            errorToast: BundleI18n.LarkTeam.Project_T_DescriptionCannotEmpty,
            reloadWithAnimation: { [weak self] animated in
                self?.targetVC?.reloadWithAnimation(animated)
            },
            textFieldDidEndEditingTask: { (_, _) in
            }
        )
    }()
    let navigator: EENavigator.Navigatable
    let userResolver: UserResolver

    init(teamAPI: TeamAPI,
         currentUserId: String,
         userResolver: UserResolver,
         successCallback: ((Basic_V1_Team) -> Void)?) {
        self.teamAPI = teamAPI
        self.currentUserId = currentUserId
        self.successCallback = successCallback
        self.isCreating = false
        self.userResolver = userResolver
        self.navigator = userResolver.navigator
        let randomAvatar = Self.randomAvatar(userId: currentUserId, userResolver: userResolver)
        self.defaultAvatar = randomAvatar
        self.teamAvatarMeta = RustPB.Basic_V1_AvatarMeta()
        self.teamAvatarMeta.type = .random
        self.teamAvatarMeta.styleType = .border
        self.teamAvatarMeta.centerColor = 0xFFFFFF
        self.teamAvatarMeta.startColor = Int32(randomAvatar.startColor)
        self.teamAvatarMeta.endColor = Int32(randomAvatar.endColor)
    }

    func viewDidLoadTask() {
        // 发射初始化信号
        self.items = structureItems()
        _reloadData.onNext(())

        startToObserve()
        trackView()
    }

    func structureItems() -> TeamSectionDatasource {
        let sections = [
            teamAvatarConfigSection(),
            teamNameInputSection(),
            teamDescriptionInputSection()
        ].compactMap { $0 == nil ? $0 : $0?.items.isEmpty == true ? nil : $0 }
        return sections
    }

    // 团队头像section
    private func teamAvatarConfigSection() -> TeamSectionModel {
        return TeamSectionModel(items: [
            teamAvatarConfigItem()
        ].compactMap({ $0 }))
    }

    // 团队名称输入sectipn
    private func teamNameInputSection() -> TeamSectionModel {
        return TeamSectionModel(items: [
            teamNameInputItem
        ].compactMap({ $0 }))
    }

    // 团队描述输入sectipn
    private func teamDescriptionInputSection() -> TeamSectionModel {
        return TeamSectionModel(items: [
            teamDescriptionInputItem
        ].compactMap({ $0 }))
    }

    // 监听事件
    private func startToObserve() {
        // 将不同输入的enbale组合
        Observable.combineLatest(teamNameInputItem.rightItemEnableOb, teamDescriptionInputItem.rightItemEnableOb)
            .subscribe(onNext: { [weak self] (nameEnable, descriptionEnable) in
                self?.rightItemEnableRelay.accept(nameEnable && descriptionEnable)
            }, onError: { error in
                TeamMemberViewModel.logger.error("teamlog/combineLatest teamNameInputItem and teamDescriptionInputItem fail, error = \(error)")
            }).disposed(by: self.disposeBag)
    }

    // navitionbar close按钮点击事件
    func closeItemClick() {
        trackCancelCreate()
        guard (teamNameInputItem.text?.isChecked ?? false) || (teamDescriptionInputItem.text?.isChecked ?? false) else {
            self.targetVC?.dismiss(animated: true, completion: nil)
            return
        }
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.LarkTeam.Project_MV_QuitCreatTeam_PopupWindow)
        dialog.addCancelButton()
        dialog.addPrimaryButton(text: BundleI18n.LarkTeam.Project_MV_Close_Button,
                                dismissCompletion: { [weak self] in
            self?.targetVC?.dismiss(animated: true, completion: nil)
        })
        if let vc = self.targetVC {
            navigator.present(dialog, from: vc)
        }
    }

    // navitionbar右边按钮点击事件
    func rightItemClick() {
        guard let targetVC = self.targetVC else { return }

        guard !isCreating else { return }
        isCreating = true

        let window = self.targetVC?.view.window
        if let window = window {
            UDToast.showLoading(with: BundleI18n.LarkTeam.Project_T_CreatingATeamNow, on: window)
        }
        let avatarEntity: TeamAvatarEntity
        if let data = self.teamAvatarData {
            avatarEntity = .customize(avatarData: data, avatarMeta: teamAvatarMeta)
        } else {
            avatarEntity = .normal(key: self.defaultAvatar.key)
        }
        // 调用创建团队接口
        teamAPI.createTeamRequest(name: (teamNameInputItem.text ?? "").removeCharSpace,
                                  avatarEntity: avatarEntity,
                                  mode: self.createTeamMode,
                                  chatIds: [],
                                  chatterIds: [self.currentUserId],
                                  description: (teamDescriptionInputItem.text ?? "").removeCharSpace,
                                  departmentIds: [])
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self, weak targetVC] res in
                guard let self = self else { return }
                self.trackCreate(isSuccess: true)
                if let window = window {
                    UDToast.showSuccess(with: BundleI18n.LarkTeam.Project_T_TeamCreated_Toast, on: window)
                }
                targetVC?.dismiss(animated: true, completion: { [weak self] in
                    guard let self = self else { return }
                    if let successCallback = self.successCallback {
                        successCallback(res.team)
                    }
                })
                self.isCreating = false
            }, onError: { [weak self] error in
                self?.trackCreate(isSuccess: false)
                if let window = window {
                    UDToast.showFailure(with: BundleI18n.LarkTeam.Project_MV_UnableToCreateToast, on: window, error: error)
                }
                TeamMemberViewModel.logger.error("teamlog/createTeamRequest fail, error = \(error)")
                self?.isCreating = false
            }).disposed(by: self.disposeBag)
    }
}

// MARK: cellViewModel 的实现方法
extension CreateTeamViewModel {
    private func teamAvatarConfigItem() -> TeamCellViewModelProtocol? {
        var avatarImage: UIImage?
        if let teamAvatarData = self.teamAvatarData {
            avatarImage = UIImage(data: teamAvatarData)
        }
        return TeamAvatarConfigViewModel(type: .default,
                                         cellIdentifier: TeamAvatarConfigCell.lu.reuseIdentifier,
                                         style: .full,
                                         entityId: "",
                                         avatarKey: defaultAvatar.key,
                                         avatarImage: avatarImage,
                                         title: BundleI18n.LarkTeam.Project_MV_TeamProfilePicture,
                                         tapAvatarHandler: { [weak self] in
                                            self?.jumpToCustomizeAvatarController()
                                         })
    }
}

struct TeamAvatarMeta {
    let key: String
    let startColor: Int64
    let endColor: Int64
}

// MARK: handler
extension CreateTeamViewModel {
    // 本地生成随机的头像key（目前三端对齐用这种方式，且产品也知悉）
    private static func randomAvatar(userId: String, userResolver: UserResolver) -> TeamAvatarMeta {
        guard Feature.avatarFG(userID: userId) else {
            return Self.defaultAvatar()
        }
        guard let setting = Self.getSettingJson(key: .make(userKeyLiteral: "team_default_avatar"), userResolver: userResolver),
              let array = setting["borderStyleMergedIconKeys"] as? [Any],
              !array.isEmpty else {
            return Self.defaultAvatar()
        }
        let avatarArray: [TeamAvatarMeta] = array.compactMap({ item in
            if let dic = item as? [String: Any],
               let key = dic["key"] as? String,
                let startColor = dic["startColor"] as? Int64,
                let endColor = dic["endColor"] as? Int64 {
                return TeamAvatarMeta(key: key, startColor: startColor, endColor: endColor)
            }
            return nil
        })
        guard !avatarArray.isEmpty else {
            return Self.defaultAvatar()
        }
        return avatarArray.randomElement() ?? avatarArray[0]
    }

    static func defaultAvatar() -> TeamAvatarMeta {
        let avatarArray: [String] = [
            "default-avatar_4d386149-2385-471d-bd2d-37bae05d812c", // 1
            "default-avatar_4ea03a71-56b9-435c-bf29-05d8703a606f", // 2
            "default-avatar_8ee43cee-985e-4ce7-835d-65da0afc1169", // 3
            "default-avatar_62543518-ab90-4962-b60b-d41b791c8e84", // 4
            "default-avatar_a24872a7-3afd-4d63-80ee-0c402de59a41", // 5
            "default-avatar_dc6fc8f9-09dc-48a4-80c6-2de25c2a279f", // 6
            "default-avatar_dd2a4d13-8a80-4090-b7f0-7c38e6c8f530", // 7
            "default-avatar_f4c3cd4a-9a70-4089-b41f-810bc2a45d34"  // 8
        ]
        let key = avatarArray.randomElement() ?? avatarArray[0]
        return TeamAvatarMeta(key: key, startColor: 0, endColor: 0)
    }

    private static func getSettingJson(key: UserSettingKey, userResolver: UserResolver) -> [String: Any]? {
        do {
            let settingService = try? userResolver.resolve(assert: SettingService.self)
            guard let setting = try settingService?.setting(with: key) else {
                TeamMemberViewModel.logger.error("teamlog/setting/\(key).")
                return nil
            }
            return setting
        } catch {
            TeamMemberViewModel.logger.error("teamlog/setting/\(key).")
            return nil
        }
    }

    private func jumpToCustomizeAvatarController() {
        // 使用data的形式，无法使用entityId
        let defaultCenterIcon = Feature.avatarFG(userID: currentUserId) ? Resources.newStyle_team_icon : Resources.defalut_team_icon
        var body = TeamCustomizeAvatarBody(avatarKey: defaultAvatar.key,
                                       entityId: "",
                                       name: teamNameInputItem.text,
                                       imageData: teamAvatarData,
                                       avatarMeta: teamAvatarMeta,
                                       defaultCenterIcon: defaultCenterIcon)
        body.savedCallback = { [weak self] iconImage, avatarMeta, targetVC, _ in
            guard let self = self else { return }
            let iconData = iconImage.pngData() ?? Data()
            self.teamAvatarData = iconData
            self.teamAvatarMeta = avatarMeta

            self.items = self.structureItems()
            self._reloadData.onNext(())
            targetVC.dismiss(animated: true, completion: nil)
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

// MARK: tool
extension CreateTeamViewModel {
    private func trackView() {
        TeamTracker.trackImCreateTeamView()
    }

    private func trackCreate(isSuccess: Bool) {
        TeamTracker.trackImCreateTeamClick(click: "create",
                                           target: "none",
                                           isSuccess: isSuccess)
    }

    private func trackCancelCreate() {
        TeamTracker.trackImCreateTeamClick(click: "cancel", target: "none")
    }
}
