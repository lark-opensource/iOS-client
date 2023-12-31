//
//  GroupApplyForLimitViewModel.swift
//  LarkChatSetting
//
//  Created by bytedance on 2021/10/15.
//

import UIKit
import Foundation
import EENavigator
import ServerPB
import LarkRustClient
import LarkSDKInterface
import RxSwift
import RxCocoa
import LKCommonsLogging
import LarkModel
import UniverseDesignToast
import LarkCore
import LarkUIKit
import LKCommonsTracker
import LarkMessengerInterface
import LarkFeatureGating
import LarkAccountInterface
import LarkContainer
import LarkOpenChat

private struct ApplyUpperTypeModel {
    fileprivate var applyUpperType: ServerPB.ServerPB_Misc_PullChatMemberSuppRoleApprovalSettingResponse.ApplyType?
    fileprivate var seletedKey: String?

    fileprivate init(applyUpperType: ServerPB.ServerPB_Misc_PullChatMemberSuppRoleApprovalSettingResponse.ApplyType) {
        if !applyUpperType.defaultOption.isEmpty, !applyUpperType.options.isEmpty {
            self.applyUpperType = applyUpperType
            self.seletedKey = applyUpperType.defaultOption
        }
    }
}

final class GroupApplyForLimitViewModel: UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    @ScopedInjectedLazy var passportUserService: PassportUserService?

    fileprivate static let logger = Logger.log(GroupApplyForLimitViewModel.self, category: "Module.IM.LarkChatSetting")
    private let chatID: String
    private let chatAPI: ChatAPI
    private let chatterAPI: ChatterAPI
    private(set) var items: CommonDatasource!
    private let disposeBag = DisposeBag()
    private var approvers = [ApproverItem]()
    private var applyUpperLimit: Int32?
    private var applyUpperLimitOptions = [Int32]()
    private var upperTypeModel: ApplyUpperTypeModel?

    private var chatModel: Chat? {
        didSet {
            if oldValue == nil, let chat = chatModel {
                self.getChat?(chat)
            }
        }
    }
    private var applyDescription = "" {
        didSet {
            controller?.setRightItemEnable(!applyDescription.isEmpty)
        }
    }

    //是否正在提交；用于避免连续点击提交发起多个审批
    private var isSubmiting = false

    weak var controller: GroupApplyForLimitViewController?

    var reloadData: Driver<Void> { _reloadData.asDriver(onErrorJustReturn: ()) }
    private var _reloadData = PublishSubject<Void>()
    var getChat: ((Chat) -> Void)?

    init(chatID: String, chatAPI: ChatAPI, chatterAPI: ChatterAPI, userResolver: UserResolver) {
        self.chatAPI = chatAPI
        self.chatID = chatID
        self.chatterAPI = chatterAPI
        self.userResolver = userResolver
        items = structureItems()
    }

    func fetchData() {
        fetchChat()
        fetchChatMemberSuppRoleApprovalSetting()
    }

    private func fetchChat() {
        chatAPI.fetchChat(by: chatID, forceRemote: false)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] chat in
                guard let self = self else { return }
                self.chatModel = chat
                self.items = self.structureItems()
                self._reloadData.onNext(())
            } onError: { error in
                Self.logger.error("ApplyForLimit trace  fetchChat error, error = \(error)")
            }.disposed(by: disposeBag)
    }

    private func fetchChatMemberSuppRoleApprovalSetting() {
        guard let tenantId = passportUserService?.user.tenant.tenantID,
              let tenantId = Int64(tenantId),
              let chatId = Int64(chatID) else { return }

        chatAPI.pullChatMemberSetting(tenantId: tenantId, chatId: chatId)
            .observeOn(MainScheduler.instance)
            .do(onNext: { [weak self] res in
                guard let self = self else { return }
                self.applyUpperLimit = res.chatMemberUpperLimit
                Self.logger.info("ApplyForLimit trace pullChatMemberSetting \(self.chatID) \(res.chatMemberUpperLimit)")
            })
            .flatMap({ [weak self] _ -> Observable<ServerPB.ServerPB_Misc_PullChatMemberSuppRoleApprovalSettingResponse> in
                guard let self = self else { return .empty() }
                return self.chatAPI.pullChatMemberSuppRoleApprovalSetting(tenantId: tenantId, applyUpperLimit: self.applyUpperLimit)
            })
            .observeOn(MainScheduler.instance)
            .flatMap({ [weak self] res -> Observable<[ApproverItem]> in
                guard let self = self else { return .empty() }
                self.applyUpperLimitOptions = res.applyUpperLimitOptions
                self.upperTypeModel = ApplyUpperTypeModel(applyUpperType: res.applyType)
                self.items = self.structureItems()
                Self.logger.info("""
                                 ApplyForLimit trace fetchChatMemberSuppRoleApprovalSetting
                                 \(self.chatID) \(res.applyUpperLimitOptions.count)
                                 \(res.applyType.defaultOption.isEmpty)
                                 \(res.applyType.options.count)
                                 \(res.approverIds.count)
                                 """)
                self._reloadData.onNext(())
                return self.chatterAPI.fetchChatChatters(ids: res.approverIds.map { "\($0)" }, chatId: self.chatID).map { chattermap in
                    return res.approverIds.compactMap({ chatterId in
                        if let chatter = chattermap["\(chatterId)"] {
                            return ApproverItem(id: chatter.id,
                                                avatarKey: chatter.avatarKey,
                                                name: chatter.displayWithAnotherName)
                        }
                        return nil
                    })
                }
            })
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] items in
                self?.setApprovers(items)
            } onError: {[weak self] error in
                guard let self = self else {
                    return
                }
                Self.logger.error("ApplyForLimit trace fetchChatMemberSuppRoleApprovalSetting error, \(self.chatID) error = \(error)")
            }.disposed(by: disposeBag)
    }

    // 随着申请配置变化，审批人需要重新拉取
    private func refreshChatMemberSuppRoleApprovalChatterIds() {
        guard let tenantId = passportUserService?.user.tenant.tenantID,
              let tenantId = Int64(tenantId)
        else { return }
        Self.logger.info("ApplyForLimit trace  refreshChatMemberSuppRoleApprovalChatterIds \(self.chatID) \(self.applyUpperLimit ?? -1) \(upperTypeModel?.seletedKey ?? "")")
        chatAPI
            .pullChatMemberSuppRoleApprovalChatterIds(tenantId: tenantId,
                                                         applyTypeKey: upperTypeModel?.seletedKey,
                                                         applyUpperLimit: self.applyUpperLimit)
            .observeOn(MainScheduler.instance)
            .flatMap({ [weak self] res -> Observable<[ApproverItem]> in
                guard let self = self else { return .empty() }
                return self.chatterAPI.fetchChatChatters(ids: res.map { "\($0)" }, chatId: self.chatID).map { chattermap in
                    return res.compactMap({ chatterId in
                        if let chatter = chattermap["\(chatterId)"] {
                            return ApproverItem(id: chatter.id,
                                                avatarKey: chatter.avatarKey,
                                                name: chatter.displayWithAnotherName)
                        }
                        return nil
                    })
                }
            })
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] items in
                self?.setApprovers(items)
            } onError: { [weak self] error in
                Self.logger.error("ApplyForLimit trace refreshChatMemberSuppRoleApprovalChatterIds error chatId \(self?.chatID ?? "")", error: error)
            }.disposed(by: disposeBag)
    }

    private func setApprovers(_ items: [ApproverItem]) {
        self.approvers.removeAll()
        self.approvers.append(contentsOf: items)
        Self.logger.info("ApplyForLimit trace setApprovers \(self.chatID) \(items.count)")
        self.items = self.structureItems()
        self._reloadData.onNext(())
    }

    private func structureItems() -> CommonDatasource {
        let sections: CommonDatasource = [
            groupInfoSection(),
            currentLimitSection(),
            applyTypeSection(),
            applyInfoSection(),
            approversSection()
        ].compactMap { $0 == nil ? $0 : $0?.items.isEmpty == true ? nil : $0 }
        return sections
    }
    private func groupInfoSection() -> CommonSectionModel? {
        let groupInfoItem = ChatInfoNameModel(
            type: .groupInfo,
            cellIdentifier: ChatInfoNameCell.lu.reuseIdentifier,
            style: .auto,
            avatarKey: chatModel?.avatarKey ?? "",
            entityId: chatID,
            name: chatModel?.displayName ?? "",
            nameTagTypes: [],
            description: "",
            canBeShared: false,
            showEditIcon: false,
            showCryptoIcon: false,
            showArrow: false,
            avatarTapHandler: {},
            tapHandler: { _ in return },
            avatarLayout: { make in
                make.top.left.bottom.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 0))
                make.width.height.equalTo(32)
            },
            infoAndQRCodeStackLayout: { make in
                make.left.equalToSuperview().offset(16 + 32 + 12)
                make.right.equalToSuperview().offset(-16)
                make.centerY.equalToSuperview()
            },
            nameLabelFont: .systemFont(ofSize: 14, weight: .regular))
        return CommonSectionModel(title: nil, items: [groupInfoItem])
    }

    //选择群成员上限
    private func currentLimitSection() -> CommonSectionModel? {
        let currentLimitItem = GroupSettingTransferItem(
            type: .currentLimit,
            cellIdentifier: GroupSettingTransferCell.lu.reuseIdentifier,
            style: .auto,
            title: applyUpperLimit?.description ?? ""
        ) { [weak self] _ in
            guard let self = self,
                  let vc = self.controller,
                  let applyUpperLimit = self.applyUpperLimit
                  else {
                return
            }
            if self.applyUpperLimitOptions.isEmpty {
                return
            }
            let vm = GroupSettingChooseLimitViewModel(options: self.applyUpperLimitOptions, currentOption: applyUpperLimit)
            vm.callback = { [weak self] value in
                guard let self = self else { return }
                self.applyUpperLimit = value
                self.items = self.structureItems()
                self._reloadData.onNext(())
                self.refreshChatMemberSuppRoleApprovalChatterIds()
            }
            self.navigator.present(GroupSettingChooseLimitViewController(viewModel: vm),
                                     wrap: LkNavigationController.self,
                                     from: vc,
                                     prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() },
                                     animated: true)
        }
        return CommonSectionModel(title: BundleI18n.LarkChatSetting.Lark_GroupLimit_SelectUpperLimitGroupSize_Subtitle, items: [currentLimitItem])
    }

    //申请类型
    private func applyTypeSection() -> CommonSectionModel? {
        guard let upperType = self.upperTypeModel?.applyUpperType else { return nil }
        let defaultOptionKey = self.upperTypeModel?.seletedKey ?? ""
        let title = BundleI18n.LarkChatSetting.Lark_GroupSettings_AppealType_Title
        var items: [ChatSettingCellVMProtocol] = []
        Self.logger.info("ApplyForLimit trace applyTypeSection \(self.chatID) \(upperType.options.count)")
        upperType.options.forEach { option in
            let selected = defaultOptionKey == option.key
            let item = GroupSettingSelectItem(type: .applyType,
                                              cellIdentifier: GroupSettingSelectItemCell.lu.reuseIdentifier,
                                              style: .half,
                                              selected: selected,
                                              key: option.key,
                                              description: option.text) { [weak self] key in
                guard let self = self else { return }
                if let seletedKey = self.upperTypeModel?.seletedKey,
                    seletedKey == key {
                    return
                }
                self.upperTypeModel?.seletedKey = key
                self.items = self.structureItems()
                self._reloadData.onNext(())
                self.refreshChatMemberSuppRoleApprovalChatterIds()
            }
            items.append(item)
        }
        return CommonSectionModel(title: title, items: items)
    }

    //申请用途
    private func applyInfoSection() -> CommonSectionModel? {
        var title = BundleI18n.LarkChatSetting.Lark_GroupLimit_ReasonForAppeal_Subtitle
        var placeholder = BundleI18n.LarkChatSetting.Lark_GroupLimit_ReasonForAppeal_Placeholder
        /// 如果没有 applyUpperType 维持原有逻辑
        if let key = self.upperTypeModel?.seletedKey,
           let applyUpperType = self.upperTypeModel?.applyUpperType,
           let option = applyUpperType.options.first(where: { $0.key == key }) {
            title = option.title
            placeholder = option.placeholder
        }

        let applyInfoItem = GroupSettingInputItem(
            type: .applyInfo,
            cellIdentifier: GroupSettingInputCell.lu.reuseIdentifier,
            style: .auto,
            placeholder: placeholder,
            height: 124) { [weak self] text in
            self?.applyDescription = text
        }
        return CommonSectionModel(title: title, items: [applyInfoItem])
    }

    //审批经办人
    private func approversSection() -> CommonSectionModel? {
        if approvers.isEmpty {
            return nil
        }
        let approversItem = GroupSettingApproversItem(
            type: .approvers,
            cellIdentifier: GroupSettingApproversCell.lu.reuseIdentifier,
            style: .auto,
            approvers: approvers,
            onItemTapped: { [weak self] item in
                guard let vc = self?.controller else { return }
                let body = PersonCardBody(chatterId: item.id)
                self?.navigator.push(body: body, from: vc)
            },
            heightChange: { [weak self] in
                self?._reloadData.onNext(())
            })
        return CommonSectionModel(title: BundleI18n.LarkChatSetting.Lark_GroupLimit_AppearReviewBy_Subtitle, items: [approversItem])
    }

    func confirmSubmit(onFinish: @escaping ((Result<ServerPB.ServerPB_Misc_PutChatMemberSuppRoleApprovalResponse, Error>) -> Void)) {
        guard let chatId = Int64(chatID),
              let applyUpperLimit = applyUpperLimit,
              !isSubmiting else {
            return
        }
        isSubmiting = true
        var trackParams: [AnyHashable: Any] = [:]
        if let chat = self.chatModel {
            trackParams = IMTracker.Param.chat(chat)
        }
        trackParams += ["click": "submit",
                        "target": "none",
                        "member_toplimit": "\(applyUpperLimit)"]
        Tracker.post(TeaEvent("im_chat_member_toplimit_apply_click", params: trackParams))
        chatAPI.putChatMemberSuppRoleApproval(chatId: chatId,
                                              applyUpperLimit: applyUpperLimit,
                                              applyTypeKey: upperTypeModel?.seletedKey,
                                              description: applyDescription)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] value in
                self?.isSubmiting = false
                onFinish(.success(value))
            } onError: { [weak self] error in
                self?.isSubmiting = false
                Self.logger.error("ApplyForLimit trace putChatMemberSuppRoleApproval error, error = \(error)")
                onFinish(.failure(error))
            }.disposed(by: self.disposeBag)
    }
}
