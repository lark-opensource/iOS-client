//
//  CryptoChatFileContentViewModel.swift
//  LarkMessageCore
//
//  Created by zc09v on 2022/1/24.
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

private let logger = Logger.log(NSObject(), category: "LarkMessageCore.cell.FileContentViewModel")

public final class CryptoChatFileContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: FileAndFolderContentContext>: FileAndFolderBaseContentViewModel<M, D, C> {
    public override var identifier: String {
        return "file"
    }

    private var content: FileContent {
        return (self.message.content as? FileContent) ?? .transform(pb: RustPB.Basic_V1_Message())
    }

    override var key: String {
        return content.key
    }

    override var name: String {
        return content.name
    }

    override var sizeValue: Int64 {
        return content.size
    }

    override var lastEditInfo: (time: Int64, userName: String)? {
        return nil
    }

    override var fileSource: Basic_V1_File.Source {
        return content.fileSource
    }

    public override var icon: UIImage {
        return LarkCoreUtils.fileLadderIcon(with: name)
    }

    // MARK: progress
    private var _progressAnimated: Bool = false
    public override var progressAnimated: Bool {
        return _progressAnimated
    }
    private let progressReplay: BehaviorRelay<Float> = BehaviorRelay(value: -1)
    /// 进度专用DisposeBag
    private var progressBag = DisposeBag()

    public override func initialize() {
        self.observeProgress()

        self.context.progressValue(key: key)
            .subscribe(onNext: { [weak self] (progress) in
                self?.progressReplay.accept(Float(progress.fractionCompleted))
            })
            .disposed(by: self.disposeBag)
    }

    public override func update(metaModel: M, metaModelDependency: D?) {
        super.update(metaModel: metaModel, metaModelDependency: metaModelDependency)
        if message.localStatus == .fail || message.localStatus == .success {
            self.progressReplay.accept(-1)
        }
    }

    public override func willDisplay() {
        super.willDisplay()
        self.observeProgress()
        self._progressAnimated = true
    }

    public override func didEndDisplay() {
        super.didEndDisplay()
        self.progressBag = DisposeBag()
        self._progressAnimated = false
    }

    public override var progress: Float {
        return self.progressReplay.value
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
}
