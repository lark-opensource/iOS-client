//
//  VideoContentComponentBinder.swift
//  LarkMessageCore
//
//  Created by liuwanlin on 2019/5/30.
//

import UIKit
import Foundation
import EEFlexiable
import AsyncComponent
import LarkMessageBase

class BaseVideoContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: VideoContentContext>: NewComponentBinder<M, D, C> {
    let videoViewModel: VideoContentViewModel<M, D, C>?
    let videoActionHandler: VideoContentActionHandler<C>?

    public init(
        key: String? = nil,
        context: C? = nil,
        videoViewModel: VideoContentViewModel<M, D, C>?,
        videoActionHandler: VideoContentActionHandler<C>?
    ) {
        self.videoViewModel = videoViewModel
        self.videoActionHandler = videoActionHandler
        super.init(key: key, context: context, viewModel: videoViewModel, actionHandler: videoActionHandler)
    }
}

final class VideoContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: VideoContentContext>: BaseVideoContentComponentBinder<M, D, C> {
    private let videoviewStyle = ASComponentStyle()
    private let videoviewProps = VideoImageViewWrapperComponent<C>.Props()

    private lazy var _component: VideoImageViewWrapperComponent<C> = .init(props: .init(), style: .init(), context: nil)

    public override var component: ComponentWithContext<C> {
        return _component
    }

    public override func syncToBinder(key: String?) {
        guard let vm = self.videoViewModel else {
            assertionFailure()
            return
        }
        videoviewProps.originSize = vm.originSize
        videoviewProps.contentPreferMaxWidth = vm.contentPreferMaxWidth
        videoviewProps.duration = vm.duration
        videoviewProps.previewImageInfo = vm.previewImageInfo
        videoviewProps.status = vm.status
        videoviewProps.uploadProgress = vm.uploadProgress
        videoviewProps.permissionPreview = vm.permissionPreview
        videoviewProps.dynamicAuthorityEnum = vm.dynamicAuthorityEnum
        videoviewProps.message = vm.message
        videoviewProps.fetchKeyWithCryptoFG = vm.fetchKeyWithCryptoFG
        videoviewProps.tapAction = { [weak self] view, _ in
            guard let self = self, let vm = self.videoViewModel else { return }
            self.videoActionHandler?.videoTapped(
                view,
                permissionPreview: vm.permissionPreview,
                dynamicAuthorityEnum: vm.dynamicAuthorityEnum,
                status: vm.status,
                allMessages: vm.allMessages,
                chat: vm.metaModel.getChat(),
                message: vm.message,
                content: vm.content,
                updateStatus: { [weak self] status in
                    self?.videoViewModel?.setStatus(status: status)
                },
                canViewInChat: vm.canViewInChat,
                showSaveToCloud: vm.showSaveToCloud
            )
        }
        _component.props = videoviewProps

        if vm.shouldAddBorder {
            _component.style.border = Border(BorderEdge(width: 1, color: UIColor.ud.N300, style: .solid))
            _component.style.cornerRadius = 8
        } else {
            _component.style.border = nil
            _component.style.cornerRadius = 0
        }
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        videoviewProps.key = key ?? "VideoContent"
        self._component = VideoImageViewWrapperComponent<C>(props: videoviewProps, style: videoviewStyle)
    }
}

final class ThreadVideoContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: VideoContentContext>: BaseVideoContentComponentBinder<M, D, C> {
    private let videoviewStyle: ASComponentStyle = {
        let style = ASComponentStyle()
        style.border = Border(BorderEdge(width: 1.0 / UIScreen.main.scale, color: UIColor.ud.N400, style: .solid))
        style.cornerRadius = 4
        return style
    }()

    private let videoviewProps = VideoImageViewWrapperComponent<C>.Props()

    private lazy var _component: VideoImageViewWrapperComponent<C> = .init(props: .init(), style: .init(), context: nil)

    public override var component: ComponentWithContext<C> {
        return _component
    }

    public override func syncToBinder(key: String?) {
        guard let vm = self.videoViewModel else {
            assertionFailure()
            return
        }
        videoviewProps.originSize = vm.originSize
        videoviewProps.contentPreferMaxWidth = vm.contentPreferMaxWidth
        videoviewProps.duration = vm.duration
        videoviewProps.previewImageInfo = vm.previewImageInfo
        videoviewProps.status = vm.status
        videoviewProps.uploadProgress = vm.uploadProgress
        videoviewProps.permissionPreview = vm.permissionPreview
        videoviewProps.dynamicAuthorityEnum = vm.dynamicAuthorityEnum
        videoviewProps.message = vm.message
        videoviewProps.fetchKeyWithCryptoFG = vm.fetchKeyWithCryptoFG
        videoviewProps.tapAction = { [weak self] view, _ in
            guard let self = self, let vm = self.videoViewModel else { return }
            self.videoActionHandler?.videoTapped(
                view,
                permissionPreview: vm.permissionPreview,
                dynamicAuthorityEnum: vm.dynamicAuthorityEnum,
                status: vm.status,
                allMessages: vm.allMessages,
                chat: vm.metaModel.getChat(),
                message: vm.message,
                content: vm.content,
                updateStatus: { [weak self] status in
                    self?.videoViewModel?.setStatus(status: status)
                },
                canViewInChat: vm.canViewInChat,
                showSaveToCloud: vm.showSaveToCloud
            )
        }
        _component.props = videoviewProps
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        videoviewProps.key = key ?? "VideoContent"
        self._component = VideoImageViewWrapperComponent<C>(props: videoviewProps, style: videoviewStyle)
    }
}

final class MessageDetailVideoContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: VideoContentContext>: BaseVideoContentComponentBinder<M, D, C> {
    private let videoviewStyle = ASComponentStyle()
    private let videoviewProps = VideoImageViewWrapperComponent<C>.Props()

    private lazy var _component: VideoImageViewWrapperComponent<C> = .init(props: .init(), style: .init(), context: nil)

    public override var component: ComponentWithContext<C> {
        return _component
    }

    public override func syncToBinder(key: String?) {
        guard let vm = self.videoViewModel else {
            assertionFailure()
            return
        }
        videoviewProps.originSize = vm.originSize
        videoviewProps.contentPreferMaxWidth = vm.contentPreferMaxWidth
        videoviewProps.duration = vm.duration
        videoviewProps.previewImageInfo = vm.previewImageInfo
        videoviewProps.status = vm.status
        videoviewProps.uploadProgress = vm.uploadProgress
        videoviewProps.permissionPreview = vm.permissionPreview
        videoviewProps.dynamicAuthorityEnum = vm.dynamicAuthorityEnum
        videoviewProps.message = vm.message
        videoviewProps.fetchKeyWithCryptoFG = vm.fetchKeyWithCryptoFG
        videoviewProps.tapAction = { [weak self] view, _ in
            guard let self = self, let vm = self.videoViewModel else { return }
            self.videoActionHandler?.videoTapped(
                view,
                permissionPreview: vm.permissionPreview,
                dynamicAuthorityEnum: vm.dynamicAuthorityEnum,
                status: vm.status,
                allMessages: vm.allMessages,
                chat: vm.metaModel.getChat(),
                message: vm.message,
                content: vm.content,
                updateStatus: { [weak self] status in
                    self?.videoViewModel?.setStatus(status: status)
                },
                canViewInChat: vm.canViewInChat,
                showSaveToCloud: vm.showSaveToCloud
            )
        }
        _component.props = videoviewProps
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        videoviewProps.key = key ?? "VideoContent"
        videoviewStyle.cornerRadius = 4
        videoviewStyle.border = Border(BorderEdge(width: 1, color: UIColor.ud.N300, style: .solid))
        self._component = VideoImageViewWrapperComponent<C>(props: videoviewProps, style: videoviewStyle)
    }
}

final class PinVideoContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: VideoContentContext>: BaseVideoContentComponentBinder<M, D, C> {
    private let videoviewStyle = ASComponentStyle()
    private let videoviewProps = VideoImageViewWrapperComponent<C>.Props()

    private lazy var _component: VideoImageViewWrapperComponent<C> = .init(props: .init(), style: .init(), context: nil)

    public override var component: ComponentWithContext<C> {
        return _component
    }

    public override func syncToBinder(key: String?) {
        guard let vm = self.videoViewModel else {
            assertionFailure()
            return
        }
        videoviewProps.originSize = vm.originSize
        videoviewProps.contentPreferMaxWidth = vm.contentPreferMaxWidth
        videoviewProps.duration = vm.duration
        videoviewProps.previewImageInfo = vm.previewImageInfo
        videoviewProps.status = vm.status
        videoviewProps.uploadProgress = vm.uploadProgress
        videoviewProps.permissionPreview = vm.permissionPreview
        videoviewProps.dynamicAuthorityEnum = vm.dynamicAuthorityEnum
        videoviewProps.message = vm.message
        videoviewProps.fetchKeyWithCryptoFG = vm.fetchKeyWithCryptoFG
        videoviewProps.tapAction = { [weak self] view, _ in
            guard let self = self, let vm = self.videoViewModel else { return }
            self.videoActionHandler?.videoTapped(
                view,
                permissionPreview: vm.permissionPreview,
                dynamicAuthorityEnum: vm.dynamicAuthorityEnum,
                status: vm.status,
                allMessages: vm.allMessages,
                chat: vm.metaModel.getChat(),
                message: vm.message,
                content: vm.content,
                updateStatus: { [weak self] status in
                    self?.videoViewModel?.setStatus(status: status)
                },
                canViewInChat: vm.canViewInChat,
                showSaveToCloud: vm.showSaveToCloud
            )
        }
        _component.props = videoviewProps
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        self._component = VideoImageViewWrapperComponent<C>(props: videoviewProps, style: videoviewStyle)
    }
}
