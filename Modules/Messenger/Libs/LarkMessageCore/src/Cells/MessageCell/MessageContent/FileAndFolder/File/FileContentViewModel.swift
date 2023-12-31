//
//  FileContentViewModel.swift
//  LarkMessageCore
//
//  Created by liuwanlin on 2019/6/13.
//

import UIKit
import Foundation
import LarkModel
import LarkMessageBase
import LarkCore
import RxRelay
import RxSwift
import EENavigator
import LarkMessengerInterface
import UniverseDesignToast
import MobileCoreServices
import LarkContainer
import LarkAccountInterface
import LKCommonsLogging
import LarkSetting
import LarkSDKInterface
import RustPB
import LarkKASDKAssemble
import LarkAlertController

private let logger = Logger.log(NSObject(), category: "LarkMessageCore.cell.FileContentViewModel")

public class FileContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: FileAndFolderContentContext>: FileAndFolderBaseContentViewModel<M, D, C> {
    public override var identifier: String {
        return "file"
    }

    var content: FileContent? {
        guard self.dynamicAuthorityEnum.authorityAllowed else { return nil }
        return (self.message.content as? FileContent) ?? .transform(pb: RustPB.Basic_V1_Message())
    }

    override var key: String {
        return self.content?.key ?? ""
    }

    override var name: String {
        return ((self.message.content as? FileContent) ?? .transform(pb: RustPB.Basic_V1_Message())).name
    }

    override var sizeValue: Int64 {
        return content?.size ?? 0
    }

    override var lastEditInfo: (time: Int64, userName: String)? {
        guard let content = content,
              let user = content.fileLastUpdateUser,
              self.context.scene != .pin else { return nil }
        let chat = self.metaModel.getChat()
        let userName = getDisplayName(with: .fileLastEditInfo, chatId: chat.id, chatType: chat.type, chatterName: Chatter.transform(pb: user))
        return (time: content.fileLastUpdateTimeMs, userName: userName)
    }

    override var fileSource: Basic_V1_File.Source {
        return content?.fileSource ?? .unknown
    }

    public override var icon: UIImage {
        return LarkCoreUtils.fileLadderIcon(with: name)
    }

    // MARK: rate
    private var rateReplay: BehaviorRelay<Int64> = BehaviorRelay(value: -1)
    private var rateBag = DisposeBag()

    // MARK: progress
    private var _progressAnimated: Bool = false
    public override var progressAnimated: Bool {
        return _progressAnimated
    }
    private let progressReplay: BehaviorRelay<Float> = BehaviorRelay(value: -1)
    /// 进度专用DisposeBag
    private var progressBag = DisposeBag()

    public override func initialize() {
        super.initialize()
        self.observeProgress()
        self.observeRate()
        self.context.progressValue(key: key)
            .subscribe(onNext: { [weak self] (progress) in
                self?.progressReplay.accept(Float(progress.fractionCompleted))
            })
            .disposed(by: self.disposeBag)
        //监听速率变化
        self.context.rateValue(key: key).subscribe(onNext: { [weak self] (rate) in
            self?.rateReplay.accept(Int64(rate))
        })
        .disposed(by: self.disposeBag)
    }

    public override func update(metaModel: M, metaModelDependency: D?) {
        super.update(metaModel: metaModel, metaModelDependency: metaModelDependency)
        if message.localStatus == .fail || message.localStatus == .success {
            self.progressReplay.accept(-1)
            //成功/失败把速率值调为负数，用来判断是否显示
            self.rateReplay.accept(-1)
        }
    }

    public override func willDisplay() {
        super.willDisplay()
        self.observeProgress()
        self.observeRate()
        self._progressAnimated = true
    }

    public override func didEndDisplay() {
        super.didEndDisplay()
        self.progressBag = DisposeBag()
        self.rateBag = DisposeBag()
        self._progressAnimated = false
    }

    public override var progress: Float {
        return self.progressReplay.value
    }

    //rate
    public override var rate: Int64 {
        return self.rateReplay.value
    }
    //监听速率改变更新UI
    private func observeRate() {
        if self.message.localStatus == .success {
            return
        }
        self.rateBag = DisposeBag()
        self.rateReplay.asObservable()
            .subscribe(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                self.binderAbility?.syncToBinder()
                self.binderAbility?.updateComponent()
            })
            .disposed(by: self.rateBag)
    }

    private func observeProgress() {
        if self.message.localStatus == .success {
            return
        }
        self.progressBag = DisposeBag()
        self.progressReplay.asObservable()
            .subscribe(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                self.binderAbility?.syncToBinder()
                self.binderAbility?.updateComponent(animation: .none)
            })
            .disposed(by: self.progressBag)
    }

    public override var permissionPreview: (Bool, ValidateResult?) {
        return context.checkPermissionPreview(chat: metaModel.getChat(), message: metaModel.message)
    }
}

final class MergeForwardFileContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: FileAndFolderContentContext>: FileContentViewModel<M, D, C> {
    // https://meego.feishu.cn/larksuite/issue/detail/16198371
    // 合并转发如果来自消息链接化，那合并转发详情页的文件等也需要屏蔽这些入口，此处其实有一些特化，正常应该遵循FileAndFolderConfig的配置
    private var isFromMessageLink: Bool {
        return !(content?.authToken?.isEmpty ?? true)
    }

    override var useLocalChat: Bool {
        if isFromMessageLink {
            return true
        }
        return fileAndFolderConfig.useLocalChat
    }

    override var canViewInChat: Bool {
        return fileAndFolderConfig.canViewInChat && !isFromMessageLink
    }

    override var canForward: Bool {
        return fileAndFolderConfig.canForward && !isFromMessageLink
    }

    override var canSearch: Bool {
        return fileAndFolderConfig.canSearch && !isFromMessageLink
    }

    override var canSaveToDrive: Bool {
        return fileAndFolderConfig.canSaveToDrive && !isFromMessageLink
    }

    override var canOfficeClick: Bool {
        return fileAndFolderConfig.canOfficeClick && !isFromMessageLink
    }
}
