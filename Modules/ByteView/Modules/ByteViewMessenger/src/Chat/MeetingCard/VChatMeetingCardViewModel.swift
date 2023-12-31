//
//  VChatMeetingCardViewModel.swift
//  Action
//
//  Created by Prontera on 2019/6/4.
//

import Foundation
import LarkModel
import LarkMessageBase
import RxSwift
import RxCocoa
import LarkUIKit
import LarkSDKInterface
import AsyncComponent
import ByteViewInterface
import ByteViewCommon
import ByteViewNetwork
import ByteViewSetting
import LarkContainer

typealias VCMeetingSource = VChatMeetingCardContent.MeetingSource
typealias MeetingParicipant = VChatMeetingCardContent.MeetingParticipant

extension MeetingParicipant {
    var id: String {
        return userID
    }

    var participantId: ParticipantId {
        let bindInfo = BindInfo(id: bindID, type: .init(rawValue: bindType.rawValue) ?? .unknown)
        return ParticipantId(id: userID, type: .init(rawValue: userType.rawValue), deviceId: deviceID, bindInfo: bindInfo)
    }

    func isExternal(localDeviceId: String?, localTenanTag: Int?, localTenatId: String?) -> Bool {
        if localTenatId == nil || localTenanTag == nil { // 缺少数据，无法判断
            return false
        }

        if localTenanTag != 0 { // 大 B 用户才参与判断外部用户
            return false
        }

        if tenantID.isEmpty || tenantID == "-1" { // 旧数据或者没有查询到对应的租户信息
            return false
        }

        if isLarkGuest {
            return false
        }

        // 以下四种类型参与判断
        if userType == .larkUser || userType == .room || userType == .neoUser || userType == .neoGuestUser {
            if localDeviceId != deviceID && localTenatId != tenantID { // 非本地用户参与判断
                return true
            }
        }

        return false
    }
}

protocol VChatMeetingCardViewModelContext: UserViewModelContext {
    var scene: ContextScene { get }
}

enum MeetingCardStatus: Equatable {
    case unknown
    case joinable // 可加入
    case joined // 已加入
    case full // 已满员
    case end // 已结束
}

class VChatMeetingCardViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: VChatMeetingCardViewModelContext>: MessageSubViewModel<M, D, C> {
    let realVM: VChatMeetingCardViewModelImpl
    private let logger = Logger.meetingCard

    override func willDisplay() {
        super.willDisplay()
        self.realVM.isDisplaying.accept(true)
    }

    override func didEndDisplay() {
        super.didEndDisplay()
        self.realVM.isDisplaying.accept(false)
    }

    override func update(metaModel: M, metaModelDependency: D?) {
        logger.debug("update with updateTime:\(metaModel.message.updateTime)")
        super.update(metaModel: metaModel, metaModelDependency: metaModelDependency)
        if let content = metaModel.message.content as? VChatMeetingCardContent {
            self.realVM.updateContent(newContent: content)
        }
    }

    var contentPreferMaxWidth: CGFloat {
        let maxWidthLimit: CGFloat = 400
        return min(maxWidthLimit, metaModelDependency.getContentPreferMaxWidth(message))
    }

    var content: VChatMeetingCardContent? {
        return (self.message.content as? VChatMeetingCardContent)
    }

    override init(metaModel: M, metaModelDependency: D, context: C, binder: ComponentBinder<C>) {
        logger.debug("init with updateTime:\(metaModel.message.updateTime)")
        let chat = metaModel.getChat()
        let content = (metaModel.message.content as? VChatMeetingCardContent)!
        self.realVM = VChatMeetingCardViewModelImpl(context: context, content: content, isFromSecretChat: chat.isCrypto)
        super.init(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context, binder: binder)
        self.initRenderer(ASComponentRenderer(binder.component))

        self.realVM.delegate = self
        self.realVM.messageId = message.id
    }

    override var identifier: String {
        guard let content = content else { return "UnknownContent" }
        switch content.status {
        case .joinable, .full:
            return "VChatMeetingCardInActive"
        default:
            return "VChatMeetingCardActive"
        }
    }

    override var contentConfig: ContentConfig? {
        if message.parentMessage != nil || !message.reactions.isEmpty {
            var config = ContentConfig(hasMargin: false, backgroundStyle: .clear, maskToBounds: true, supportMutiSelect: true,
                                       hasBorder: true)
            config.isCard = true
            return config
        }
        return ContentConfig(hasMargin: false, backgroundStyle: .clear, maskToBounds: true, supportMutiSelect: true,
                             hasBorder: true)
    }
}

extension VChatMeetingCardViewModel: VChatMeetingCardViewModelImplDelegate {
    func needUpdate() {
        self.binder.update(with: self)
        self.update(component: binder.component, animation: .automatic)
    }
}

extension ParticipantService {
    func participantsByIdsUsingCache<U>(_ pids: [ParticipantId], meetingId: String,
                                        compactMap: @escaping (ParticipantId, ParticipantUserInfo) -> U?) -> Single<[U]> {
        RxTransform.single { completion in
            self.participantInfo(pids: pids, meetingId: meetingId) { aps in
                completion(.success(zip(pids, aps).compactMap(compactMap)))
            }
        }
    }
}
