//
//  DetailCustomFieldsContentCell.swift
//  Todo
//
//  Created by baiyantao on 2023/4/18.
//

import Foundation
import UniverseDesignTag
import UniverseDesignInput
import UniverseDesignIcon
import UniverseDesignFont
import LKRichView
import LarkRichTextCore
import LarkUIKit

protocol DetailCustomFieldsContentCellDelegate: AnyObject {
    func onClick(_ cell: DetailCustomFieldsContentCell)
    func onClearMember(_ cell: DetailCustomFieldsContentCell)
    func numberFieldShouldBeginEditing(_ cell: DetailCustomFieldsContentCell) -> Bool
    func onNumberFieldBeginEditing(_ cell: DetailCustomFieldsContentCell)
    func onNumberFieldEndEditing(content: String?, data: DetailCustomFieldsContentCellData?)
    func onClickMore(_ cell: DetailCustomFieldsContentCell)
}

struct DetailCustomFieldsContentCellData {
    var iconImage: UIImage
    var titleText: String
    var customType: CustomType
    var showMore: Bool = false

    var isEmpty: Bool

    // 原始数据
    var fieldVal: Rust.TaskFieldValue?
    var assoc: Rust.ContainerTaskFieldAssoc

    enum CustomType {
        case time(date: Date, formatter: DateFormatter)
        case member(users: [UserType], canClear: Bool)
        case number(rawString: String, rawDouble: Double?, settings: Rust.NumberFieldSettings)
        case tag(options: [Rust.SelectFieldOption])
        case text(text: LKRichViewCore)
    }

    var isNumberType: Bool {
        if case .number = customType {
            return true
        }
        return false
    }
}

final class DetailCustomFieldsContentCell: UITableViewCell {

    var viewData: DetailCustomFieldsContentCellData? {
        didSet {
            guard let data = viewData else { return }
            iconView.image = data.iconImage
            titleLabel.text = data.titleText

            if data.isEmpty, !data.isNumberType {
                emptyView.isHidden = false
                customView.isHidden = true
                moreView.isHidden = true
                return
            }
            moreView.isHidden = !data.showMore
            emptyView.isHidden = true
            customView.isHidden = false
            customView.subviews.forEach { $0.removeFromSuperview() }
            switch data.customType {
            case .time(let date, let formatter):
                let label = initTimeLabel()
                label.text = formatter.string(from: date)
                customView.addSubview(label)
                label.snp.remakeConstraints { $0.left.right.centerY.equalToSuperview() }
            case .member(let originUsers, let canClear):
                let users  = originUsers.prefix(5)
                let icon = UDIcon.getIconByKey(.closeOutlined, size: CGSize(width: 14, height: 14))
                let isShowClearBtn = (users.count == 1) && canClear
                let view = initUserContentView(needBackgroundColor: isShowClearBtn)
                let avatarData = AvatarGroupViewData(
                    avatars: users.map { CheckedAvatarViewData(icon: .avatar($0.avatar)) },
                    style: .big,
                    remainCount: originUsers.count - 5
                )
                view.viewData = DetailUserViewData(
                    avatarData: avatarData,
                    content: users.count == 1 ? users.first?.name : nil,
                    icon: isShowClearBtn ? icon : nil
                )
                customView.addSubview(view)
                view.snp.remakeConstraints { $0.edges.equalToSuperview() }
            case .number(_, let rawDouble, let settings):
                if let rawDouble = rawDouble {
                    fieldView.text = DetailCustomFields.double2String(rawDouble, settings: settings)
                } else {
                    fieldView.text = nil
                }
                customView.addSubview(fieldView)
                fieldView.snp.remakeConstraints { $0.left.right.centerY.equalToSuperview() }
            case .tag(let options):
                let view = DetailCustomFields.initTagListView()
                let tagViews = DetailCustomFields.options2TagViews(options, with: view)
                view.addTagViews(tagViews)
                customView.addSubview(view)
                view.snp.remakeConstraints {
                    $0.top.equalToSuperview().offset(7)
                    $0.left.right.equalToSuperview()
                }
            case .text(let text):
                customView.addSubview(textView)
                if let size = text.layout(CGSize(width: frame.width - 140, height: .greatestFiniteMagnitude)) {
                    if size.height < DetailCustomFields.cellHeight {
                        textView.frame = CGRect(x: 0, y: (DetailCustomFields.cellHeight - size.height) / 2, width: size.width, height: size.height)
                    } else {
                        textView.frame = CGRect(x: 0, y: 5, width: size.width, height: size.height)
                    }
                } else {
                    textView.frame = CGRect(x: 0, y: 0, width: frame.width - 140, height: DetailCustomFields.cellHeight)
                }
                textView.setRichViewCore(text)
            }
        }
    }

    weak var actionDelegate: DetailCustomFieldsContentCellDelegate?

    private lazy var containerView = UIView()
    private lazy var iconView = UIImageView()
    private lazy var titleLabel = initTitleLabel()
    private lazy var customView = initCustomView()
    private lazy var emptyView = initEmptyView()
    private lazy var textView = LKRichView(frame: .zero)
    private lazy var fieldView = initNumberTextField()
    private lazy var moreView = DetailCustomFieldTextMoreView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = UIColor.ud.bgBody
        selectionStyle = .none

        contentView.addSubview(containerView)
        containerView.clipsToBounds = true
        containerView.snp.makeConstraints {
            $0.left.right.top.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-4)
        }

        containerView.addSubview(iconView)
        iconView.snp.makeConstraints {
            $0.width.height.equalTo(16)
            $0.top.equalToSuperview().offset(10)
            $0.left.equalToSuperview()
        }

        containerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.centerY.equalTo(iconView)
            $0.left.equalTo(iconView.snp.right).offset(12)
            $0.width.equalTo(100)
        }

        containerView.addSubview(customView)
        customView.snp.makeConstraints {
            $0.top.bottom.right.equalToSuperview()
            $0.left.equalTo(titleLabel.snp.right).offset(12)
        }

        containerView.addSubview(emptyView)
        emptyView.snp.makeConstraints {
            $0.edges.equalTo(customView)
        }
        textView.bindEvent(selectorLists: selectors, isPropagation: true)

        containerView.addSubview(moreView)
        moreView.isHidden = true
        moreView.snp.makeConstraints { make in
            make.height.equalTo(100)
            make.left.bottom.right.equalToSuperview()
        }
        moreView.onShowTap = { [weak self] in
            guard let self = self else { return }
            self.actionDelegate?.onClickMore(self)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initTitleLabel() -> UILabel {
        let label = UILabel()
        label.textColor = UIColor.ud.textCaption
        label.font = UDFont.systemFont(ofSize: 14)
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }

    private func initCustomView() -> UIView {
        let view = UIView()
        let tap = UITapGestureRecognizer(target: self, action: #selector(onClick))
        tap.delegate = self
        view.addGestureRecognizer(tap)
        return view
    }

    private let selectors: [[CSSSelector]] = [
        [CSSSelector(value: RichViewAdaptor.Tag.a)],
        [CSSSelector(value: RichViewAdaptor.Tag.at)]
    ]

    private func initEmptyView() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBody
        let tap = UITapGestureRecognizer(target: self, action: #selector(onClick))
        view.addGestureRecognizer(tap)

        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UDFont.systemFont(ofSize: 14)
        label.text = "-"

        view.addSubview(label)
        label.snp.makeConstraints {
            $0.left.centerY.equalToSuperview()
        }
        return view
    }

    private func initTimeLabel() -> UILabel {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UDFont.systemFont(ofSize: 14)
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }

    private func initUserContentView(needBackgroundColor: Bool) -> DetailUserContentView {
        let config: DetailUserContentView.Config
        if needBackgroundColor {
            config = DetailUserContentView.Config(
                leftPadding: 2,
                rightPadding: 8,
                needBackgroundColor: true,
                backgroundCornerRadius: 14,
                height: 28
            )
        } else {
            config = DetailUserContentView.Config(
                leftPadding: 2,
                rightPadding: 0,
                needBackgroundColor: false
            )
        }
        let view = DetailUserContentView(config: config)
        view.onTapContentHandler = { [weak self] in
            guard let self = self else { return }
            self.actionDelegate?.onClick(self)
        }
        view.onTapIconHandler = { [weak self] in
            guard let self = self else { return }
            self.actionDelegate?.onClearMember(self)
        }
        return view
    }

    private func initNumberTextField() -> UDTextField {
        let field = UDTextField()
        field.config.textMargins = UIEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
        field.config.backgroundColor = UIColor.ud.udtokenComponentOutlinedBg
        field.config.font = UDFont.systemFont(ofSize: 14)
        field.config.textColor = UIColor.ud.textTitle
        field.setStatus(.activated)
        field.input.attributedPlaceholder = getFieldPlaceHolder()
        field.input.returnKeyType = .done
        field.input.keyboardType = .decimalPad
        field.input.delegate = self
        return field
    }

    private func getFieldPlaceHolder() -> NSAttributedString {
        NSAttributedString(
            string: "-",
            attributes: [
                .font: UDFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.ud.textPlaceholder
            ]
        )
    }

    @objc
    private func onClick() {
        actionDelegate?.onClick(self)
    }
}

extension DetailCustomFieldsContentCell: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        actionDelegate?.numberFieldShouldBeginEditing(self) ?? false
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        fieldView.config.isShowBorder = true
        fieldView.input.attributedPlaceholder = nil
        actionDelegate?.onNumberFieldBeginEditing(self)

        guard let data = viewData,
              case .number(var rawString, _, _) = data.customType else {
            assertionFailure()
            return
        }

        // 百分比类型的特化
        if data.assoc.taskField.settings.numberFieldSettings.format == .percentage,
           let doubleVal = Double(rawString),
           let stringVal = DetailCustomFields.double2String(
            doubleVal * 100,
            decimalCount: data.assoc.taskField.settings.numberFieldSettings.decimalCount
        ) {
            rawString = stringVal
        }

        replaceAllText(rawString, textField)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        fieldView.config.isShowBorder = false
        fieldView.input.attributedPlaceholder = getFieldPlaceHolder()

        guard let data = viewData,
              case .number(_, let rawDouble, let settings) = data.customType,
              var text = textField.text else {
            assertionFailure()
            actionDelegate?.onNumberFieldEndEditing(content: nil, data: nil)
            return
        }

        // 清空时单独处理
        if text.isEmpty {
            actionDelegate?.onNumberFieldEndEditing(content: "", data: data)
            return
        }

        // 百分比类型的特化
        if data.assoc.taskField.settings.numberFieldSettings.format == .percentage,
           let doubleVal = Double(text),
           let stringVal = DetailCustomFields.double2String(
            doubleVal / 100,
            decimalCount: data.assoc.taskField.settings.numberFieldSettings.decimalCount + 2
        ) {
            text = stringVal
        }

        guard let doubleVal = Double(text) else {
            if let text = DetailCustomFields.double2String(rawDouble ?? 0, settings: settings) {
                replaceAllText(text, textField)
            }
            actionDelegate?.onNumberFieldEndEditing(content: nil, data: data)
            return
        }

        actionDelegate?.onNumberFieldEndEditing(content: text, data: data)
        guard let presentText = DetailCustomFields.double2String(doubleVal, settings: settings) else {
            assertionFailure()
            return
        }
        replaceAllText(presentText, textField)
    }

    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        // Handle backspace/delete
        guard !string.isEmpty else {
            return true
        }

        guard CharacterSet(charactersIn: "0123456789.")
            .isSuperset(of: CharacterSet(charactersIn: string)) else {
            return false
        }

        if let text = textField.text, let range = Range(range, in: text) {
            let proposedText = text.replacingCharacters(in: range, with: string)
            if proposedText.count > 20 || Double(proposedText) == nil {
                return false
            }
        }

        return true
    }

    private func replaceAllText(_ text: String, _ textField: UITextField) {
        guard let range = textField.textRange(
            from: textField.beginningOfDocument,
            to: textField.endOfDocument
        ) else {
            assertionFailure()
            return
        }
        textField.replace(range, withText: text)
    }
}

final class DetailCustomFieldTextMoreView: UIView {

    var shouldShow: Bool = false {
        didSet {
            self.isHidden = !shouldShow
        }
    }

    var onShowTap: (() -> Void)?

    private lazy var label: UILabel = {
        let label = UILabel()
        label.font = UDFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.primaryContentDefault
        label.text = I18N.Todo_Task_ShowMore
        label.textAlignment = .right
        return label
    }()

    private lazy var gradient: GradientView = {
        let gradient = GradientView()
        gradient.backgroundColor = UIColor.clear
        gradient.colors = [
            UIColor.ud.bgBody.withAlphaComponent(1.0),
            UIColor.ud.bgBody.withAlphaComponent(0.0)
        ]
        gradient.locations = [1.0, 0.0]
        gradient.direction = .vertical
        return gradient
    }()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        addSubview(gradient)
        addSubview(label)
        gradient.snp.makeConstraints { make in
            make.height.equalTo(100)
            make.edges.equalToSuperview()
        }
        label.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-8)
            make.bottom.equalToSuperview().offset(-6)
            make.height.equalTo(22)
            make.left.equalToSuperview()
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(clickBtn))
        addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func clickBtn() {
        onShowTap?()
    }

}
