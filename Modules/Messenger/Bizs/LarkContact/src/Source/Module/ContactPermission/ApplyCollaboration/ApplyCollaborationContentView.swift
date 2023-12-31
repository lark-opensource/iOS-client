//
//  ApplyCollaborationContentView.swift
//  LarkContact
//
//  Created by 姜凯文 on 2020/7/26.
//

import Foundation
import UIKit
import LarkUIKit
import EENavigator
import EditTextView
import RxSwift
import RxCocoa
import LarkBizAvatar
import LarkMessengerInterface

final class ApplyCollaborationContentView: UIView {
    private let contentViewWidth: CGFloat = Display.typeIsLike == .iPhone5 ? 206 : 260

    private let explainLabel: UILabel = UILabel()
    private let unauthorizationListView: UnauthorizationListView = UnauthorizationListView()
    private let inputTextView: LarkEditTextView = LarkEditTextView()
    private let grayView: UIView = UIView()

    private var showGrayView: Bool = false
    private var showCheckBox: Bool = true

    private let disposeBag = DisposeBag()

    var showDetailBlock: (() -> Void)?

    init() {
        super.init(frame: .zero)

        self.setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        self.addSubview(explainLabel)
        explainLabel.snp.makeConstraints { (maker) in
            maker.top.left.right.equalToSuperview()
            maker.width.equalTo(contentViewWidth)
        }

        explainLabel.numberOfLines = 0

        self.addSubview(unauthorizationListView)
        unauthorizationListView.snp.makeConstraints { (maker) in
            maker.top.equalTo(explainLabel.snp.bottom).offset(12.5)
            maker.left.right.equalToSuperview()
            maker.height.equalTo(47.5)
        }

        unauthorizationListView.layer.cornerRadius = 4
        unauthorizationListView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showApplyUserDetailAlert))
        unauthorizationListView.addGestureRecognizer(tapGesture)

        self.addSubview(inputTextView)
        inputTextView.snp.makeConstraints { (maker) in
            maker.top.equalTo(unauthorizationListView.snp.bottom).offset(15.5)
            maker.left.right.equalToSuperview()
            maker.height.equalTo(42)
        }
        let font = UIFont.systemFont(ofSize: 16)
        let defaultTypingAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.ud.N900,
            .paragraphStyle: {
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineSpacing = 2
                return paragraphStyle
            }()
        ]
        inputTextView.defaultTypingAttributes = defaultTypingAttributes
        inputTextView.font = font
        inputTextView.placeholder = BundleI18n.LarkContact.Lark_NewContacts_PermissionRequestLeaveAMessagePlaceholder
        inputTextView.placeholderTextColor = UIColor.ud.N500
        inputTextView.textContainerInset = UIEdgeInsets(top: 9, left: 12, bottom: 11, right: 12)
        inputTextView.layer.borderWidth = 1
        inputTextView.layer.borderColor = UIColor.ud.N300.cgColor
        inputTextView.layer.cornerRadius = 4
        let maxLength = 2000
        inputTextView.rx.text.asDriver().drive(onNext: { [weak self] (text) in
            guard let self = self, let text = text else { return }
            // 中文输入法，正在输入拼音时不进行截取处理
            if let language = self.inputTextView.textInputMode?.primaryLanguage, language == "zh-Hans" {
                // 获取高亮部分
                let selectRange = self.inputTextView.markedTextRange ?? UITextRange()
                // 对已输入的文字进行字数统计和限制
                if self.inputTextView.position(from: selectRange.start, offset: 0) == nil {
                    if text.count > maxLength {
                        self.inputTextView.text = String(text.prefix(maxLength))
                    }
                } else {
                    // 正在输入拼音时，不对文字进行统计和限制
                    return
                }
            } else {
                // 中文输入法以外的直接对其统计限制即可，不考虑其他语种情况
                if text.count > maxLength {
                    self.inputTextView.text = String(text.prefix(maxLength))
                }
            }
        }).disposed(by: self.disposeBag)

        self.addSubview(grayView)
        grayView.snp.makeConstraints { (maker) in
            maker.top.left.right.equalToSuperview()
            maker.bottom.equalTo(inputTextView.snp.bottom)
        }

        grayView.backgroundColor = UIColor.ud.N00
        grayView.alpha = 0.4
        grayView.isHidden = true
    }

    func setupContentView(
        contacts: [AddExternalContactModel],
        text: String?,
        showCheckBox: Bool
    ) {
        unauthorizationListView.updateUserCollectionView(contacts)
        self.explainLabel.text = text ?? BundleI18n.LarkContact.Lark_NewContacts_NeedToAddToContactstGroupDialogContent
        inputTextView.snp.remakeConstraints { (maker) in
            maker.top.equalTo(unauthorizationListView.snp.bottom).offset(15.5)
            maker.left.right.equalToSuperview()
            maker.height.equalTo(42)
            maker.bottom.equalToSuperview()
        }
    }

    func checkBoxTapHandle(checkBox: LKCheckbox) {
        checkBox.isSelected = !checkBox.isSelected
        grayView.isHidden = checkBox.isSelected
        inputTextView.resignFirstResponder()
    }

    func getInputText() -> String {
        return self.inputTextView.text
    }

    @objc
    private func showApplyUserDetailAlert() {
        self.showDetailBlock?()
    }
}

extension ApplyCollaborationContentView: LKCheckboxDelegate {
    func didTapLKCheckbox(_ checkbox: LKCheckbox) {
        self.checkBoxTapHandle(checkBox: checkbox)
    }
}

private final class UnauthorizationListView: UIView {
    static let cellIndentifier = String(describing: UnauthorizationListAvatarCollectionViewCell.self)

    private let disposeBag: DisposeBag = DisposeBag()

    private lazy var userCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 24, height: 24)
        layout.minimumLineSpacing = 6
        return UICollectionView(frame: .zero, collectionViewLayout: layout)
    }()

    private let unfoldImageView = UIImageView()

    init() {
        super.init(frame: .zero)
        self.setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        self.backgroundColor = UIColor.ud.N200

        self.addSubview(unfoldImageView)
        unfoldImageView.snp.makeConstraints { (maker) in
            maker.width.equalTo(7)
            maker.height.equalTo(13)
            maker.top.right.equalToSuperview().inset(UIEdgeInsets(top: 17, left: 0, bottom: 0, right: 10))
        }

        unfoldImageView.image = Resources.dark_right_arrow

        self.addSubview(userCollectionView)
        userCollectionView.snp.makeConstraints { (maker) in
            maker.top.left.bottom.equalToSuperview().inset(UIEdgeInsets(top: 11, left: 14, bottom: 12, right: 0))
            maker.right.equalTo(unfoldImageView.snp.left).offset(-25)
        }

        userCollectionView.register(
            UnauthorizationListAvatarCollectionViewCell.self,
            forCellWithReuseIdentifier: UnauthorizationListView.cellIndentifier
        )
        userCollectionView.backgroundColor = UIColor.ud.N200
        userCollectionView.isScrollEnabled = false
    }

    func updateUserCollectionView(_ items: [AddExternalContactModel]) {
        // 最大可展示头像数，根据屏幕宽度调整
        let maxCount = Display.typeIsLike == .iPhone5 ? 5 : 7
        Observable.just(items.prefix(maxCount)).bind(to: userCollectionView.rx.items) { (collectionView, row, _) in
            let indexPath = IndexPath(row: row, section: 0)
            let item = items[row]
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UnauthorizationListView.cellIndentifier, for: indexPath)
            if let cell = cell as? UnauthorizationListAvatarCollectionViewCell {
                cell.setContent(ID: item.ID, avatarKey: item.avatarKey)
            }
            return cell
        }.disposed(by: disposeBag)
    }
}

private final class UnauthorizationListAvatarCollectionViewCell: UICollectionViewCell {
    private var avatarView = BizAvatar()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.contentView.addSubview(avatarView)
        avatarView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setContent(ID: String, avatarKey: String) {
        self.avatarView.setAvatarByIdentifier(ID, avatarKey: avatarKey)
    }
}
