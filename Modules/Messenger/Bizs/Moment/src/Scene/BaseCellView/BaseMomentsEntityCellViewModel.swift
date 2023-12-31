//
//  MomentFeedListCellViewModel.swift
//  Moment
//
//  Created by zc09v on 2021/1/5.
//
import LarkMessageBase
import Foundation
import AsyncComponent
import RxSwift

public enum MomentsEntitySubType: CaseIterable {
    // 消息内容
    case content
    //热评
    case hotComments
    // 普通评论
    case normalComments
    // 帖子评论（评论外露需求后 热评和普通评论 改用同一个type和ViewModel）
    case postComments
    //帖子状态
    case postStatus
    // 点赞等表情
    case reaction
    // 局部不支持组件
    case partUnsupport
    //评论状态
    case commentStatus
}

class BaseMomentsEntityCellViewModel<M: HasId, C: BaseMomentContextInterface>: BaseMomentCellViewModel<C> {
    var entity: M

    public var content: BaseMomentSubCellViewModel<M, C>! {
        didSet {
            self.resetContent(with: content, old: oldValue)
        }
    }

    open private(set) var subvms: [MomentsEntitySubType: BaseMomentSubCellViewModel<M, C>]

    public init(
        entity: M,
        content: BaseMomentSubCellViewModel<M, C>,
        subvms: [MomentsEntitySubType: BaseMomentSubCellViewModel<M, C>],
        context: C,
        binder: ComponentBinder<C>
    ) {
        self.entity = entity
        self.content = content
        self.subvms = subvms
        super.init(context: context, binder: binder)
        self.resetContent(with: content, old: nil)
        self.subvms.values.forEach { (vm) in
            self.addChild(vm)
            vm.initRenderer(renderer)
        }
    }

    func update(entity: M) {
        self.entity = entity
        for (_, subvm) in self.subvms where subvm.shouldUpdate(entity) {
            subvm.update(entity: entity)
        }
    }

    private func resetContent(with new: BaseMomentSubCellViewModel<M, C>, old: BaseMomentSubCellViewModel<M, C>?) {
        old?.removeFromParent()
        self.addChild(new)
        new.initRenderer(renderer)
    }
}
