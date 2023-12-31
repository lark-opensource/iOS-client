//
//  CreateGroupModeViewController.swift
//  LarkContact
//
//  Created by 姚启灏 on 2019/2/26.
//

import UIKit
import Foundation
import RxSwift
import LarkUIKit
import LarkModel
import EENavigator
import LarkAlertController
import LarkMessengerInterface
import RxCocoa
import LarkContainer
import Swinject
import LarkSDKInterface
import LarkAccountInterface
import LKCommonsLogging

final class GroupScopeSelectView: UIView {
    private var isPublic: Bool
    private let didSelectedBlock: (Bool) -> Void
    private let privateGroupView = GroupModeDescView(
        title: BundleI18n.LarkContact.Lark_Group_CreateGroup_TypeSwitch_Private,
        desc: BundleI18n.LarkContact.Lark_Group_CreateGroup_TypeSwitch_Private_Tip
    )
    private let publicGroupView = GroupModeDescView(
        title: BundleI18n.LarkContact.Lark_Group_CreateGroup_TypeSwitch_Public,
        desc: BundleI18n.LarkContact.Lark_Group_CreateGroup_TypeSwitch_Public_Tip
    )
    weak var hostViewController: UIViewController?

    init(isPublic: Bool,
         didSelectedBlock: @escaping (Bool) -> Void) {
        self.isPublic = isPublic
        self.didSelectedBlock = didSelectedBlock
        super.init(frame: .zero)
        self.setupUI()
        self.updateView(isPublic: self.isPublic)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateView(isPublic: Bool) {
        self.isPublic = isPublic
        publicGroupView.isSelected = isPublic
        privateGroupView.isSelected = !isPublic
    }

    private func setupUI() {
        self.addSubview(privateGroupView)
        privateGroupView.snp.makeConstraints { (make) in
            make.leading.top.trailing.equalToSuperview()
        }
        privateGroupView.lu.addTopBorder()

        self.addSubview(publicGroupView)
        publicGroupView.snp.makeConstraints { (make) in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(privateGroupView.snp.bottom)
        }
        publicGroupView.lu.addTopBorder()
        publicGroupView.lu.addBottomBorder()

        publicGroupView.delegate = self
        privateGroupView.delegate = self
    }
}

extension GroupScopeSelectView: GroupModeDescViewDelegate {
    func didSelected(_ view: GroupModeDescView, isSelected: Bool) {
        let currentSelected = !isSelected

        if self.privateGroupView == view, currentSelected == true {
            view.isSelected = currentSelected
            Tracer.trackGoupTypePrivate()
            self.publicGroupView.isSelected = false
            self.isPublic = false
        } else {
            Tracer.trackGoupTypePublic()
            self.didSelectPublicItem()
        }
        self.didSelectedBlock(self.isPublic)
    }

    private func didSelectPublicItem() {
        self.privateGroupView.isSelected = false
        self.publicGroupView.isSelected = true
        self.isPublic = true
    }

}

public final class GroupModeViewController: BaseUIViewController, UserResolverWrapper {
    private static let logger = Logger.log(GroupModeViewController.self, category: "Module.IM.CreateGroup")
    private let switchModeView: SwitchModeView

    private let completionFunc: CompletionFunc
    private let hasSelectedExternalChatter: Bool
    private let hasSelectedChatOrDepartment: Bool
    private let ability: CreateAbility
    public var userResolver: LarkContainer.UserResolver
    private var currentChatterId: String {
        return self.userResolver.userID
    }

    @ScopedInjectedLazy private var contactAPI: ContactAPI?
    private let disposeBag: DisposeBag = DisposeBag()

    override public func backItemTapped() {
        Tracer.trackGoupTypeCancel()
        super.backItemTapped()
    }

    init(
        modeType: ModelType,
        ability: CreateAbility,
        completion: @escaping CompletionFunc,
        hasSelectedExternalChatter: Bool,
        hasSelectedChatOrDepartment: Bool,
        resolver: UserResolver
    ) {
        self.completionFunc = completion
        self.hasSelectedExternalChatter = hasSelectedExternalChatter
        self.hasSelectedChatOrDepartment = hasSelectedChatOrDepartment
        self.ability = ability
        self.userResolver = resolver
        let switchModeView = SwitchModeView(
            modeType: modeType,
            ability: ability
        )
        self.switchModeView = switchModeView
        super.init(nibName: nil, bundle: nil)
        self.switchModeView.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        self.title = BundleI18n.LarkContact.Lark_Group_CreateGroup_Mode_Title
        self.view.backgroundColor = UIColor.ud.bgBase
        self.view.addSubview(switchModeView)
        switchModeView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(12)
            make.left.right.bottom.equalToSuperview()
        }

        if self.ability.contains(.privateChat) {
            self.getPrivateChatAuth()
            self.fetchPrivateChatAuth()
        }
    }

    private func getPrivateChatAuth() {
        self.contactAPI?
            .getAuthChattersRequestFromLocal(actionType: .privateChat,
                                             chattersAuthInfo: [currentChatterId: ""])
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (res) in
                self?.handleAuthResponse(res)
            }, onError: { (error) in
                Self.logger.error("getAuthChattersRequest error, error = \(error)")
            }).disposed(by: self.disposeBag)
    }

    private func fetchPrivateChatAuth() {
        self.contactAPI?
            .fetchAuthChattersRequest(actionType: .privateChat,
                                      isFromServer: true,
                                      chattersAuthInfo: [currentChatterId: ""])
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (res) in
                self?.handleAuthResponse(res)
            }, onError: { (error) in
                Self.logger.error("fetchAuthChattersRequest error, error = \(error)")
            }).disposed(by: self.disposeBag)
    }

    private func handleAuthResponse(_ response: FetchAuthChattersResponse) {
        guard response.authResult.deniedReasons[currentChatterId] == nil else {
            Self.logger.info("no permission to create private mode chat")
            self.switchModeView.hasPrivateModePermission = false
            return
        }
        self.switchModeView.hasPrivateModePermission = true
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // switchModeView在密聊FG和话题FG都为false时不会创建
        self.completionFunc(self.switchModeView.value)
    }
}

extension GroupModeViewController: SwitchGroupModelViewDelegate {

    func shouldSelecteDriver(newModelType: ModelType) -> Driver<Bool> {
        return Observable.create { [weak self] (observer) -> Disposable in
            guard let self = self else {
                observer.onError(NSError(domain: "self nil", code: -1, userInfo: nil))
                return Disposables.create()
            }
            guard let window = self.view.window else {
                assertionFailure("缺少路由跳转Window")
                observer.onError(NSError(domain: "缺少路由跳转Window", code: -1, userInfo: nil))
                return Disposables.create()
            }

            if self.hasSelectedChatOrDepartment,
               newModelType == .secret {
                let alertController = LarkAlertController()
                alertController.setTitle(text: BundleI18n.LarkContact.Lark_Group_SecretChatGroupInviteDisabled)
                alertController.addSecondaryButton(
                    text: BundleI18n.LarkContact.Lark_Chat_Create_Group_Switch_Type_PublicChatAddExternalUser_ErrorAlter_Cancel,
                    dismissCompletion: {
                        observer.onNext(false)
                        observer.onCompleted()
                    }
                )
                alertController.addSecondaryButton(
                    text: BundleI18n.LarkContact.Lark_Chat_Create_Group_Switch_Type_PublicChatAddExternalUser_ErrorAlter_Confirm,
                    dismissCompletion: {
                        observer.onNext(true)
                        observer.onCompleted()
                    }
                )
                self.navigator.present(alertController, from: window)
                return Disposables.create()
            }
            if self.hasSelectedExternalChatter,
               newModelType == .privateChat {
                let alertController = LarkAlertController()
                alertController.setContent(text: BundleI18n.LarkContact.Lark_IM_EncryptedChat_UnableToAddExternalUserOrGroupConfirmToConvert_Title)
                alertController.addSecondaryButton(
                    text: BundleI18n.LarkContact.Lark_IM_EncryptedChat_UnableToAddExternalUserOrGroupConfirmToConvert_Cancel_Button,
                    dismissCompletion: {
                        observer.onNext(false)
                        observer.onCompleted()
                    }
                )
                alertController.addSecondaryButton(
                    text: BundleI18n.LarkContact.Lark_IM_EncryptedChat_UnableToAddExternalUserOrGroupConfirmToConvert_Convert_Button,
                    dismissCompletion: {
                        observer.onNext(true)
                        observer.onCompleted()
                    }
                )
                self.navigator.present(alertController, from: window)
                return Disposables.create()
            }

            observer.onNext(true)
            observer.onCompleted()
            return Disposables.create()
        }.asDriver(onErrorJustReturn: false)
    }
}
