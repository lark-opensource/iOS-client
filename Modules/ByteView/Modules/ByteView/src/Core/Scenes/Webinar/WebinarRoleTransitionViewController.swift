//
// Created by liujianlong on 2022/10/9.
//

import UIKit
import UniverseDesignLoading
import UniverseDesignColor
import UniverseDesignButton
import UniverseDesignIcon
import SnapKit
import ByteViewMeeting
import RxSwift


struct WebinarRoleTransitionBody: RouteBody {
    static let pattern = "//client/videoconference/webinar-role-transition"
    let meetingId: String
    let isWebinarAttendee: Bool
    let webinarManager: InMeetWebinarManager
}

class WebinarRoleTransitionHandler: RouteHandler<WebinarRoleTransitionBody> {
    override func handle(_ body: WebinarRoleTransitionBody) -> UIViewController? {
        guard let router = body.webinarManager.session.service?.router else { return nil }
        let vm = WebinarRoleTransitionViewModel(manager: body.webinarManager, isWebinarAttendee: body.isWebinarAttendee)
        return PresentationViewController(router: router, fullScreenFactory: {
            WebinarRoleTransitionViewController(viewModel: vm)
        }, floatingFactory: {
            WebinarRoleTransitionFloatingViewController()
        })
    }
}

class WebinarRoleTransitionFloatingViewController: BaseViewController {
    private lazy var topSpacer = UILayoutGuide()
    private lazy var bottomSpacer = UILayoutGuide()
    private lazy var loadingView = UDLoading.spin(config: UDSpinConfig(indicatorConfig: UDSpinIndicatorConfig(size: 24.0, color: UDColor.primaryContentDefault), textLabelConfig: nil))
    private lazy var loadingLabel = UILabel()
    private lazy var contentView = UIView()
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()

        loadingLabel.text = I18n.View_G_RejoinMeetingLoad
    }

    private var useSmallFont: Bool = false {
        didSet {
            guard self.useSmallFont != oldValue else {
                return
            }
            self.loadingLabel.font = UIFont.systemFont(ofSize: useSmallFont ? 10.0 : 12.0, weight: .regular)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let labelSize = NSString(string: loadingLabel.text ?? "").size(withAttributes: [.font: UIFont.systemFont(ofSize: 12.0, weight: .regular)])
        self.useSmallFont = labelSize.width > self.view.bounds.width - 4.0 * 2.0
    }

    private func setupSubviews() {
        self.view.backgroundColor = nil
        self.contentView.applyFloatingBGAndBorder()

        loadingLabel.font = UIFont.systemFont(ofSize: useSmallFont ? 10.0 : 12.0, weight: .regular)
        loadingLabel.textColor = UDColor.textCaption
        loadingLabel.textAlignment = .center
        loadingLabel.numberOfLines = 2

        self.view.addSubview(contentView)
        contentView.addLayoutGuide(topSpacer)
        contentView.addLayoutGuide(bottomSpacer)
        contentView.addSubview(loadingView)
        contentView.addSubview(loadingLabel)

        self.contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.topSpacer.snp.makeConstraints { make in
            make.top.equalToSuperview()
        }
        self.loadingView.snp.makeConstraints { make in
            make.top.equalTo(topSpacer.snp.bottom)
            make.centerX.equalToSuperview()
            make.size.equalTo(CGSize(width: 24.0, height: 24.0))
        }

        self.loadingLabel.snp.makeConstraints { make in
            make.top.equalTo(self.loadingView.snp.bottom).offset(8.0)
            make.left.right.equalToSuperview().inset(4.0)
        }
        self.bottomSpacer.snp.makeConstraints { make in
            make.top.equalTo(loadingLabel.snp.bottom)
            make.bottom.equalToSuperview()
            make.height.equalTo(topSpacer)
        }
    }
}

class WebinarRoleTransitionViewController: VMViewController<WebinarRoleTransitionViewModel> {
    private lazy var backButton: UIButton = {
        let button = UIButton()
        button.isExclusiveTouch = true
        button.addInteraction(type: .highlight)
        let normalImage = UDIcon.getIconByKey(.leftOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 24, height: 24))
        let highlightedImage = UDIcon.getIconByKey(.leftOutlined, iconColor: UIColor.ud.iconN1.withAlphaComponent(0.5), size: CGSize(width: 24, height: 24))
        button.setImage(normalImage.ud.withTintColor(UIColor.ud.iconN1), for: .normal)
        button.setImage(highlightedImage.ud.withTintColor(UIColor.ud.iconN1.withAlphaComponent(0.5)), for: .highlighted)
        return button
    }()
    private lazy var animationView = UDLoading.loadingImageView()
    private lazy var titleLabel = UILabel()
    private lazy var subtitleLabel = UILabel()
    private lazy var rejoinButton = UDButton(.primaryBlue)
    private lazy var leaveButton = UDButton(.secondaryGray)
    private lazy var topSpacer = UILayoutGuide()
    private lazy var bottomSpacer = UILayoutGuide()
    private var trackAction: String {
        viewModel.isWebinarAttendee ? "panelist_to_attendee" : "attendee_to_panelist"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    private var displayButtons = false {
        didSet {
            guard self.isViewLoaded,
                  oldValue != displayButtons else {
                return
            }
            if self.displayButtons {
                setupButtonLayout()
            } else {
                setupNoButtonLayout()
            }
        }
    }

    override func setupViews() {
        self.view.backgroundColor = UDColor.bgBase
        titleLabel.font = .systemFont(ofSize: 17.0, weight: .medium)
        titleLabel.textColor = UDColor.textTitle
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        subtitleLabel.font = .systemFont(ofSize: 14.0, weight: .regular)
        subtitleLabel.textColor = UDColor.textCaption
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        self.view.addLayoutGuide(topSpacer)
        self.view.addLayoutGuide(bottomSpacer)
        self.view.addSubview(backButton)
        self.view.addSubview(animationView)
        self.view.addSubview(titleLabel)
        self.view.addSubview(subtitleLabel)
        self.view.addSubview(rejoinButton)
        self.view.addSubview(leaveButton)

        backButton.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide).offset(10.0)
            make.left.equalTo(self.view.safeAreaLayoutGuide).offset(16.0)
            make.size.equalTo(CGSize(width: 24.0, height: 24.0))
        }
        topSpacer.snp.makeConstraints { make in
            make.top.equalToSuperview()
        }
        animationView.snp.makeConstraints { make in
            make.top.equalTo(topSpacer.snp.bottom)
            make.centerX.equalToSuperview()
            make.size.equalTo(CGSize(width: 100.0, height: 100.0))
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(animationView.snp.bottom).offset(12.0)
            make.left.right.equalToSuperview().inset(16.0)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4.0)
            make.left.right.equalToSuperview().inset(16.0)
        }
        rejoinButton.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(24.0)
            make.centerX.equalToSuperview()
            make.width.equalTo(180.0)
            make.height.greaterThanOrEqualTo(36.0)
        }
        leaveButton.snp.makeConstraints { make in
            make.top.equalTo(rejoinButton.snp.bottom).offset(12.0)
            make.centerX.equalToSuperview()
            make.width.equalTo(180.0)
            make.height.greaterThanOrEqualTo(36.0)
        }

        if self.displayButtons {
            setupButtonLayout()
        } else {
            setupNoButtonLayout()
        }
    }

    private func setupNoButtonLayout() {
        rejoinButton.isHidden = true
        leaveButton.isHidden = true
        bottomSpacer.snp.remakeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom)
            make.bottom.equalToSuperview()
            make.height.equalTo(topSpacer)
        }
    }

    private func setupButtonLayout() {
        rejoinButton.isHidden = false
        leaveButton.isHidden = false
        bottomSpacer.snp.remakeConstraints { make in
            make.top.equalTo(leaveButton.snp.bottom)
            make.bottom.equalToSuperview()
            make.height.equalTo(topSpacer)
        }
    }

    @objc
    func tapRejoinButton(sender: UIButton) {
        InMeetWebinarTracks.RoleChange.rejoinButtonClick(action: self.trackAction)
        self.viewModel.rejoinMeeting()
    }

    @objc func tapLeaveButton(sender: UIButton) {
        InMeetWebinarTracks.RoleChange.leaveButtonClick(action: self.trackAction)
        self.viewModel.leaveMeeting()
    }

    @objc func tapBackButton(sender: UIButton) {
        self.viewModel.router?.setWindowFloating(true)
    }

    let disposeBag = DisposeBag()
    override func bindViewModel() {
        self.titleLabel.text = self.viewModel.isWebinarAttendee ? I18n.View_G_HostHadChangedYou : I18n.View_G_HostHadPromotedYou
        self.subtitleLabel.text = I18n.View_G_RejoinMeetingLoad
        self.rejoinButton.setTitle(I18n.View_G_RejoinWebButton, for: .normal)
        self.leaveButton.setTitle(I18n.View_M_LeaveMeetingButton, for: .normal)
        self.backButton.addTarget(self, action: #selector(tapBackButton(sender:)), for: .touchUpInside)
        self.rejoinButton.addTarget(self, action: #selector(tapRejoinButton(sender:)), for: .touchUpInside)
        self.leaveButton.addTarget(self, action: #selector(tapLeaveButton(sender:)), for: .touchUpInside)
        let action = self.trackAction
        self.viewModel.rejoinTimeout
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    InMeetWebinarTracks.RoleChange.buttonView(action: action)
                    self?.displayButtons = true
                })
                .disposed(by: self.disposeBag)
    }
}
