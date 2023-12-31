//
// Created by maozhixiang.lip on 2022/8/1.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork
import ByteViewTracker
import UniverseDesignIcon
import UniverseDesignTheme
import RxSwift
import RxCocoa
import ByteViewUI

class InterviewQuestionnaireViewController: VMViewController<InterviewQuestionnaireViewModel> {
    typealias InterviewBundle = BundleResources.ByteView.Interview

    private enum TextStyles {
        static var title: VCFontConfig { VCScene.isRegular ? .h2 : .h3 }
        static var desc: VCFontConfig { VCScene.isRegular ? .r_14_22 : .bodyAssist }
        static var descAlignment: NSTextAlignment { VCScene.isRegular ? .left : .center }
        static var descColor: UIColor { VCScene.isRegular ? .ud.textTitle : .ud.textCaption }
        static var acceptBtn: VCFontConfig { VCScene.isRegular ? .m_16_24 : .h4 }
        static var refuseBtn: VCFontConfig { .hAssist }
    }

    private let disposeBag = DisposeBag()
    var dismissAction: (() -> Void)?
    var hittableView: UIView {
        VCScene.isRegular ? self.contentView : self.view
    }

    private lazy var illustrationView: UIImageView = {
        let view = UIImageView()
        view.layer.cornerRadius = 6
        view.image = BundleResources.ByteView.Interview.QuestionnaireIllustration
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .ud.primaryColor8
        label.numberOfLines = 0
        return label
    }()

    private lazy var closeButton: UIButton = {
        let closeIcon = UDIcon.getIconByKey(.closeOutlined, iconColor: .ud.iconN2, size: .init(width: 20, height: 20))
        let button = UIButton()
        button.setImage(closeIcon, for: .normal)
        button.addTarget(self, action: #selector(didTapRefuseButton), for: .touchUpInside)
        return button
    }()

    private lazy var titleContainer: UIView = {
        let view = UIView()
        view.addSubview(self.titleLabel)
        view.addSubview(self.closeButton)
        return view
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = TextStyles.descAlignment
        label.textColor = TextStyles.descColor
        return label
    }()

    private lazy var acceptButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 6
        button.layer.masksToBounds = true
        button.vc.setBackgroundColor(.ud.primaryContentDefault, for: .normal)
        button.setTitleColor(.ud.primaryOnPrimaryFill, for: .normal)
        button.addTarget(self, action: #selector(didTapAcceptButton), for: .touchUpInside)
        return button
    }()

    private lazy var refuseButton: UIButton = {
        let button = UIButton()
        button.setTitleColor(.ud.primaryContentDefault, for: .normal)
        button.vc.setBackgroundColor(.ud.bgBody, for: .normal)
        button.vc.setBackgroundColor(.ud.udtokenBtnTextBgPriPressed, for: .highlighted)
        button.addTarget(self, action: #selector(didTapRefuseButton), for: .touchUpInside)
        return button
    }()

    private lazy var contentStackView: UIView = {
        let container = UIView()
        container.addSubview(self.illustrationView)
        container.addSubview(self.titleContainer)
        container.addSubview(self.descriptionLabel)
        container.addSubview(self.acceptButton)
        container.addSubview(self.refuseButton)
        return container
    }()

    private lazy var contentView: UIView = {
        let view = UIView()
        view.addSubview(self.contentStackView)
        view.backgroundColor = .ud.bgBody
        return view
    }()

    override func setupViews() {
        super.setupViews()
        self.view.addSubview(self.contentView)
        self.setupLayout()
    }

    private func updateTitle(_ title: String) {
        self.titleLabel.attributedText = .init(string: title, config: TextStyles.title)
    }

    private func updateDescription(_ desc: String) {
        self.descriptionLabel.attributedText =
            .init(string: desc, config: TextStyles.desc, alignment: TextStyles.descAlignment)
    }

    private func updateAcceptButton(_ text: String) {
        let attributedText = NSAttributedString.init(string: text, config: TextStyles.acceptBtn)
        self.acceptButton.setAttributedTitle(attributedText, for: .normal)
    }

    private func updateRefuseButton(_ text: String) {
        let attributedText = NSAttributedString.init(string: text, config: TextStyles.refuseBtn)
        self.refuseButton.setAttributedTitle(attributedText, for: .normal)
    }

    override func bindViewModel() {
        super.bindViewModel()
        self.viewModel.title
            .drive(onNext: { self.updateTitle($0) })
            .disposed(by: self.disposeBag)
        self.viewModel.description
            .drive(onNext: { self.updateDescription($0) })
            .disposed(by: self.disposeBag)
        self.viewModel.acceptButtonText
            .drive(onNext: { self.updateAcceptButton($0) })
            .disposed(by: self.disposeBag)
        self.viewModel.refuseButtonText
            .drive(onNext: { self.updateRefuseButton($0) })
            .disposed(by: self.disposeBag)
    }

    private func setupLayout() {
        self.contentView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        if VCScene.isRegular {
            self.setupRegularLayout()
        } else {
            self.setupCompactLayout()
        }
    }

    // disable-lint: duplicated code
    private func setupCompactLayout() {
        self.view.backgroundColor = .ud.staticBlack.withAlphaComponent(0.3)
        self.contentView.layer.cornerRadius = 12
        self.contentView.layer.borderWidth = 0
        self.contentView.layer.shadowOpacity = 0
        self.contentView.snp.remakeConstraints { make in
            make.left.right.bottom.equalToSuperview()
        }
        self.contentStackView.snp.remakeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.equalToSuperview().inset(20)
            make.bottom.equalTo(self.contentView.safeAreaLayoutGuide.snp.bottom).inset(20)
        }
        self.illustrationView.snp.remakeConstraints { make in
            make.top.equalToSuperview()
            make.left.right.equalToSuperview()
            make.height.equalTo(148)
        }
        self.closeButton.isHidden = true
        self.closeButton.snp.removeConstraints()
        self.titleLabel.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.titleContainer.snp.remakeConstraints { make in
            make.top.equalTo(self.illustrationView.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.width.lessThanOrEqualToSuperview()
        }
        self.descriptionLabel.snp.remakeConstraints { make in
            make.top.equalTo(self.titleContainer.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
            make.width.lessThanOrEqualToSuperview()
        }
        self.acceptButton.contentEdgeInsets = .init(top: 12, left: 16, bottom: 12, right: 16)
        self.acceptButton.snp.remakeConstraints { make in
            make.top.equalTo(self.descriptionLabel.snp.bottom).offset(20)
            make.left.right.equalToSuperview()
        }
        self.refuseButton.isHidden = false
        self.refuseButton.snp.remakeConstraints { make in
            make.top.equalTo(self.acceptButton.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    private func setupRegularLayout() {
        self.view.backgroundColor = .clear
        self.contentView.layer.cornerRadius = 8
        self.contentView.layer.ud.setBorderColor(.ud.lineBorderCard)
        self.contentView.layer.borderWidth = 1
        self.contentView.layer.shadowOpacity = 1
        self.contentView.layer.ud.setShadowColor(.ud.shadowDefaultLg)
        self.contentView.layer.shadowRadius = 24
        self.contentView.layer.shadowOffset = .init(width: 0, height: 8)
        self.contentView.snp.remakeConstraints { make in
            make.top.equalToSuperview().inset(34)
            make.right.equalToSuperview().inset(12)
            make.width.equalTo(288)
        }
        self.contentStackView.snp.remakeConstraints { make in
            make.left.right.equalToSuperview().inset(24)
            make.top.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(25)
        }
        self.closeButton.isHidden = false
        self.titleLabel.snp.remakeConstraints { make in
            make.top.left.bottom.equalToSuperview()
        }
        self.closeButton.snp.remakeConstraints { make in
            make.top.equalToSuperview().inset(4)
            make.right.equalToSuperview()
            make.left.equalTo(self.titleLabel.snp.right).offset(8)
        }
        self.titleContainer.snp.remakeConstraints { make in
            make.top.left.right.equalToSuperview()
        }
        self.descriptionLabel.snp.remakeConstraints { make in
            make.top.equalTo(self.titleContainer.snp.bottom).offset(8)
            make.left.right.equalToSuperview()
        }
        self.illustrationView.snp.remakeConstraints { make in
            make.top.equalTo(self.descriptionLabel.snp.bottom).offset(19)
            make.left.right.equalToSuperview()
            make.height.equalTo(148)
        }
        self.acceptButton.contentEdgeInsets = .init(top: 8, left: 16, bottom: 8, right: 16)
        self.acceptButton.snp.remakeConstraints { make in
            make.top.equalTo(self.illustrationView.snp.bottom).offset(20)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        self.refuseButton.isHidden = true
        self.refuseButton.snp.removeConstraints()
    }
    // enable-lint: duplicated code

    @objc
    private func didTapAcceptButton() {
        InterviewTracker.trackClickInterviewQuestionnaireButton(.fillIn)
        self.dismissAction?()
        if let url = URL(string: self.viewModel.link) {
            viewModel.dependency.openURL(url)
        }
    }

    @objc
    private func didTapRefuseButton() {
        InterviewTracker.trackClickInterviewQuestionnaireButton(.close)
        self.dismissAction?()
    }

    override func viewDidAppear(_ animated: Bool) {
        InterviewTracker.trackShowInterviewQuestionnaireWindow()
    }
}
