//
//  InMeetPopoverComponent.swift
//  ByteView
//
//  Created by wulv on 2022/1/3.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import UIKit
import ByteViewUI

/// Popover
final class InMeetPopoverComponent: InMeetViewComponent {
    var componentIdentifier: InMeetViewComponentIdentifier {
        .popover
    }
    private var disposeBag = DisposeBag()
    weak var popover: PopoverView?
    weak var backgroundCover: UIButton?
    private var blockFullScreenToken: BlockFullScreenToken? {
        didSet {
            guard blockFullScreenToken !== oldValue else {
                return
            }
            oldValue?.invalidate()
        }
    }

    let viewModel: PeopleMinutesViewModel
    weak var container: InMeetViewContainer?
    private var currentLayoutType: LayoutType
    init(container: InMeetViewContainer, viewModel: InMeetViewModel, layoutContext: VCLayoutContext) throws {
        self.container = container
        self.currentLayoutType = layoutContext.layoutType
        self.viewModel = PeopleMinutesViewModel(meeting: viewModel.meeting, context: container.context, resolver: viewModel.resolver)
        bindViewModel()
    }

    private func bindViewModel() {
        viewModel.popoverShowDriver
            .drive(onNext: { [weak self] isOpen in
                guard let self = self else { return }
                if isOpen {
                    guard self.popover == nil, let container = self.container, let topBarComponent = container.component(by: .topBar) as? InMeetTopBarComponent, let meetStatusComponent = container.component(by: .meetingStatus) as? InMeetMeetingStatusComponent else {
                        Logger.ui.warn("people minutes popover can't show, popover: \(self.popover), container: \(self.container)")
                        return
                    }
                    if self.currentLayoutType.isRegular {
                        self.showPopover(topBarComponent.topBar.interviewPopoverReferenceView, container: container, with: [])
                    } else {
                        self.showPopover(meetStatusComponent.flowStatusVC.statusView.peopleMinutesView, container: container, with: [.arrowToSource(6)])
                    }
                } else {
                    guard self.popover != nil else { return }
                    self.dismissPopover()
                }
            })
            .disposed(by: disposeBag)

        viewModel.minutesOpenedDriver
            .drive(onNext: { [weak self] opened in
                guard let self = self, opened else { return }
                if self.container?.presentedViewController != nil {
                    // 当候选人正在浏览二级页面，提示候选人返回主页面查看
                    Toast.show(I18n.View_G_EnableWrittenRecordMoreDetail)
                }
            })
            .disposed(by: disposeBag)
    }

    private func showPopover(_ source: UIView?, container: InMeetViewContainer, with configures: [PopoverLayoutConfigure]?) {
        let popover = PopoverView.peopleMinutesPopover(sourceView: source, with: configures) { [weak self, weak container] in
            guard let self = self, let container = container else { return }
            PeopleMinutesViewModel.stopPeopleMinutes(meeting: self.viewModel.meeting,
                                                     isShareing: container.context.meetingContent.isShareContent)
        }
        self.popover = popover
        container.addContent(popover, level: .popover)
        updatePopoverLayout()
        insertBackgroundCover()
        blockFullScreenToken = container.fullScreenDetector.requestBlockAutoFullScreen()
    }

    private func createBackgroundCover() -> UIButton {
        let cover = UIButton()
        cover.backgroundColor = .clear
        cover.addTarget(self, action: #selector(didClickBackgroundCover), for: .touchUpInside)
        return cover
    }

    private func insertBackgroundCover() {
        if let popover = popover, let superView = popover.superview {
            let cover = createBackgroundCover()
            self.backgroundCover = cover
            superView.insertSubview(cover, belowSubview: popover)
            cover.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }

    private func updatePopoverLayout() {
        guard let popover = popover, popover.superview != nil, let container = container else { return }
        let traitCollection = VCScene.rootTraitCollection ?? container.traitCollection
        let horizontalSizeClass = traitCollection.horizontalSizeClass
        let compactMode: Bool
        if Display.phone {
            compactMode = traitCollection.horizontalSizeClass == .compact && traitCollection.verticalSizeClass == .regular
        } else {
            compactMode = horizontalSizeClass == .compact
        }
        // nolint-next-line: magic number
        let top = container.context.isTopBarHidden ? 16 : -3
        if compactMode {
            popover.snp.remakeConstraints { make in
                make.left.equalToSuperview().offset(9)
                make.right.equalToSuperview().offset(-9)
                make.top.equalTo(container.topBarGuide.snp.bottom).offset(top)
            }
        } else if currentLayoutType.isPhoneLandscape {
            popover.snp.remakeConstraints { make in
                if let sourceView = popover.sourceView, sourceView.superview != nil {
                    make.left.equalTo(sourceView.snp.left).offset(-9)
                } else {
                    make.left.equalToSuperview().offset(9)
                }
                make.width.equalTo(343)
                make.top.equalTo(container.topBarGuide.snp.bottom).offset(top)
            }
        } else {
            popover.snp.remakeConstraints { make in
                if let sourceView = popover.sourceView, sourceView.superview != nil {
                    make.centerX.equalTo(sourceView)
                } else {
                    make.centerX.equalToSuperview()
                }
                make.width.equalTo(343)
                make.top.equalTo(container.topBarGuide.snp.bottom).offset(top)
            }
        }
    }

    private func dismissPopover() {
        popover?.removeFromSuperview()
        backgroundCover?.removeFromSuperview()
        blockFullScreenToken = nil
    }

    func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        currentLayoutType = newContext.layoutType
        self.updatePopoverLayout()
    }

    @objc private func didClickBackgroundCover() {
        viewModel.clickBackgroundCover()
    }
}
