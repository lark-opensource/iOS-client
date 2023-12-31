//
//  EventAlertScrollViewController.swift
//  CalendarFoundation
//
//  Created by Miao Cai on 2020/8/30.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift

struct ScrollableAlertMessage {
    let title: String
    var content: [String]?
}

final class ScrollableAlertView: UIView {
    typealias ActionHandler = () -> Void
    var confirmHandler: ActionHandler?
    var cancelHandler: ActionHandler?

    var confirmText: String? {
        didSet {
            confirmButton.setTitle(confirmText, for: .normal)
        }
    }
    var cancelText: String? {
        didSet {
            cancelButton.setTitle(cancelText, for: .normal)
        }
    }

    private let margin: CGFloat = 20.0
    private let disposeBag = DisposeBag()

    private let titleWrapperView: UIView = {
        let wrapperView = UIView()
        wrapperView.backgroundColor = .clear
        return wrapperView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textAlignment = .left
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()

    private let contentScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return scrollView
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()

    private lazy var confirmButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(didConfirmButtonTapped), for: .touchUpInside)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.lu.addTopBorder()
        button.setTitleColor(UIColor.ud.textDisable, for: .disabled)
        button.isEnabled = true
        return button
    }()

    private lazy var cancelButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(didCancelButtonTapped), for: .touchUpInside)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        button.lu.addTopBorder()
        button.setTitleColor(UIColor.ud.textDisable, for: .disabled)
        button.isEnabled = true
        return button
    }()

    init(
        title: String,
        subtitle: String? = nil,
        with messages: [ScrollableAlertMessage],
        confirmHandler: ActionHandler? = nil,
        cancelHandler: ActionHandler? = nil
    ) {
        self.confirmHandler = confirmHandler
        self.cancelHandler = cancelHandler
        super.init(frame: .zero)
        backgroundColor = UIColor.ud.bgBody
        layer.cornerRadius = 6
        layer.masksToBounds = true
        setupTitleWrapperView(by: title, with: subtitle)
        setupStackView(by: messages)
        setupScrollView()
        setupButtons()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupTitleWrapperView(by titleText: String, with subtitleText: String?) {
        addSubview(titleWrapperView)
        titleWrapperView.snp.makeConstraints {
            $0.width.top.equalToSuperview()
            $0.centerX.equalToSuperview()
        }
        titleLabel.text = titleText
        titleWrapperView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(margin)
            $0.centerX.equalToSuperview()
            $0.left.right.equalToSuperview().inset(margin)
            $0.bottom.equalToSuperview().inset(margin).priority(.low)
        }
        guard let text = subtitleText, !text.isEmpty else { return }
        subtitleLabel.text = text
        titleWrapperView.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
            $0.centerX.equalToSuperview()
            $0.left.right.equalToSuperview().inset(margin)
            $0.bottom.equalToSuperview().inset(margin).priority(.required)
        }
    }

    private func setupStackView(by message: [ScrollableAlertMessage]) {
        message.forEach { message in
            // 二级标题
            let titleLabel = UILabel()
            titleLabel.textColor = UIColor.ud.textTitle
            titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
            titleLabel.textAlignment = .left
            titleLabel.numberOfLines = 0
            titleLabel.text = message.title
            titleLabel.lineBreakMode = .byWordWrapping

            contentStackView.addArrangedSubview(titleLabel)
            contentStackView.setCustomSpacing(4, after: titleLabel)
            guard let contents = message.content, contents.count >= 1 else {
                assertionFailure("Invaild alert message content")
                return
            }

            // 二级副标题
            let count = contents.count
            for index in 0..<count {
                let label = UILabel()
                label.textColor = UIColor.ud.textPlaceholder
                label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
                label.textAlignment = .left
                label.numberOfLines = 0
                label.text = contents[index]
                label.lineBreakMode = .byWordWrapping
                contentStackView.addArrangedSubview(label)
                if index == count - 1 {
                    contentStackView.setCustomSpacing(12, after: label)
                } else {
                    contentStackView.setCustomSpacing(4, after: label)
                }
            }
        }
    }

    private func setupScrollView() {
        addSubview(contentScrollView)
        contentScrollView.addSubview(contentStackView)
        contentScrollView.snp.makeConstraints {
            $0.top.equalTo(titleWrapperView.snp.bottom)
            $0.left.right.equalToSuperview().inset(margin)
            // 保证 contentScroll 可以被撑开；low 避免约束冲突
            $0.height.equalTo(contentStackView.snp.height).priority(.low)
        }
        contentStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            // 保证 stackview 宽度与 scrollview 一致
            $0.width.equalToSuperview()
        }
    }

    private func setupButtons() {
        var buttons: [UIButton] = []
        if confirmHandler != nil {
            buttons.append(confirmButton)
        }
        if cancelHandler != nil {
            buttons.append(cancelButton)
        }
        let count = buttons.count
        guard !buttons.isEmpty else {
            assertionFailure("Number of Alert Buttons is invaild")
            return
        }
        if count == 1 {
            let button = buttons.first ?? confirmButton
            addSubview(button)
            button.snp.makeConstraints {
                $0.bottom.width.equalToSuperview()
                $0.centerX.equalToSuperview()
                $0.top.equalTo(contentScrollView.snp.bottom).offset(margin)
                $0.height.equalTo(50)
            }
        } else {
            cancelButton.lu.addRightBorder()
            addSubview(cancelButton)
            cancelButton.snp.makeConstraints {
                $0.left.equalToSuperview()
                $0.width.equalToSuperview().dividedBy(2)
                $0.top.equalTo(contentScrollView.snp.bottom).offset(margin)
                $0.height.equalTo(50)
            }

            addSubview(confirmButton)
            confirmButton.snp.makeConstraints {
                $0.bottom.right.equalToSuperview()
                $0.left.equalTo(cancelButton.snp.right)
                $0.top.equalTo(cancelButton.snp.top)
                $0.height.equalTo(50)
            }
        }
    }

    @objc
    private func didConfirmButtonTapped() {
        confirmHandler?()
    }

    @objc
    private func didCancelButtonTapped() {
        cancelHandler?()
    }

}

final class EventAlertScrollViewController: UIViewController {

    typealias ActionHandler = () -> Void
    private let alertView: ScrollableAlertView
    var confirmHandler: ActionHandler?
    var cancelHandler: ActionHandler?

    init(
        title: String,
        subtitle: String? = nil,
        with messages: [ScrollableAlertMessage],
        confirmText: String? = nil,
        cancelText: String? = nil,
        confirmHandler: ActionHandler? = nil,
        cancelHandler: ActionHandler? = nil
    ) {
        alertView = ScrollableAlertView(
            title: title,
            subtitle: subtitle,
            with: messages,
            confirmHandler: confirmHandler,
            cancelHandler: cancelHandler
        )
        alertView.confirmText = confirmText ?? BundleI18n.Calendar.Calendar_Common_Confirm
        alertView.cancelText = cancelText ?? BundleI18n.Calendar.Calendar_Common_Cancel
        self.confirmHandler = confirmHandler
        self.cancelHandler = cancelHandler
        super.init(nibName: nil, bundle: nil)
        self.view.backgroundColor = UIColor.ud.color(0, 0, 0, 0.3)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bindViewAction()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        view.addSubview(alertView)
        alertView.snp.makeConstraints {
            $0.top.greaterThanOrEqualTo(self.view.safeAreaLayoutGuide.snp.top).offset(36)
            $0.bottom.lessThanOrEqualTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-36)
            $0.width.equalTo(300)
            $0.center.equalToSuperview()
        }
    }

    private func bindViewAction() {
        alertView.confirmHandler = { [weak self] in
            guard let self = self else { return }
            self.alertView.isHidden = true
            self.dismiss(animated: false, completion: nil)
            self.confirmHandler?()
        }

        alertView.cancelHandler = { [weak self] in
            guard let self = self else { return }
            self.alertView.isHidden = true
            self.dismiss(animated: false, completion: nil)
            self.cancelHandler?()
        }
    }
}
