//
//  DrivePDFViewModel+Follow.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2020/4/9.
//  

import Foundation
import RxSwift
import RxCocoa
import SKCommon
import SKFoundation
import SpaceInterface
import LarkDocsIcon

extension DrivePDFViewModel {
    func setup(followDelegate: DriveFollowAPIDelegate, mountToken: String?) {
        DocsLogger.driveInfo("drive.pdf.follow --- setting up follow delegate")
        followAPIDelegate = followDelegate
        followMountToken = mountToken
        uiReadyRelay
            .subscribe(onNext: { [weak self] isReady in
                guard isReady else { return }
                guard let self = self else { return }
                guard let delegate = self.followAPIDelegate else { return }
                DocsLogger.driveInfo("drive.pdf.follow --- registing pdf module as followable content")
                self.setToPresentationModeIfNeed()
                delegate.register(followContent: self)
                delegate.followDidReady()
                delegate.followDidRenderFinish()
            })
            .disposed(by: disposeBag)
    }

    func intercept(url: URL) -> Bool {
        guard let followAPIDelegate = followAPIDelegate else {
            return false
        }
        DocsLogger.driveInfo("drive.pdf.follow --- redirect url to vc follow delegate")
        followAPIDelegate.handle(operation: .vcOperation(value: .openUrl(url: url.absoluteString)))
        return true
    }
    
    func registerFollowableContent() {
        followAPIDelegate?.register(followContent: self)
    }
    
    func unregisterFollowableContent() {
        followStateDisposeBag = DisposeBag()
        followContentDelegate = nil
        followAPIDelegate?.unregister(followContent: self)
        followAPIDelegate = nil
    }
    
    private func setToPresentationModeIfNeed() {
        // VCFollow 下，共享纯 Drive 文件，且是主讲人默认进入演示模式
        guard let fileType = DriveFileType(rawValue: originFileType), fileType.isPPT else { return }
        guard followAPIDelegate?.isHostNativeContent == true else { return }
        followRoleChangeSubject.take(1).observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] role in
                guard role == .presenter else { return }
                DocsLogger.driveInfo("drive.pdf.follow --- set to presentationMode")
                self?.presentationModeChangedSubject.onNext((true, .auto))
        }).disposed(by: disposeBag)
        
    }
}

extension DrivePDFViewModel: FollowableContent {

    typealias State = DrivePDFFollowState
    typealias RelativeLocation = FollowLocationState

    var isInVCFollow: Bool {
        return followAPIDelegate != nil
    }

    var pdfFollowStateUpdated: Driver<State> {
        return pdfFollowStateSubject
            .asDriver(onErrorJustReturn: .default)
    }

    var currentPDFState: State {
        return pdfStateRelay.value
    }

    var moduleName: String {
        return State.module
    }

    var relativeLocationChanged: Observable<RelativeLocation> {
        let presenterStateObservable = presenterStateRelay.compactMap { $0 } // 仅在 presenter state 不为 nil 的时候
        return Observable
            .combineLatest(pdfStateRelay, presenterStateObservable)
            .compactMap { [weak self] follower, presenter in
                guard let self = self else { return nil }
                return self.relativeLocation(follower: follower, presenter: presenter)
            }
    }

    func onSetup(delegate: FollowableContentDelegate) {
        guard followContentDelegate == nil else { return }
        DocsLogger.driveInfo("drive.pdf.follow --- setting up pdf follow content delegate")
        followContentDelegate = delegate
        monitorStateChanged()
    }

    private func monitorStateChanged() {
        pdfFollowStateSubject
            .bind(to: pdfStateRelay)
            .disposed(by: followStateDisposeBag)

        pdfStateRelay
            .subscribe(onNext: { [weak self] newState in
                guard let delegate = self?.followContentDelegate else { return }
                DocsLogger.debug("drive.pdf.follow --- follow content state changed")
                delegate.onContentEvent(.stateChanged(newState.followModuleState), at: self?.followMountToken)
            })
            .disposed(by: followStateDisposeBag)
        relativeLocationChanged
            .subscribe(onNext: { [weak self] newLocation in
                guard let delegate = self?.followContentDelegate else { return }
                DocsLogger.debug("drive.pdf.follow --- relative location state changed")
                delegate.onContentEvent(.presenterLocationChanged(newLocation), at: self?.followMountToken)
            })
            .disposed(by: followStateDisposeBag)
    }

    func setState(_ state: FollowModuleState) {
        // PDF 过滤掉同层 Follow 的事件（DoxBoxPreview）
        guard state.module != FollowModule.docxBoxPreview.rawValue else { return }
        guard let pdfState = State(followModuleState: state) else {
            DocsLogger.error("drive.pdf.follow --- failed to convert module state to pdf state", extraInfo: ["moduleState": state])
            return
        }
        pdfFollowStateSubject.onNext(pdfState)
    }

    func getState() -> FollowModuleState? {
        return currentPDFState.followModuleState
    }

    func updatePresenterState(_ state: FollowModuleState?) {
        let presenterState: State?
        if let state = state {
            presenterState = State(followModuleState: state)
        } else {
            presenterState = nil
        }
        DocsLogger.debug("drive.pdf.follow --- receive presenter state")
        presenterStateRelay.accept(presenterState)
    }

    func relativeLocation(follower: State, presenter: State) -> RelativeLocation? {
        let pageCount = self.pageCount
        guard pageCount > 0 else {
            DocsLogger.error("drive.pdf.follow --- page count is 0 when calculating relative location")
            return nil
        }
        let followerLocation = convert(state: follower, pageCount: pageCount)
        let presenterLocation = convert(state: presenter, pageCount: pageCount)
        return RelativeLocation(presenter: presenterLocation, follower: followerLocation)
    }

    func convert(state: State, pageCount: UInt) -> RelativeLocation.Location {
        switch state {
        case let .preview(location, _):
            let x = Double(location.pageOffset.x)
            let y = (Double(location.pageNumber - 1) + Double(location.pageOffset.y)) / Double(pageCount)
            let space = "preview"
            return RelativeLocation.Location(x: x, y: y, space: space)
        case let .presentation(pageNumber):
            let x = Double(pageNumber) / Double(pageCount)
            let y = 0.5
            let space = "presentation"
            return RelativeLocation.Location(x: x, y: y, space: space)
        }
    }
}
