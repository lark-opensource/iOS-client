//
//  EventAttendeeLimitApproveViewController.swift
//  Calendar
//
//  Created by huoyunjie on 2022/6/10.
//

import Foundation
import UIKit
import LarkUIKit
import SnapKit
import UniverseDesignInput
import UniverseDesignColor
import UniverseDesignFont
import CalendarFoundation
import LarkTimeFormatUtils
import EventKit
import RxSwift
import RxCocoa
import UniverseDesignToast
import LKCommonsLogging

struct AttendeeLimitApprove {
    static let logger = Logger.log(CalendarList.self, category: "lark.calendar.attendee_limit_approve")

    static func logInfo(_ message: String) {
        logger.info(message)
    }

    static func logError(_ message: String) {
        logger.error(message)
    }

    static func logWarn(_ message: String) {
        logger.warn(message)
    }

    static func logDebug(_ message: String) {
        logger.debug(message)
    }
}

class EventAttendeeLimitApproveViewController: UIViewController {
    // 申请原因
    private lazy var reasonField: UDMultilineTextField = {
        let textField = UDMultilineTextField()
        textField.placeholder = I18n.Calendar_G_EnterReason
        textField.config.font = UIFont.cd.font(ofSize: 14)
        textField.config.textMargins = .zero
        return textField
    }()

    // 参与者数量
    private lazy var attendeeCountField: UDTextField = {
        let textField = UDTextField()
        textField.placeholder = I18n.Calendar_G_EnterGuestNumber
        textField.config.font = UIFont.cd.font(ofSize: 14)
        textField.config.errorMessege = I18n.Calendar_G_EnterOneFiveThousand(number: viewModel.underLimit, num: viewModel.upperLimit)
        textField.config.maximumTextLength = 5
        textField.input.keyboardType = .numberPad
        return textField
    }()

    // 审批信息
    private lazy var summary: EventContentView = {
        return EventContentView(title: I18n.Calendar_Edit_Subject)
    }()

    private lazy var time: EventContentView = {
        return EventContentView(title: I18n.Calendar_Edit_EventTime)
    }()

    private lazy var rrule: EventContentView = {
        return EventContentView(title: I18n.Calendar_EmailGuest_HtmlOccurrence)
    }()

    // 审批人
    let avatarViews = UIView()

    // LoadingView
    private lazy var loadingView: LoadingView = {
        let loadingView = LoadingView(displayedView: view)
        loadingView.backgroundColor = UIColor.ud.bgBody
        return loadingView
    }()

    private let viewModel: EventAttendeeLimitApproveViewModel
    private let rxSubmitting: BehaviorRelay<Bool> = .init(value: false)
    private let disposeBag = DisposeBag()

    init(viewModel: EventAttendeeLimitApproveViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = I18n.Calendar_G_IncreaseNumberRequest
        view.backgroundColor = UDColor.bgBase

        setupNaviItem()
        setupView()
        bindViewData()
        bindViewAction()

        let tap = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc
    private func hideKeyboard() {
        view.endEditing(true)
    }
}

// MARK: Setup View
extension EventAttendeeLimitApproveViewController {
    private func setupNaviItem() {
        let cancelItem = LKBarButtonItem(title: BundleI18n.Calendar.Calendar_Common_Cancel)
        cancelItem.button.rx.controlEvent(.touchUpInside)
            .bind { [weak self] in
                self?.presentingViewController?.dismiss(animated: true) { [weak self] in
                    self?.viewModel.cancelCommitHandler?()
                }
            }.disposed(by: disposeBag)
        navigationItem.leftBarButtonItem = cancelItem

        let commitItem = LKBarButtonItem(title: I18n.Calendar_G_Submit, fontStyle: .medium)
        commitItem.button.tintColor = UIColor.ud.primaryContentDefault
        commitItem.button.rx.controlEvent(.touchUpInside)
            .bind { [weak self] in
                guard let self = self else { return }
                self.rxSubmitting.accept(true)
                self.hideKeyboard()
                UDToast.showLoading(with: I18n.Calendar_Common_LoadAndWait, on: self.view)
                self.viewModel.commitApprove()
                    .subscribeForUI(onNext: { [weak self] success in
                        if success {
                            self?.presentingViewController?.dismiss(animated: true, completion: { [weak self] in
                                self?.viewModel.approveCommitSucceedHandler?()
                            })
                        }
                        self?.rxSubmitting.accept(false)
                    }, onError: { [weak self] error in
                        guard let self = self else { return }
                        UDToast.showFailure(with: I18n.Calendar_Common_TryAgain, on: self.view)
                        self.rxSubmitting.accept(false)
                        AttendeeLimitApprove.logError("attendee limit approve form commit error: \(error)")
                    }).disposed(by: self.disposeBag)
            }
            .disposed(by: disposeBag)
        navigationItem.rightBarButtonItem = commitItem
    }

    private func setupView() {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.addArrangedSubview(generateReasonView())
        stackView.addArrangedSubview(generateAttendeeCountView())
        stackView.addArrangedSubview(generateApproveDetail())
        stackView.addArrangedSubview(generateApproversView())

        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .onDrag

        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.left.right.bottom.equalToSuperview()
        }

        scrollView.addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.right.left.equalTo(scrollView.frameLayoutGuide)
            $0.top.bottom.equalTo(scrollView.contentLayoutGuide)
        }
    }

    private func generateApproveDetail() -> UIView {
        let stackView = UIStackView()
        stackView.backgroundColor = UDColor.bgBody
        stackView.axis = .vertical
        stackView.spacing = 12

        let titleLabel = UILabel()
        titleLabel.text = I18n.Calendar_G_ApprovalDetails
        titleLabel.textColor = UDColor.textTitle
        titleLabel.font = UIFont.cd.mediumFont(ofSize: 16)

        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(summary)
        stackView.addArrangedSubview(time)
        stackView.addArrangedSubview(rrule)

        let containerView = UIView()
        containerView.backgroundColor = UDColor.bgBody
        containerView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(12)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        return containerView
    }

    private func generateAttendeeCountView() -> UIView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8

        let titleLabel = UILabel()
        titleLabel.textColor = UDColor.textTitle
        titleLabel.font = UIFont.cd.mediumFont(ofSize: 16)
        titleLabel.btd_setText("\(I18n.Calendar_G_GuestNumber)*", withNeedHighlightedText: "*", highlightedColor: UDColor.functionDangerContentDefault)

        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(attendeeCountField)

        let containerView = UIView()
        containerView.backgroundColor = UDColor.bgBody
        containerView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(12)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        return containerView
    }

    private func generateApproversView() -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = UDColor.bgBody

        let titleLabel = UILabel()
        titleLabel.textColor = UDColor.textTitle
        titleLabel.font = UIFont.cd.mediumFont(ofSize: 16)
        titleLabel.text = I18n.Calendar_Approval_Approver

        containerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.height.equalTo(24)
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(12)
        }

        containerView.addSubview(avatarViews)
        avatarViews.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(13)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(0)
            make.bottom.equalToSuperview().inset(12)
        }

        return containerView
    }

    private func generateReasonView() -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = UDColor.bgBody

        let titleLabel = UILabel()
        titleLabel.textColor = UDColor.textTitle
        titleLabel.font = UIFont.cd.mediumFont(ofSize: 16)
        titleLabel.btd_setText("\(I18n.Calendar_G_RequestReason)*", withNeedHighlightedText: "*", highlightedColor: UDColor.functionDangerContentDefault)

        containerView.addSubview(titleLabel)
        containerView.addSubview(reasonField)

        titleLabel.snp.makeConstraints { make in
            make.height.equalTo(24)
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(12)
        }

        reasonField.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(11)
            make.bottom.equalToSuperview().inset(12)
        }
        return containerView
    }

    private func initApproverAvatarViews(_ avatars: [Avatar]) {
        avatarViews.setNeedsLayout()
        avatarViews.layoutIfNeeded()
        let maxX = avatarViews.bounds.maxX
        var nextX: CGFloat = 0              // 下一个胶囊 frame.x
        var nextY: CGFloat = 0              // 下一个胶囊 frame.y
        let spacingX: CGFloat = 8           // 胶囊间水平间隙
        let spacingY: CGFloat = 12          // 胶囊间垂直间隙
        let nameLeftSpacing: CGFloat = 26   // 名字距胶囊左边距
        let nameRightSpacing: CGFloat = 8   // 名字距胶囊右边距
        let capsuleHeight: CGFloat = 24     // 胶囊view高度
        let capsuleMaxWidth: CGFloat = 343  // 胶囊view最大宽度
        avatars.forEach { avatar in
            let view = AttendeeApproverAvatarView()
            view.avatar = avatar
            let textWidth = avatar.userName.getWidth(withConstrainedHeight: capsuleHeight, font: UIFont.cd.font(ofSize: 14))
            var viewWidth = min(nameLeftSpacing + textWidth + nameRightSpacing, capsuleMaxWidth) // 文字左边距 + 文字宽度 + 文字右边距 = 胶囊宽度，最大宽度为 343
            if nextX + viewWidth > maxX {
                nextX = 0
                nextY += capsuleHeight + spacingY
            }
            view.frame = CGRect(x: nextX, y: nextY, width: viewWidth, height: 24)
            avatarViews.addSubview(view)
            nextX += viewWidth + spacingX
        }
        avatarViews.snp.updateConstraints { make in
            make.height.equalTo(nextY + 24)
        }
    }
}

// MARK: Bind ViewData
extension EventAttendeeLimitApproveViewController {
    private func bindViewData() {
        viewModel.rxDataStatus.subscribeForUI(onNext: { [weak self] status in
            guard let self = self else { return }
            switch status {
            case .initial:
                self.loadingView.showLoading()
            case .failed:
                self.loadingView.showFailed { [weak self] in
                    self?.viewModel.retryLoad()
                }
            case .dataLoaded(let viewData):
                self.loadingView.hideSelf()
                self.loadingView.remove()
                self.summary.setText(viewData.summary)
                self.time.setText(viewData.time)
                self.rrule.setText(viewData.rrule)
                self.summary.isHidden = viewData.summary == nil
                self.time.isHidden = viewData.time == nil
                self.rrule.isHidden = viewData.rrule == nil
                if !viewData.approvers.isEmpty {
                    self.initApproverAvatarViews(viewData.approvers)
                }
            }

        }).disposed(by: disposeBag)
    }
}

// MARK: Bind ViewAction
extension EventAttendeeLimitApproveViewController {
    private func bindViewAction() {
        reasonField.input.rx.text.orEmpty.changed
            .observeOn(MainScheduler.instance)
            .bind { [weak self] text in
                self?.viewModel.updateReason(text)
            }
            .disposed(by: disposeBag)

        attendeeCountField.input.rx.text.orEmpty.changed
            .observeOn(MainScheduler.instance)
            .bind { [weak self] text in
                self?.viewModel.updateAttendeeNumber(text)
            }.disposed(by: disposeBag)

        // 提交按钮状态
        Observable.combineLatest(
            viewModel.rxReasonViewData,
            viewModel.rxAttendeeNumberViewData,
            rxSubmitting
        ).subscribeForUI(onNext: { [weak self] (reason, number, isSubmitting) in
            guard let self = self else { return }
            let attendeeNumberIsValid = self.viewModel.attendeeNumberIsValid
            self.attendeeCountField.setStatus(attendeeNumberIsValid || number.isEmpty ? .normal : .error)
            self.navigationItem.rightBarButtonItem?.isEnabled = !reason.isEmpty && !number.isEmpty && attendeeNumberIsValid && !isSubmitting
        }).disposed(by: disposeBag)
    }
}

fileprivate class EventContentView: UIStackView {

    private let titleLabel: UILabel = {
        let title = UILabel()
        title.textColor = UDColor.N500
        title.font = UIFont.cd.font(ofSize: 12)
        return title
    }()

    private let contentLabel: UILabel = {
        let content = UILabel()
        content.font = UIFont.cd.font(ofSize: 14)
        return content
    }()

    init(title: String) {
        super.init(frame: .zero)
        axis = .vertical
        spacing = 1
        backgroundColor = UDColor.bgBody
        titleLabel.btd_SetText(title, lineHeight: 20)
        addArrangedSubview(titleLabel)
        addArrangedSubview(contentLabel)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setText(_ text: String?) {
        contentLabel.btd_SetText(text ?? "", lineHeight: 22)
    }
}
