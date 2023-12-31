//
//  InMeetWebSpaceContainerViewController.swift
//  ByteView
//
//  Created by fakegourmet on 2022/12/1.
//

import Foundation
import ByteViewUI
import ByteViewNetwork
import UniverseDesignColor
import UniverseDesignToast

/// 方案设计
/// https://bytedance.feishu.cn/docx/Emmod6eP3oYndFxJOODcEdrJnjq
class InMeetWebSpaceContainerViewController: VMViewController<InMeetWebSpaceViewModel> {

    private lazy var interviewerCount: Int = viewModel.meeting.participant.interviewerCount {
        didSet {
            if interviewerCount > oldValue {
                showLongToast(text: I18n.View_G_InterviewerHereHidePage)
            }
        }
    }

    private let navigationWrapperViewController: NavigationController = {
        let nav = NavigationController()
        nav.interactivePopDisabled = true
        nav.navigationBar.isHidden = true
        return nav
    }()

    private let navigationWrapperView: UIView = {
        let view = UIView()
        return view
    }()

    let contentLayoutGuide: UILayoutGuide = {
        let guide = UILayoutGuide()
        #if DEBUG
        guide.identifier = "webspace-content-layout-guide"
        #endif
        return guide
    }()
    let bottomBarLayoutGuide = UILayoutGuide()

    private var wrapperVC: MagicShareWrapperViewController?

    /// 操作栏
    private lazy var operationView: InMeetWebSpaceOperationView = {
        let view = InMeetWebSpaceOperationView()
        view.meetingLayoutStyle = viewModel.context.meetingLayoutStyle
        view.updateBackgroundColor()
        view.refreshButton.addTarget(self, action: #selector(didTapRefreshButton), for: .touchUpInside)
        view.stopSharingButton.addTarget(self, action: #selector(didTapStopButton), for: .touchUpInside)
        view.fileNameLabel.attributedText = .init(string: I18n.View_VM_YouAreViewingSpace, config: .tinyAssist, textColor: UIColor.ud.textTitle)
        return view
    }()

    override func setupViews() {
        super.setupViews()

        view.backgroundColor = UIColor.ud.N100
        isNavigationBarHidden = true

        view.addLayoutGuide(contentLayoutGuide)
        view.addLayoutGuide(bottomBarLayoutGuide)

        view.addSubview(operationView)
        view.addSubview(navigationWrapperView)

        addChild(navigationWrapperViewController)
        navigationWrapperView.addSubview(navigationWrapperViewController.view)
        navigationWrapperViewController.view.snp.remakeConstraints {
            $0.edges.equalToSuperview()
        }
        navigationWrapperViewController.didMove(toParent: self)

        // layout operationView
        if Display.phone {
            operationView.snp.remakeConstraints {
                $0.left.right.equalToSuperview()
                $0.bottom.equalTo(bottomBarLayoutGuide.snp.top)
            }
        } else {
            operationView.snp.remakeConstraints {
                $0.left.right.equalToSuperview()
                $0.top.equalTo(contentLayoutGuide.snp.top)
            }
        }
        // layout navigationWrapperView
        navigationWrapperView.snp.remakeConstraints {
            $0.left.right.equalToSuperview()
            if Display.phone {
                $0.top.equalTo(contentLayoutGuide.snp.top)
                $0.bottom.equalTo(operationView.snp.top)
            } else {
                $0.top.equalTo(operationView.snp.bottom)
                $0.bottom.equalTo(contentLayoutGuide.snp.bottom)
            }
        }
    }

    override func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        self.operationView.updateLayout()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadContent()
        if interviewerCount == 0 && viewModel.manager.isWebSpaceGuideShown == false {
            showLongToast(text: I18n.View_G_OnboardingForBackgroundPage)
        }
        viewModel.manager.isWebSpaceGuideShown = true
    }

    private func loadContent() {
        if let runtime = viewModel.manager.currentRuntime {
            let vc = MagicShareWrapperViewController(runtime: runtime, meeting: viewModel.meeting, context: viewModel.context)
            navigationWrapperViewController.setViewControllers([], animated: false)
            navigationWrapperViewController.setViewControllers([vc], animated: false)
        }
    }

    override func bindViewModel() {
        super.bindViewModel()
        _ = interviewerCount // initialize interviewerCount
        viewModel.meeting.participant.addListener(self, fireImmediately: false)
        viewModel.manager.addListener(self)
    }

    private func showLongToast(text: String) {
        let workItem: DispatchWorkItem = DispatchWorkItem {
            guard let view = self.view else { return }
            let config = UDToastConfig(
                toastType: .info,
                text: text,
                operation: UDToastOperationConfig(text: I18n.View_G_CloseButton, displayType: .vertical),
                delay: 6.0
            )
            UDToast.removeToast(on: view)
            UDToast.showToast(with: config, on: view, delay: 6.0, operationCallBack: { _ in
                UDToast.removeToast(on: view)
            })
        }
        let deadline: DispatchTime = isViewAppeared ? .now() : .now() + .milliseconds(500)
        DispatchQueue.main.asyncAfter(deadline: deadline, execute: workItem)

    }

    @objc func didTapRefreshButton() {
        viewModel.manager.currentRuntime?.reload()
    }

    @objc func didTapStopButton() {
        MeetingTracksV2.trackClickEnterprisePromotion(isToolBar: false)
        viewModel.manager.close()
    }
}

extension InMeetWebSpaceContainerViewController: InMeetWebSpaceDataObserver {
    func didChangeWeb(title: String?) {
        operationView.updateFileName("\(I18n.View_VM_YouAreViewingSpace)\(title)")
    }
}

extension InMeetWebSpaceContainerViewController: InMeetParticipantListener {
    func didChangeCurrentRoomParticipants(_ output: InMeetParticipantOutput) {
        interviewerCount = viewModel.meeting.participant.interviewerCount
    }
}

extension InMeetWebSpaceContainerViewController: MeetingSceneModeListener {
    func containerDidChangeSceneMode(container: InMeetViewContainer, sceneMode: InMeetSceneManager.SceneMode) {
        if container.sceneMode == .gallery {
            // 切换宫格视图直接退出
            viewModel.manager.close()
            container.sceneManager.switchSceneMode(.gallery)
        }
    }
}

extension InMeetWebSpaceContainerViewController: MeetingLayoutStyleListener {
    func containerDidChangeLayoutStyle(container: InMeetViewContainer, prevStyle: MeetingLayoutStyle?) {}
}
