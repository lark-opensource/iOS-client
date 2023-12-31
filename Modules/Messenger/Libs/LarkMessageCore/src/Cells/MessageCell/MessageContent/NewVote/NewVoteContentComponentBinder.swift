//
//  NewVoteContentComponentBinder.swift
//  LarkMessageCore
//
//  Created by bytedance on 2022/4/10.
//

import Foundation
import AsyncComponent
import EEFlexiable
import LarkMessageBase
import UniverseDesignColor
import UIKit

struct NewVoteContentConfig {
    public static var contentMaxWidth: CGFloat = 400
    public static var contentMaxHeight: CGFloat = 800
}

final class NewVoteContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: NewVoteContentViewModelContext>: ComponentBinder<C> {
    private let style = ASComponentStyle()
    private let props = NewVoteContentComponent<C>.Props()
    private var _component: NewVoteContainerComponent<C> = .init(props: .init(), style: .init(), context: nil)

    public override var component: NewVoteContainerComponent<C> {
        return _component
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        props.key = key ?? "NewVoteContent"
        style.backgroundColor = UIColor.ud.bgFloat
        _component = NewVoteContainerComponent<C>(props: props, style: style, context: context)
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? NewVoteContentViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        vm.updateVoteInfo()
        props.voteViewProps.isClose = vm.voteClose
        props.voteViewProps.isVoted = vm.isVoted
        props.voteViewProps.voteTitle = vm.title
        props.voteViewProps.voteTagInfos = vm.voteTagInfos
        props.voteViewProps.voteResultText = vm.voteResultText
        props.voteViewProps.voteCellPropsList = vm.contentCellProps
        if (vm.isVoted || vm.voteClose) && vm.isSponsor {
            props.voteViewProps.leftButtonTitle = vm.resendButtonTitle
            props.voteViewProps.leftButtonEnabled = vm.resendButtonEnabled
            props.voteViewProps.leftButtonClickEvent = { [weak vm] in
                vm?.resendAction()
            }
            props.voteViewProps.rightButtonTitle = vm.closeButtonTitle
            props.voteViewProps.rightButtonEnabled = vm.closeButtonEnabled
            props.voteViewProps.rightButtonClickEvent = { [weak vm] in
                vm?.closeAction()
            }
        } else {
            props.voteViewProps.leftButtonTitle = vm.voteButtonTitle
            props.voteViewProps.leftButtonEnabled = vm.voteButtonEnabled
            props.voteViewProps.leftButtonClickEvent = { [weak vm] in
                vm?.sendAction()
            }
        }
        if !vm.showResult {
            props.voteViewProps.cellDidClickEvent = { [weak vm] index in
                vm?.onItemDidSelect(identifier: index)
            }
        }
        props.voteViewProps.showMoreButtonTitle = vm.showMoreButtonTitle
        props.flodEnable = vm.flodEnable
        props.voteViewProps.showMoreButtonClickEvent = { [weak vm] in
            vm?.showMoreAction()
        }
        props.contentPreferMaxWidth = min(NewVoteContentConfig.contentMaxWidth, vm.contentPreferMaxWidth)
        props.contentPreferMaxHeight = min(NewVoteContentConfig.contentMaxHeight, vm.contentPreferMaxHeight)
        props.voteViewProps.width = props.contentPreferMaxWidth
        props.voteViewProps.maxHeight = props.contentPreferMaxHeight
        _component.props = props
        vm.update(component: _component)
    }
}

final class MessageDetailNewVoteContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: NewVoteContentViewModelContext>: ComponentBinder<C> {
    private let style = ASComponentStyle()
    private let props = NewVoteContentComponent<C>.Props()
    private lazy var _component: NewVoteContainerComponent<C> = .init(props: .init(), style: .init(), context: nil)

    public override var component: NewVoteContainerComponent<C> {
        return _component
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        props.key = key ?? "NewVoteContent"
        style.cornerRadius = 10
        style.border = Border(BorderEdge(width: 1, color: UDMessageColorTheme.imMessageCardBorder, style: .solid))
        style.boxSizing = .borderBox
        style.backgroundColor = UIColor.ud.bgFloat
        _component = NewVoteContainerComponent<C>(props: props, style: style, context: context)
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? NewVoteContentViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        vm.updateVoteInfo()
        props.voteViewProps.isClose = vm.voteClose
        props.voteViewProps.isVoted = vm.isVoted
        props.voteViewProps.voteTitle = vm.title
        props.voteViewProps.voteTagInfos = vm.voteTagInfos
        props.voteViewProps.voteResultText = vm.voteResultText
        props.voteViewProps.voteCellPropsList = vm.contentCellProps
        if (vm.isVoted || vm.voteClose) && vm.isSponsor {
            props.voteViewProps.leftButtonTitle = vm.resendButtonTitle
            props.voteViewProps.leftButtonEnabled = vm.resendButtonEnabled
            props.voteViewProps.leftButtonClickEvent = { [weak vm] in
                vm?.resendAction()
            }
            props.voteViewProps.rightButtonTitle = vm.closeButtonTitle
            props.voteViewProps.rightButtonEnabled = vm.closeButtonEnabled
            props.voteViewProps.rightButtonClickEvent = { [weak vm] in
                vm?.closeAction()
            }
        } else {
            props.voteViewProps.leftButtonTitle = vm.voteButtonTitle
            props.voteViewProps.leftButtonEnabled = vm.voteButtonEnabled
            props.voteViewProps.leftButtonClickEvent = { [weak vm] in
                vm?.sendAction()
            }
        }
        if !vm.showResult {
            props.voteViewProps.cellDidClickEvent = { [weak vm] index in
                vm?.onItemDidSelect(identifier: index)
            }
        }
        props.flodEnable = false
        props.contentPreferMaxWidth = min(NewVoteContentConfig.contentMaxWidth, vm.contentPreferMaxWidth)
        props.contentPreferMaxHeight = min(NewVoteContentConfig.contentMaxHeight, vm.contentPreferMaxHeight)
        props.voteViewProps.width = props.contentPreferMaxWidth
        _component.props = props
        vm.update(component: _component)
    }
}

final class MergeForwardNewVoteContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: NewVoteContentViewModelContext>: ComponentBinder<C> {
    private let style = ASComponentStyle()
    private let props = NewVoteContentMergeForwardComponent<C>.Props()
    private lazy var _component: NewVoteContentMergeForwardComponent<C> = .init(props: .init(), style: .init(), context: nil)

    public override var component: NewVoteContentMergeForwardComponent<C> {
        return _component
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        _component = NewVoteContentMergeForwardComponent<C>(props: props, style: style, context: context)
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? MergeForwardNewVoteContentViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        props.title = vm.downGradeText
        _component.props = props
    }
}

final class PinNewVoteContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: NewVoteContentViewModelContext>: ComponentBinder<C> {
    private let style = ASComponentStyle()
    private let props = NewVoteContentPinComponent<C>.Props()
    private lazy var _component: NewVoteContentPinComponent<C> = .init(props: .init(), style: .init(), context: nil)

    public override var component: NewVoteContentPinComponent<C> {
        return _component
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        style.backgroundColor = UIColor.ud.bgFloat
        _component = NewVoteContentPinComponent<C>(props: props, style: style, context: context)
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? PinNewVoteContentViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        props.contentPreferMaxWidth = min(NewVoteContentConfig.contentMaxWidth, vm.contentPreferMaxWidth)
        props.title = vm.title
        props.content = vm.pinVoteContent
        props.setIcon = { [weak vm] view in
            view.image = vm?.pinVoteIcon
        }
        _component.props = props
    }
}
