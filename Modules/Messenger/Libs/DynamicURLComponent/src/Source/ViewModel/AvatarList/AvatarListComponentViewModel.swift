//
//  AvatarListComponentViewModel.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2021/8/23.
//

import UIKit
import Foundation
import RustPB
import RxSwift
import LarkUIKit
import EENavigator
import LarkBizAvatar
import LarkContainer
import LarkNavigator
import LKCommonsLogging
import LarkSDKInterface
import TangramComponent
import TangramUIComponent
import UniverseDesignToast
import LarkMessengerInterface

public final class AvatarListComponentViewModel: RenderComponentBaseViewModel {
    static let logger = Logger.log(AvatarListComponentViewModel.self, category: "DynamicURLComponent.AvatarListComponentViewModel")

    private lazy var _component: AvatarListComponent<EmptyContext> = .init(props: .init())
    public override var component: Component {
        return _component
    }
    private let disposeBag = DisposeBag()
    @ScopedInjectedLazy var chatterAPI: ChatterAPI?

    public override func buildComponent(stateID: String,
                                        componentID: String,
                                        component: Basic_V1_URLPreviewComponent,
                                        style: Basic_V1_URLPreviewComponent.Style,
                                        property: Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty?,
                                        renderStyle: RenderComponentStyle) {
        let chattersPreview = property?.chattersPreview ?? .init()
        let props = buildComponentProps(componentID: componentID, property: chattersPreview, style: style)
        _component = AvatarListComponent<EmptyContext>(props: props, style: renderStyle)
    }

    public override func buildComponentStyle(style: Basic_V1_URLPreviewComponent.Style) -> RenderComponentStyle {
        let renderStyle = super.buildComponentStyle(style: style)
        renderStyle.backgroundColor = UIColor.clear // backgroundColor由内部UILabel响应
        return renderStyle
    }

    private func buildComponentProps(componentID: String,
                                     property: Basic_V1_URLPreviewComponent.ChattersPreviewProperty,
                                     style: Basic_V1_URLPreviewComponent.Style) -> AvatarListComponentProps {
        let props = AvatarListComponentProps()
        let chatterInfos = property.chatterInfos.prefix(Int(property.maxShowCount))
        props.setAvatarTasks.setTask { [weak self] (completion) in
            guard let self = self else {
                completion([], nil)
                return
            }
            // 异步数据回来时，主动触发刷新
            let refreshTask: AsyncSerialEquatable.ValueCapturedResult = { [weak self] isCaptured in
                if isCaptured, let component = self?.component {
                    self?.ability.updatePreview(component: component)
                }
            }
            // 当包含空的avatarKey时，需要端上兜底拉取Chatter信息
            if chatterInfos.contains(where: { $0.avatarKey.isEmpty }) {
                let chatterIDs = chatterInfos.map({ $0.chatterID })
                self.chatterAPI?.getChatters(ids: chatterIDs)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { (chatters) in
                        let tasks = chatterIDs.compactMap { id -> UserAvatarListView.SetAvatarTask? in
                            if let chatter = chatters[id] {
                                let task: UserAvatarListView.SetAvatarTask = { avatarView in
                                    avatarView.setAvatarByIdentifier(chatter.id, avatarKey: chatter.avatarKey, scene: .Chat)
                                }
                                return task
                            }
                            Self.logger.error("match no chatter for \(id)")
                            return nil
                        }
                        completion(tasks, refreshTask)
                    })
                    .disposed(by: self.disposeBag)
            } else {
                let tasks = chatterInfos.map { chatter -> UserAvatarListView.SetAvatarTask in
                    let task: UserAvatarListView.SetAvatarTask = { avatarView in
                        avatarView.setAvatarByIdentifier(chatter.chatterID, avatarKey: chatter.avatarKey, scene: .Chat)
                    }
                    return task
                }
                // 此处为同步返回，不用再触发refresh
                completion(tasks, nil)
            }
        }

        props.restCount = Int(property.chattersCount) - chatterInfos.count
        if let textColor = style.tcTextColor {
            props.restTextColor = textColor
        }
        if let backgroundColor = style.tcBackgroundColor {
            props.restBackgroundColor = backgroundColor
        }
        if let font = style.tcFont {
            props.restTextFont.value = font
        }
        props.onTap.update { [weak self] in
            self?.openParticipantsPreview(componentID: componentID, property: property)
        }
        return props
    }

    private func openParticipantsPreview(componentID: String, property: Basic_V1_URLPreviewComponent.ChattersPreviewProperty) {
        guard let targetVC = dependency.targetVC else { return }
        let viewModel = AvatarListViewModel(previewID: self.entity.previewID, componentID: componentID, property: property, userResolver: userResolver)
        let vc = AvatarListViewController(viewModel: viewModel, navigator: userResolver.navigator)
        userResolver.navigator.present(vc, wrap: LkNavigationController.self, from: targetVC, prepare: { $0.modalPresentationStyle = .formSheet })
        URLTracker.trackRenderClick(entity: self.entity, extraParams: self.dependency.extraTrackParams, clickType: .avatar, componentID: componentID)
    }
}
