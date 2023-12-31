//
//  DriveImageFollowManager.swift
//  SKDrive
//
//  Created by ZhangYuanping on 2022/3/16.
//  

import RxSwift
import RxCocoa
import SKCommon
import SKFoundation
import SpaceInterface

class DriveImageFollowManager: FollowableContent {
    /// 负责处理 Follow 内容加载流程的事件
    weak var followAPIDelegate: DriveFollowAPIDelegate?
    /// 负责回调内容状态变化事件
    weak var followContentDelegate: FollowableContentDelegate?
    /// 同层 Follow 的文档挂载点
    var followMountToken: String?
    
    /// input: 图片是否加载完毕
    let imagePreviewReadyRelay = BehaviorRelay<Bool>(value: false)
    /// 当前图片的状态
    let imageStateRelay = BehaviorRelay<DriveImageFollowState>(value: DriveImageFollowState.default)
    
    /// 接收到的 Follow State
    private let imageFollowStateSubject = PublishSubject<DriveImageFollowState>()
    var imageFollowStateUpdated: Driver<DriveImageFollowState> {
        return imageFollowStateSubject.asDriver(onErrorJustReturn: DriveImageFollowState.default)
    }
    
    private let disposeBag = DisposeBag()
    
    func setup(follwDelegate: DriveFollowAPIDelegate, mountToken: String?) {
        self.followAPIDelegate = follwDelegate
        self.followMountToken = mountToken
        imagePreviewReadyRelay.subscribe(onNext: { [weak self] isReady in
            guard isReady else { return }
            self?.followAPIDelegate?.followDidReady()
            self?.registerFollowableContent()
        }).disposed(by: disposeBag)
    }
    
    func registerFollowableContent() {
        followAPIDelegate?.register(followContent: self)
    }
    
    // MARK: - FollowableContent
    
    var moduleName: String {
        return DriveImageFollowState.module
    }
    
    func onSetup(delegate: FollowableContentDelegate) {
        self.followContentDelegate = delegate
        imageStateRelay.subscribe(onNext: { [weak self] imageState in
            guard let self = self else { return }
            self.followContentDelegate?.onContentEvent(.stateChanged(imageState.followModuleState),
                                                       at: self.followMountToken)
        }).disposed(by: disposeBag)
    }
    
    func setState(_ state: FollowModuleState) {
        // 图片过滤掉同层 Follow 的事件（DoxBoxPreview）
        guard state.module != FollowModule.docxBoxPreview.rawValue else { return }
        guard let imageState = DriveImageFollowState(followModuleState: state) else {
            DocsLogger.error("drive.image.follow --- failed to convert to image state", extraInfo: ["moduleState": state])
            return
        }
        imageFollowStateSubject.onNext(imageState)
    }
    
    func getState() -> FollowModuleState? {
        return imageStateRelay.value.followModuleState
    }
    
    func updatePresenterState(_ state: FollowModuleState?) {}
}
