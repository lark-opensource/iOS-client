//
//  VideoMeetingSettingViewController.swift
//  Calendar
//
//  Created by zhuheng on 2021/4/7.
//
import UniverseDesignIcon
import LarkUIKit
import RxSwift
import RxCocoa
import UniverseDesignActionPanel
import RustPB
import LarkAlertController
import LarkActionSheet
import UniverseDesignFont
import LarkKeyboardKit
import UIKit
import LarkContainer
import UniverseDesignToast
import LKCommonsLogging
import UniverseDesignColor

protocol VideoMeetingSettingViewControllerDelegate: AnyObject {
    func didFinishEdit(from viewController: VideoMeetingSettingViewController)
}

/// 日程 - 视频会议设置页
final class VideoMeetingSettingViewController: BaseUIViewController, UIGestureRecognizerDelegate, UserResolverWrapper {
    private let logger = Logger.log(VideoMeetingSettingViewModel.self, category: "calendar.VideoMeetingSettingViewModel")

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(EventEditUIStyle.Color.viewControllerBackground)
    }
    weak var delegate: VideoMeetingSettingViewControllerDelegate?
    private(set) var viewModel: VideoMeetingSettingViewModel
    private let disposeBag = DisposeBag()

    private let videoTypeSelectView = VideoTypeSelectView()
    private let videoURLInputView = VideoURLInputView()
    private lazy var inputViewTopDivideView = EventBasicDivideView()
    private lazy var switchViewBottomDivideView = EventBasicDivideView()
    private lazy var scrollView = UIScrollView()
    private lazy var switchView: EventEditSwitch = {
        let isOpen = self.viewModel.rxVideoMeeting.value.videoMeetingType != .noVideoMeeting
        let switchView = EventEditSwitch(isOn: isOpen, descText: BundleI18n.Calendar.Calendar_Edit_VC)
        return switchView
    }()

    let userResolver: UserResolver
    @ScopedInjectedLazy var calendarDependency: CalendarDependency?
    @ScopedInjectedLazy var serverPushService: ServerPushService?

    init(viewModel: VideoMeetingSettingViewModel, userResolver: UserResolver) {
        self.viewModel = viewModel
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = EventEditUIStyle.Color.viewControllerBackground
        title = BundleI18n.Calendar.Calendar_Edit_JoinSettings
        setupView()
        bindAction()
        bindViewData()
        bindViewModel()

        registerBindAccountNotification()
        naviPopGestureRecognizerEnabled = false
    }

    private func registerBindAccountNotification() {
        serverPushService?
            .rxZoomBind
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.logger.info("Zoom Account Notification Bind Success Push")
                self.viewModel.createZoomMeeting()
                UDToast.showTips(with: I18n.Calendar_Settings_BindSuccess, on: self.view)
            }).disposed(by: disposeBag)
    }

    /// 适配侧滑手势保存视频会议逻辑
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if viewModel.needShowNoUrlAlert() || viewModel.needBindZoomAccount() {
            // 尚未填写跳转链接，此时返回将默认选择飞书视频会议
            let alertController = LarkAlertController()
            if viewModel.needShowNoUrlAlert() {
                alertController.setContent(text: BundleI18n.Calendar.Calendar_Edit_NotFillInOtherVCLinksReturn())
            } else {
                alertController.setContent(text: I18n.Calendar_Zoom_DidNotAddReturn())
            }
            alertController.addSecondaryButton(text: BundleI18n.Calendar.Calendar_Detail_BackToEdit)
            alertController.addPrimaryButton(text: BundleI18n.Calendar.Calendar_Common_Return, dismissCompletion: { [weak self] in
                guard let self = self else { return }
                self.viewModel.onSave(customSummary: self.videoURLInputView.customSummary, customUrl: self.videoURLInputView.customURL)
                self.viewModel.onVideoTypeChange(videoType: .feishu)
                self.delegate?.didFinishEdit(from: self)
            })
            self.present(alertController, animated: true)
            return false
        } else {
            if viewModel.rxVideoMeeting.value.videoMeetingType == .zoomVideoMeeting {
                viewModel.onSave()
            } else {
                viewModel.onSave(customSummary: videoURLInputView.customSummary, customUrl: videoURLInputView.customURL)
            }
            delegate?.didFinishEdit(from: self)
        }
        return false
    }

    private func bindViewData() {
        viewModel.rxVideoInputViewData.bind(to: videoURLInputView).disposed(by: disposeBag)
        viewModel.rxVideoTypeSelectViewData.bind(to: videoTypeSelectView).disposed(by: disposeBag)
    }

    private func bindAction() {
        switchView.rxIsOn.skip(1).bind { [weak self] (isOn) in
            guard let self = self else { return }
            self.viewModel.onSave(customSummary: self.videoURLInputView.customSummary,
                                  customUrl: self.videoURLInputView.customURL)
            self.viewModel.onVideoOpenSwitch(isOn: isOn)
            self.switchViewBottomDivideView.isHidden = !isOn
            self.inputViewTopDivideView.isHidden = (!isOn || self.viewModel.rxVideoTypeSelectViewData.value.selectedVideoType != .custom)
        }.disposed(by: disposeBag)
        videoTypeSelectView.onItemSelected = { [weak self] (videoType) in
            guard let self = self else { return }
            self.viewModel.onVideoTypeChange(videoType: videoType)
            self.inputViewTopDivideView.isHidden = videoType != .custom
        }

        videoTypeSelectView.onClickRefreshOrRebindCallBack = { [weak self] status in
            guard let self = self else { return }
            self.viewModel.refreshZoomStatus(status: status)
        }

        videoURLInputView.videoTypeClickHandler = { [weak self] in
            guard let self = self else { return }
            let sheet = ActionSheet()
            sheet.addItem(title: BundleI18n.Calendar.Calendar_Edit_JoinVC,
                          textColor: UIColor.ud.textTitle,
                          icon: UDIcon.getIconByKeyNoLimitSize(.videoOutlined).ud.resized(to: CGSize(width: 20, height: 20)).renderColor(with: .n2),
                          entirelyCenter: true,
                          action: { [unowned self] in
                self.viewModel.onVideoIconChange(iconType: .videoMeeting)
            })

            sheet.addItem(title: BundleI18n.Calendar.Calendar_Edit_EnterLivestream,
                          textColor: UIColor.ud.textTitle,
                          icon: UDIcon.getIconByKeyNoLimitSize(.livestreamOutlined).ud.resized(to: CGSize(width: 20, height: 20)).renderColor(with: .n2),
                          entirelyCenter: true,
                          action: { [unowned self] in
                self.viewModel.onVideoIconChange(iconType: .live)
            })

            sheet.addCancelItem(title: BundleI18n.Calendar.Calendar_Common_Cancel)
            sheet.modalPresentationStyle = .pageSheet

            self.present(sheet, animated: true, completion: nil)
        }

        videoURLInputView.urlLengthExceedsLimitHandler = { [weak self] in
            guard let self = self else { return }
            UDToast.showTips(with: I18n.Calendar_G_LengthExceed, on: self.view)
        }
    }

    private func bindViewModel() {
        viewModel.rxToast
            .bind(to: rx.toast)
            .disposed(by: disposeBag)

        viewModel.rxRoute
            .subscribeForUI(onNext: { route in
                switch route {
                case let .url(url):
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }).disposed(by: disposeBag)
    }

    override func backItemTapped() {
        if viewModel.rxVideoMeeting.value.videoMeetingType == .zoomVideoMeeting {
            viewModel.onSave()
        } else {
            viewModel.onSave(customSummary: videoURLInputView.customSummary, customUrl: videoURLInputView.customURL)
        }

        if viewModel.needShowNoUrlAlert() || viewModel.needBindZoomAccount() {
            // 尚未填写跳转链接，此时返回将默认选择飞书视频会议
            let alertController = LarkAlertController()
            if viewModel.needShowNoUrlAlert() {
                alertController.setContent(text: BundleI18n.Calendar.Calendar_Edit_NotFillInOtherVCLinksReturn())
            } else {
                alertController.setContent(text: I18n.Calendar_Zoom_DidNotAddReturn())
            }
            alertController.addSecondaryButton(text: BundleI18n.Calendar.Calendar_Detail_BackToEdit)
            alertController.addPrimaryButton(text: BundleI18n.Calendar.Calendar_Common_Return, dismissCompletion: { [weak self] in
                guard let self = self else { return }
                EventEdit.logger.info("cancel edit custom video meeting")
                self.viewModel.onVideoTypeChange(videoType: .feishu)
                self.delegate?.didFinishEdit(from: self)
            })
            self.present(alertController, animated: true)
            return
        }

        delegate?.didFinishEdit(from: self)
        EventEdit.logger.info("finish edit video meeting")
    }

    private func setupView() {
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints {
            $0.left.right.top.equalToSuperview()
            $0.bottom.equalTo(self.view.lkKeyboardLayoutGuide.snp.top)
        }

        scrollView.addSubview(switchView)
        switchView.snp.makeConstraints {
            $0.top.equalTo(12)
            $0.left.right.equalToSuperview()
            $0.height.equalTo(48)
        }

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill

        stackView.addArrangedSubview(switchViewBottomDivideView)
        switchViewBottomDivideView.isHidden = self.viewModel.rxVideoMeeting.value.videoMeetingType == .noVideoMeeting

        stackView.addArrangedSubview(videoTypeSelectView)

        stackView.addArrangedSubview(inputViewTopDivideView)
        inputViewTopDivideView.isHidden = self.viewModel.rxVideoMeeting.value.videoMeetingType != .other
        stackView.addArrangedSubview(videoURLInputView)

        scrollView.addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.top.equalTo(switchView.snp.bottom)
            $0.bottom.equalToSuperview()
            $0.width.equalToSuperview()
        }

        KeyboardKit.shared.keyboardHeightChange(for: self.view).drive(onNext: { [weak self] (height) in
            guard let `self` = self else { return }

            if height > 0 {
                let offset = self.scrollView.contentSize.height - self.scrollView.bounds.height
                if offset > 0 {
                    self.scrollView.setContentOffset(CGPoint(x: 0, y: offset), animated: false)
                }
            }
        }).disposed(by: disposeBag)
    }
}
