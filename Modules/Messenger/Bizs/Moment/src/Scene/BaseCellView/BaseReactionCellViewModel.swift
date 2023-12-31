//
//  BaseReactionCellViewModel.swift
//  Moment
//
//  Created by bytedance on 2021/1/27.
//

import UIKit
import Foundation
import LarkMessageBase
import LarkModel
import LarkFoundation
import LarkCore
import LarkMessageCore
import LarkAccountInterface
import LarkContainer
import LarkMessengerInterface
import LarkUIKit
import LarkSDKInterface
import EENavigator
import EEFlexiable
import AsyncComponent
import RxSwift
import UniverseDesignToast
import LarkFeatureGating
import LarkSetting

protocol ReactionListEntitiesProtocol: HasId {
    var type: RawData.EntityType { get }
    var postId: String { get }
    var circleId: String { get }
    var reactionListEntities: [RawData.ReactionListEntity] { get }
    var reactions: [RawData.ReactionList] { get }
    var originalReactionSet: RawData.ReactionSet { get }
}
/// 公司圈的新reaction样式
/// 服务端会保证返回的reaction的数量大于端上最大的5个
/// 1. 如果全是实名，走原有的逻辑
/// 2. 如果全是匿名，走仅展示匿名数量的样式
/// 3. 如果匿名&花名的样式都有，花名展示出来，匿名展示+x的逻辑
///    3.1 如果花名够5个 跟原来的逻辑一样
///    3.2 如果花名不够5个，展示比如： 3+x等人点赞的逻辑
class BaseReactionCellViewModel <T: ReactionListEntitiesProtocol>: BaseMomentSubCellViewModel<T, BaseMomentContext>, ReactionViewDelegate, UserResolverWrapper {

    let userResolver: UserResolver
    override var identifier: String {
        return "moments_reaction"
    }

    @ScopedInjectedLazy private var postAPI: PostApiService?
    @ScopedInjectedLazy private var createReactionService: UserCreateReactionService?
    @ScopedInjectedLazy private var momentsAccountService: MomentsAccountService?
    var canReaction = true

    lazy var newProfileFG = {
        (try? userResolver.resolve(assert: FeatureGatingService.self))?.staticFeatureGatingValue(with: "moments.profile.new") ?? false
    }()

    let disposeBag = DisposeBag()

    var preferMaxLayoutWidth: CGFloat {
        return 0
    }

    /// 这里需要转换一下模型
    var reactions: [Reaction] {
        if entity.reactionListEntities.isEmpty {
            return []
        }
        return convertReactionListEntities(entity.reactionListEntities)
    }

    init(userResolver: UserResolver, entity: T, context: BaseMomentContext, binder: ComponentBinder<BaseMomentContext>) {
        self.userResolver = userResolver
        super.init(entity: entity, context: context, binder: binder)
    }

    func convertReactionListEntities(_ entities: [RawData.ReactionListEntity]) -> [Reaction] {
        return entities.map { (reactionsEntity) -> Reaction in
            let reaction = Reaction(type: reactionsEntity.reactionList.type, chatterIds: reactionsEntity.reactionList.firstPageUserIds, chatterCount: 0)
            reaction.chatters = reactionsEntity.firstPageUsers.map({ user in
                let chatter = Chatter.transform(pb: Chatter.PBModel())
                chatter.id = user.userID
                chatter.name = user.displayName
                return chatter
            })
            return reaction
        }
    }

    /// 如果都是匿名的话 才仅仅展示数量
    func justShowCountFor(reaction: Reaction) -> Bool {
        guard newProfileFG else {
            return reactionForAnonymous()
        }
        let count = 0
        if let item = self.entity.reactionListEntities.first { (entity) -> Bool in
            return entity.reactionList.type == reaction.type
        } {
            return (item.reactionList.count > count) && item.firstPageUsers.isEmpty
        }
        return false
    }

    func reactionAbsenceCount(_ reaction: Reaction) -> Int? {
        let item = self.entity.reactionListEntities.first { (entity) -> Bool in
            return entity.reactionList.type == reaction.type && entity.reactionList.count > entity.firstPageUsers.count
        }
        if let item = item {
            return Int(item.reactionList.count) - item.firstPageUsers.count
        }
        return nil
    }

    func maxReactionDisplayCount(_ reaction: Reaction) -> Int {
        return 5
    }

    func forceShowMoreAbsenceCount(reaction: Reaction) -> Bool {
        /// 如果FG关闭的话 此功能
        guard newProfileFG else {
            return false
        }
        /// 只是有匿名和和花名混合的时候 才会需要 forceShowMoreAbsenceCount
        if !self.reactionForAnonymous() {
            return false
        }
        if let item = self.entity.reactionListEntities.first { (entity) -> Bool in
            return entity.reactionList.type == reaction.type
        } {
            /// 这里为什么要 forceShowMore呢？
            /// 1. 业务需求 比如 2个花名 + 1个匿名，这个时候需要展示 aaa, bbb +... 1
            /// 2. 这个时候是触发不了最大的数量的 所以我们需要处理一下这个case
            /// 怎么判断是匿名和花名的场景，1. 匿名不会返回userId 2.服务端会保证返回的firstPageUsers 大于5
            /// 正常情况下 只有 firstPageUsers> 5时候， firstPageUsers ！= reactionList.count
            /// 故当 firstPageUsers 小于 5时候，说明当前reaction较少，如果还小于 reactionList.count 说明没有完全返回，有匿名
            if item.firstPageUsers.count <= 5 && item.firstPageUsers.count < item.reactionList.count {
                return true
            } else {
                return false
            }
        }
        return false
    }
    /// reaction的点击事件
    /// - Parameters:
    ///   - reaction: 点击的reaction
    ///   - tapType: 点击的类型
    func reactionDidTapped(_ reaction: Reaction, tapType: ReactionActionType) {
        switch tapType {
        case .icon:
            doReaction(type: reaction.type)
        case .name(let userID):
            if self.newProfileFG {
                if let item = entity.reactionListEntities.first { $0.reactionList.type == reaction.type }, let user = item.firstPageUsers.first { $0.userID == userID } {
                    jumpToProfileWithUser(user)
                }
            } else {
                guard let targetVC = self.context.pageAPI else { return }
                MomentsNavigator.pushUserAvatarWith(userResolver: self.userResolver,
                                                    userID: userID,
                                                    from: targetVC,
                                                    source: .reaction,
                                                    trackInfo: nil)
            }
        case .more:
            jumpToReactionListWithType(reaction.type)
        }
    }
    /// 扩充reactionTag的icon点击区域
    func reactionTagIconActionAreaEdgeInsets() -> UIEdgeInsets? {
        return UIEdgeInsets(top: 2, left: 5, bottom: 2, right: 3)
    }

    /// 跳转profile页
    /// - Parameter userID: userID
    func jumpToProfileWithUser(_ user: MomentUser) {
        guard let targetVC = self.context.pageAPI else { return }
        MomentsNavigator.pushAvatarWith(userResolver: userResolver,
                                        user: user,
                                        from: targetVC,
                                        source: .reaction,
                                        trackInfo: nil)
    }

    /// 跳转Reaction列表
    /// - Parameter type: reaction的类型
    func jumpToReactionListWithType(_ type: String) {
        guard let pageAPI = self.context.pageAPI else {
            return
        }
        let generator
        = ReactionDetailViewControllerGenerator(userResolver: userResolver,
                                                id: self.entity.id,
                                                reactionType: type,
                                                reactions: self.entity.reactions)
        let detailVC = generator.generator()
        userResolver.navigator.present(detailVC,
                                 wrap: LkNavigationController.self,
                                 from: pageAPI,
                                 prepare: { (controller) in
                                    controller.modalPresentationStyle = .overCurrentContext
                                    controller.modalTransitionStyle = .crossDissolve
                                    controller.view.backgroundColor = UIColor.clear
                                 },
                                 animated: false)
    }

    func doReaction(type: String) {
        if !canReaction {
            if let view = context.pageAPI?.view {
                UDToast.showTips(with: BundleI18n.Moment.Lark_Moments_ReactionsTurnedOff, on: view)
            }
            return
        }
        let action: Bool
        if self.entity.reactions.contains(where: { (reactionInfo) -> Bool in
            return reactionInfo.type == type && reactionInfo.selfInvolved
        }) {
            self.postAPI?
                .deleteReaction(byID: self.entity.id,
                                entityType: self.entity.type,
                                reactionType: type,
                                originalReactionSet: self.entity.originalReactionSet,
                                categoryIds: self.getCategoryIds(),
                                isAnonymous: self.reactionForAnonymous())
                .subscribe(onError: { [weak self] error in
                    self?.momentsAccountService?.handleOfficialAccountErrorIfNeed(error: error, from: self?.context.pageAPI)
                })
                .disposed(by: self.disposeBag)
            action = false
        } else {
            self.createReactionService?.createReaction(byID: self.entity.id,
                                                       entityType: self.entity.type,
                                                       reactionType: type,
                                                       originalReactionSet: self.entity.originalReactionSet,
                                                       categoryIds: self.getCategoryIds(),
                                                       isAnonymous: self.reactionForAnonymous(),
                                                       fromVC: self.context.pageAPI)
            action = true
        }
        doReactionWithAction(action)
    }

    func doReactionWithAction(_ action: Bool) {

    }

    func getCategoryIds() -> [String] {
        return []
    }

    func reactionForAnonymous() -> Bool {
        assertionFailure("must override")
        return false
    }
}

final class MomentsReactionCellViewModelBinder<T: ReactionListEntitiesProtocol, C: BaseMomentContext>: ComponentBinder<C> {

    private let postReactionComponentKey: String = "post_reaction_component"
    private lazy var _component: ASLayoutComponent<C> = .init(key: "", style: .init(), context: nil, [])
    public override var component: ComponentWithContext<C> {
        return _component
    }

    lazy var reactionComponentProp: ReactionViewComponent<C>.Props = {
        return ReactionViewComponent<C>.Props()
    }()

    lazy var reactionComponent: ReactionViewComponent<C> = {
        let style = ASComponentStyle()
        style.marginLeft = -3
        style.marginBottom = -3
        return ReactionViewComponent(props: self.reactionComponentProp, style: style)
    }()

    lazy var containerComponent: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        return ASLayoutComponent(style: style, [reactionComponent])
    }()

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? BaseReactionCellViewModel<T> else {
            assertionFailure()
            return
        }
        let reactions = vm.reactions
        if !reactions.isEmpty {
            self._component.style.display = .flex
            self.reactionComponentProp.reactions = vm.reactions
            self.reactionComponentProp.delegate = vm
            self.reactionComponentProp.getChatterDisplayName = { chatter in
                return chatter.name
            }
            self.reactionComponent.props = self.reactionComponentProp
        } else {
            self._component.style.display = .none
        }

    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        let style = ASComponentStyle()
        self._component = ASLayoutComponent<C>(
            key: key ?? postReactionComponentKey,
            style: style,
            context: context,
            [containerComponent]
        )
    }

}
