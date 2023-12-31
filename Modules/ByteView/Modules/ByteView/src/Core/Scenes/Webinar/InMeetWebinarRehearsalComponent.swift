//
//  InMeetWebinarRehearsalComponent.swift
//  ByteView
//
//  Created by liujianlong on 2023/1/16.
//

import UIKit
import UniverseDesignColor
import UniverseDesignActionPanel
import UniverseDesignShadow
import RxSwift
import ByteViewSetting

// Webinar 彩排组件，控制 host 彩排 bar
class InMeetWebinarRehearsalComponent: InMeetViewComponent {
    private weak var container: InMeetViewContainer?
    private let viewModel: InMeetViewModel
    private let disposeBag = DisposeBag()
    private var hasHostAuthority: Bool = false {
        didSet {
            guard self.hasHostAuthority != oldValue else {
                return
            }
            self.isHostRehearsing = hasHostAuthority && isRehearsing
        }
    }

    private var isRehearsing: Bool = false {
        didSet {
            guard self.isRehearsing != oldValue else {
                return
            }
            /* 彩排相关 Toast 由后端推送
             * if !isRehearsing {
             *     Toast.show(I18n.View_G_TheHostStartWebinar)
             * } else if isRehearsing && !hasHostAuthority {
             *     Toast.show(I18n.View_G_RehearsingToast)
             * }
             */
            self.isHostRehearsing = hasHostAuthority && isRehearsing
        }
    }

    private var currentLayoutType: LayoutType
    private var isMobileLandscapeOrPadRegularWidth: Bool {
        if Display.phone {
            return currentLayoutType.isPhoneLandscape
        } else {
            return currentLayoutType.isRegular
        }
    }


    private var isRegularMode: Bool = false {
        didSet {
            guard self.isRegularMode != oldValue else {
                return
            }
            if let container = self.container {
                self.updateBGColor(container: container)
            }
        }
    }

    private var isHostRehearsing: Bool = false {
        didSet {
            guard self.isHostRehearsing != oldValue else {
                return
            }
            guard let container = self.container else {
                return
            }
            if isHostRehearsing {
                container.topExtendContainerComponent?.addChild(self.webinarRehearsalBar, for: .webinarRehearsal)
                updateBGColor(container: container)
            } else {
                container.topExtendContainerComponent?.removeChild(for: .webinarRehearsal)
            }
        }
    }

    private lazy var webinarRehearsalBar = {
        let bar = SceneTopStatusBar(regularAlignment: .floating, compactAlignment: .distribute)
        bar.numberOfLines = 0
        bar.hideInFullScreenMode = true
        bar.setLabelText(I18n.View_G_RehearsingToast)
        bar.setButtonText(I18n.View_G_StartWebinar_Button)
        bar.buttonAction = { [weak self] sender in
            let source = UDActionSheetSource(sourceView: sender,
                                             sourceRect: sender.bounds,
                                             preferredContentWidth: 375.0,
                                             arrowDirection: .up)
            let config = UDActionSheetUIConfig(isShowTitle: true, popSource: source)
            let actionsheet = UDActionSheet(config: config)
            actionsheet.isAutorotatable = true
            actionsheet.setTitle(I18n.View_G_StartWebinar_Notice)
            actionsheet.addDefaultItem(text: I18n.View_G_StartWebinar_Button, action: { [weak self] in
                guard let self = self, self.hasHostAuthority else { return }
                InMeetWebinarTracks.startWebinarFromRehearsal()
                self.viewModel.meeting.webinarManager?.startWebinarFromRehearsal()
            })
            actionsheet.setCancelItem(text: I18n.View_G_CancelButton)
            self?.viewModel.router.present(actionsheet)
        }
        return bar
    }()

    private func updateBGColor(container: InMeetViewContainer) {
        guard isHostRehearsing else {
            return
        }
        webinarRehearsalBar.updateStatusBarStyle()
    }

    var componentIdentifier: InMeetViewComponentIdentifier {
        .webinarRehearsal
    }
    private let statusManager: InMeetStatusManager
    required init(container: InMeetViewContainer, viewModel: InMeetViewModel, layoutContext: VCLayoutContext) throws {
        self.container = container
        self.viewModel = viewModel
        self.currentLayoutType = layoutContext.layoutType
        self.statusManager = viewModel.resolver.resolve()!
        self.statusManager.addListener(self)
    }

    func containerDidLoadComponent(container: InMeetViewContainer) {
        guard self.viewModel.meeting.subType == .webinar else {
            return
        }
        if Display.phone {
            InMeetOrientationToolComponent.isLandscapeModeRelay
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else {
                        return
                    }
                    self.isRegularMode = self.isMobileLandscapeOrPadRegularWidth
                })
                .disposed(by: self.disposeBag)
        }
        self.hasHostAuthority = self.viewModel.meeting.setting.hasHostAuthority
        self.isRegularMode = self.isMobileLandscapeOrPadRegularWidth
        self.viewModel.meeting.webinarManager?.addListener(self, fireImmediately: true)
        self.viewModel.meeting.setting.addListener(self, for: .hasHostAuthority)
    }

    func containerDidChangeLayoutStyle(container: InMeetViewContainer, prevStyle: MeetingLayoutStyle?) {
        self.updateBGColor(container: container)
    }

    func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        self.currentLayoutType = newContext.layoutType
        self.isRegularMode = self.isMobileLandscapeOrPadRegularWidth
    }
}

extension InMeetWebinarRehearsalComponent: WebinarRoleListener, MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        if key == .hasHostAuthority {
            Util.runInMainThread {
                self.hasHostAuthority = isOn
            }
        }
    }

    func webinarDidChangeRehearsal(isRehearsing: Bool, oldValue: Bool?) {
        Util.runInMainThread {
            self.isRehearsing = isRehearsing
        }
    }
}

extension InMeetWebinarRehearsalComponent: InMeetStatusManagerListener {
    func statusDidChange(type: InMeetStatusType) {
        Util.runInMainThread {
            self.webinarRehearsalBar.isStatusEmpty = self.statusManager.statuses.isEmpty
            self.webinarRehearsalBar.updateWebinarBar()
        }
    }
}
