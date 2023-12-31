//
//  ApplyFormTableViewCell.swift
//  LarkAccount
//
//  Created by Nix Wang on 2022/12/15.
//

import LarkUIKit
import UniverseDesignColor
import UniverseDesignFont
import UniverseDesignToast
import LarkAccountInterface
import LarkContainer
import RxCocoa

class ApplyFormTextCell: UITableViewCell {
    var titleLabel: UILabel = {
        var label = UILabel()
        label.font = .ud.body0
        label.textColor = .ud.textTitle
        return label
    }()

    var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .ud.body2
        label.textColor = .ud.textTitle
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        initViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initViews() {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing

        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.center.equalToSuperview()
        }

        let separator = UIView()
        separator.backgroundColor = .ud.lineDividerDefault
        contentView.addSubview(separator)
        separator.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(1.0)
        }
    }

    func setup(title: String, subtitle: String) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }
}

class ApplyFormReviewerCell: UITableViewCell {
    @Provider private var passportContactDependency: AccountDependency // user:checked (global-resolve)

    weak var hostViewController: UIViewController?

    var titleLabel: UILabel = {
        var label = UILabel()
        label.font = .ud.body0
        label.textColor = .ud.textTitle
        return label
    }()

    var avatarView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 10
        imageView.layer.masksToBounds = true
        imageView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 20, height: 20))
        }
        return imageView
    }()

    var nameLabel: UILabel = {
        let label = UILabel()
        label.font = .ud.body2
        label.textColor = .ud.textTitle
        return label
    }()

    private var reviewer: ApplyFormInfo.Reviewer?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        initViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initViews() {
        let capsuleView = UIView()
        capsuleView.backgroundColor = .ud.udtokenTagNeutralBgNormal
        capsuleView.layer.cornerRadius = 14
        let avatarStack = UIStackView(arrangedSubviews: [avatarView, nameLabel])
        avatarStack.axis = .horizontal
        avatarStack.spacing = 4
        capsuleView.addSubview(avatarStack)
        avatarStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(edges: 4.0))
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(onTap))
        capsuleView.addGestureRecognizer(tap)

        titleLabel.text = I18N.Lark_Passport_AccountAccessControl_PermissionApplication_Approver
        let stackView = UIStackView(arrangedSubviews: [titleLabel, capsuleView])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing

        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.center.equalToSuperview()
        }
    }

    func setup(reviewer: ApplyFormInfo.Reviewer) {
        self.reviewer = reviewer
        nameLabel.text = reviewer.username

        if let url = URL(string: reviewer.avatarURL) {
            avatarView.kf.setImage(with: url, placeholder: DynamicResource.default_avatar)
        }
    }

    @objc
    private func onTap() {
        guard let reviewer = self.reviewer, let hostViewController = self.hostViewController else { return }
        passportContactDependency.openProfile(reviewer.userID, hostViewController: hostViewController)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        reviewer = nil
        nameLabel.text = ""
        avatarView.image = DynamicResource.default_avatar
    }
}

class ApplyFormTextViewCell: UITableViewCell, UITextViewDelegate {
    var titleLabel: UILabel = {
        var label = UILabel()
        label.font = .ud.body0
        label.textColor = .ud.textTitle
        return label
    }()

    var placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = I18N.Lark_Passport_AccountAccessControl_PermissionApplication_ReasonContent
        label.font = .ud.body2
        label.textColor = .ud.textPlaceholder
        return label
    }()

    lazy var textView: UITextView = {
        let textView = UITextView()
        textView.typingAttributes = [
            .font : UIFont.ud.body2,
            .foregroundColor : UIColor.ud.textTitle
        ]
        textView.contentInset = .zero
        textView.delegate = self

        return textView
    }()

    var inputText: String {
        return textView.text
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        initViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initViews() {
        let title = I18N.Lark_Passport_AccountAccessControl_PermissionApplication_Reason
        let attributedTitle = NSMutableAttributedString(string: title, attributes: [.font : UIFont.ud.body0, .foregroundColor : UIColor.ud.textTitle])
        attributedTitle.append(NSAttributedString(string: "*", attributes: [.font : UIFont.ud.body0, .foregroundColor : UIColor.ud.functionDangerContentDefault]))
        titleLabel.attributedText = attributedTitle

        textView.addSubview(placeholderLabel)
        placeholderLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        textView.rx.didBeginEditing.subscribe({ [weak self] _ in
            self?.placeholderLabel.isHidden = true
        })
        textView.rx.didEndEditing.subscribe({ [weak self] _ in
            self?.placeholderLabel.isHidden = !(self?.textView.text?.isEmpty ?? true)
        })

        let stack = UIStackView(arrangedSubviews: [titleLabel, textView])
        stack.axis = .vertical
        stack.spacing = 12.0
        contentView.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(edges: 16.0))
        }
    }

}
