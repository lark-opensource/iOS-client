//
//  FollowContainerViewController+Direction.swift
//  ByteView
//
//  Created by liurundong.henry on 2020/5/19.
//

import Foundation
import RxSwift
import RxCocoa
import Action
import ByteViewNetwork

extension FollowContainerViewController {

    enum Layout {
        static let directionViewSideLength: CGFloat = 50.0
        static let operationViewHeight: CGFloat = 40.0
    }

    var directionViewMovableEdgeInsets: UIEdgeInsets {
        if currentLayoutContext.layoutType.isPhoneLandscape {
            let isLandscapeLeft: Bool = view.orientation == .landscapeLeft
            let isXSeries: Bool = Display.iPhoneXSeries
            let isSelfInterpreterOn: Bool = self.viewModel.isInterpreterComponentDisplayRelay.value
            return UIEdgeInsets(top: 67.0, // 无沉浸态，顶部保持 44 + 15 + 8
                                left: (isXSeries && !isLandscapeLeft) ? 39.0 : 11.0, // 刘海侧 44 + 2 - 7，非刘海侧 16 + 2 - 7
                                bottom: isXSeries ? 61.0 : 44.0, // 刘海屏 53 + 8, 非刘海屏 36 + 8
                                right: (isSelfInterpreterOn ? (isLandscapeLeft ? 54.0 : 62.0) : 0) + ((isXSeries && isLandscapeLeft) ? 39.0 : 11.0)) // 刘海侧 44 + 2 - 7，非刘海侧 16 + 2 - 7
        } else {
            let safeAreaEdgeInsets = self.view.safeAreaInsets
            return UIEdgeInsets(top: safeAreaEdgeInsets.top,
                                left: safeAreaEdgeInsets.left,
                                bottom: safeAreaEdgeInsets.bottom + Layout.operationViewHeight,
                                right: safeAreaEdgeInsets.right)
        }
    }

    private var directionViewBottomOffset: CGFloat {
        return self.operationView.frame.size.height
    }

    private var isPpt: Bool {
        guard let docType = viewModel.meeting.shareData.shareContentScene.magicShareDocument?.shareSubType else {
            return false
        }
        return docType == .ccmPpt
    }

    func setupDirectionViewAttachment() {
        directionView.enableAttachment(within: directionViewMovableEdgeInsets,
                                       attachesToEdge: .right,
                                       excludesSafeArea: false)
        directionView.defaultPosition = { [weak self] in
            guard let self = self, let superview = self.directionView.superview else {
                Self.logger.info("FollowContainerVC or its view is nil, displaying directionView may fail")
                return nil
            }
            let x = superview.bounds.maxX - Layout.directionViewSideLength - self.directionViewMovableEdgeInsets.right
            // nolint-next-line: magic number
            let y = self.view.isLandscape ? (superview.bounds.height - self.directionViewBottomOffset - Layout.directionViewSideLength - 114 + 7 - (self.isPpt ? 0 : 6)) : ((superview.bounds.height - self.directionViewBottomOffset - Layout.directionViewSideLength) / 2.0)
            return CGPoint(x: x, y: y)
        }
    }

    func bindDirectionView() {
        let tapPresenterIconActionWrapper = CocoaAction { [weak self] _ -> Observable<Void> in
            guard let self = self, let document = self.viewModel.remoteMagicShareDocument else {
                InMeetFollowViewModel.logger.warn("tapPresenterIconActionWrapper failed")
                return .empty()
            }
            UIApplication.shared.sendAction(#selector(self.resignFirstResponder), to: nil, from: nil, for: nil)
            MagicShareTracks.trackTapPresenterIcon(subType: document.shareSubType.rawValue,
                                                   followType: document.shareType.rawValue,
                                                   shareId: document.shareID,
                                                   token: document.token)
            MagicShareTracksV2.trackMagicShareClickOperation(action: .clickFollowIcon, isSharer: self.viewModel.isPresenter)
            self.viewModel.toPresenterAction.execute()
            return .empty()
        }
        let directionViewModel = MagicShareDirectionViewModel(
            tapPresenterIconAction: tapPresenterIconActionWrapper,
            avatarInfoObservable: viewModel.sharerAvatarInfoObservable,
            directionObservable: viewModel.directionSubject.asObservable(),
            isRemoteEqualLocalObservable: viewModel.isRemoteEqualLocal)
        directionView.bindViewModel(directionViewModel)

        Observable.combineLatest(viewModel.shareStatusObservable,
                                 viewModel.magicShareDocumentRelay.asObservable().map { $0 != nil },
                                 viewModel.isInterpreterComponentDisplayRelay.asObservable())
        .map { (shareStatus: MSShareStatus, isSharingDocument: Bool, _) in
            return !(shareStatus == .free && isSharingDocument)
        }
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak self] (isHidden: Bool) in
            guard let self = self else {
                Self.logger.info("FollowContainerVC is nil, displaying directionView may fail")
                return
            }
            self.directionView.isHidden = isHidden
            self.setupDirectionViewAttachment()
        })
        .disposed(by: disposeBag)
    }

    func resetDirectionViewLayout() {
        let edgeInsets = self.directionViewMovableEdgeInsets
        let isSharingPpt = self.viewModel.manager.currentRuntime?.documentInfo.shareSubType == .ccmPpt

        self.directionView.snp.remakeConstraints {
            if currentLayoutContext.layoutType.isPhoneLandscape {
                $0.right.equalToSuperview().inset(directionViewRightEdgeOffset)
            } else {
                $0.right.equalToSuperview().inset(edgeInsets.right)
            }
            $0.height.width.equalTo(Layout.directionViewSideLength)
            if currentLayoutContext.layoutType.isPhoneLandscape {
                $0.bottom.equalTo(operationView.snp.top).offset(isSharingPpt ? -107.0 : -113.0)
            } else {
                $0.centerY.equalTo(self.hitDetectView)
            }
        }
        self.setupDirectionViewAttachment()
    }

    var directionViewRightEdgeOffset: CGFloat {
        let isSelfInterpreterOn: Bool = self.viewModel.isInterpreterComponentDisplayRelay.value
        let isLandscapeLeft: Bool = view.orientation == .landscapeLeft
        let isXSeries: Bool = Display.iPhoneXSeries
        // disable-lint: magic number
        switch (isSelfInterpreterOn, isLandscapeLeft, isXSeries) {
        case (true, true, true):
            return 109.0
        case (true, false, true):
            return 65.0
        case (true, _, false):
            return 65.0
        case (_, true, true):
            return 55.0
        default:
            return 11.0
        }
        // enable-lint: magic number
    }

}
