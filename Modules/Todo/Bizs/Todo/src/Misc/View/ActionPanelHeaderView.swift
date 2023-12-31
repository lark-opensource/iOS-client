//
//  ActionPanelHeaderView.swift
//  Todo
//
//  Created by wangwanxin on 2023/7/13.
//

import Foundation
import UniverseDesignIcon
import UniverseDesignFont

final class ActionPanelHeaderView: UIView {
    
    var onCloseHander: (() -> Void)?
    var onSaveHandler: (() -> Void)?

    struct Title {
        var center: String
        var right: String?
    }
    var title: Title? {
        didSet {
            titleLabel.text = title?.center
            if let title = title?.right {
                rightButton.isHidden = false
                rightButton.setTitle(title, for: .normal)
            } else {
                rightButton.isHidden = true
            }
        }
    }

    private var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UDFont.systemFont(ofSize: 17, weight: .medium)
        label.textColor = UIColor.ud.textTitle
        label.text = I18N.Todo_SectionSorting_Title
        label.textAlignment = .center
        return label
    }()

    private let leftButton: UIButton = {
        let btn = UIButton()
        let icon = UDIcon.getIconByKey(.closeSmallOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 24, height: 24))
        btn.setImage(icon, for: .normal)
        return btn
    }()

    private let rightButton: UIButton = {
        let btn = UIButton()
        btn.titleLabel?.font = UDFont.systemFont(ofSize: 16)
        btn.setTitle(I18N.Todo_SectionSortingSave_Button, for: .normal)
        btn.setTitleColor(UIColor.ud.textLinkNormal, for: .normal)
        return btn
    }()

    private lazy var separateLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.ud.bgFloatBase

        addSubview(leftButton)
        leftButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.height.width.equalTo(24)
            make.centerY.equalToSuperview()
        }

        addSubview(rightButton)
        rightButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        rightButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(leftButton.snp.right).offset(16)
            make.right.equalTo(rightButton.snp.left).offset(-16)
            make.centerY.equalToSuperview()
        }

        addSubview(separateLine)
        separateLine.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(CGFloat(1.0 / UIScreen.main.scale))
        }
        rightButton.addTarget(self, action: #selector(clickSave), for: .touchUpInside)
        leftButton.addTarget(self, action: #selector(clickClose), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func clickClose() {
        onCloseHander?()
    }

    @objc
    func clickSave() {
        onSaveHandler?()
    }

}

final class DetailPickerHeaderView: UIView {

    var onCloseHandler: (() -> Void)?
    var onConfirmHandler: (() -> Void)?

    private lazy var closeBtn: UIButton = {
        let btn = UIButton()
        let icon = UDIcon.getIconByKey(
            .closeSmallOutlined,
            iconColor: UIColor.ud.iconN1,
            size: CGSize(width: 24, height: 24)
        )
        btn.setImage(icon, for: .normal)
        btn.addTarget(self, action: #selector(closeBtnClick), for: .touchUpInside)
        return btn
    }()

    private lazy var title: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UDFont.systemFont(ofSize: 17, weight: .medium)
        label.numberOfLines = 1
        label.textAlignment = .center
        return label
    }()

    private lazy var subTitle: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textCaption
        label.font = UDFont.systemFont(ofSize: 10)
        label.numberOfLines = 1
        label.textAlignment = .center
        return label
    }()

    private lazy var confirmBtn: UIButton = {
        let btn = UIButton()
        btn.titleLabel?.font = UDFont.systemFont(ofSize: 16.0, weight: .regular)
        btn.isEnabled = true
        btn.tintColor = UIColor.ud.textDisabled
        btn.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        btn.addTarget(self, action: #selector(clickConfirm), for: .touchUpInside)
        return btn
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.ud.bgBody
        addSubview(closeBtn)
        addSubview(title)
        addSubview(subTitle)
        addSubview(confirmBtn)

        closeBtn.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.top.equalToSuperview().offset(10)
            make.left.equalToSuperview().offset(14)
        }

        title.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        title.snp.makeConstraints { make in
            make.height.equalTo(24)
            make.left.greaterThanOrEqualTo(closeBtn.snp.right).offset(16)
            make.top.equalToSuperview().offset(11)
            make.right.lessThanOrEqualTo(confirmBtn.snp.left).offset(-16)
            make.centerX.equalToSuperview().priority(.low)
        }

        subTitle.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        subTitle.snp.makeConstraints { make in
            make.height.equalTo(13)
            make.left.greaterThanOrEqualTo(closeBtn.snp.right).offset(16)
            make.top.equalTo(title.snp.bottom)
            make.right.lessThanOrEqualTo(confirmBtn.snp.left).offset(-16)
            make.centerX.equalToSuperview().priority(.low)
        }

        confirmBtn.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        confirmBtn.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func closeBtnClick() {
        onCloseHandler?()
    }

    @objc
    private func clickConfirm() {
        onConfirmHandler?()
    }

    func updateTitle(_ text: String, _ subText: String?, _ count: Int?) {
        title.text = text
        subTitle.isHidden = true
        if let subText = subText {
            subTitle.text = subText
            subTitle.isHidden = false
        }

        if !subTitle.isHidden {
            title.snp.updateConstraints { make in
                make.top.equalToSuperview().offset(3.5)
            }
        }
        confirmBtn.isHidden = true
        if let selectedNum = count {
            confirmBtn.isHidden = false
            let text: String
            if selectedNum >= 1 {
                text = "\(I18N.Todo_Task_Confirm)(\(selectedNum))"
                confirmBtn.isEnabled = true
                confirmBtn.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
                confirmBtn.tintColor = UIColor.ud.primaryContentDefault
            } else {
                text = I18N.Todo_Task_Confirm
                confirmBtn.isEnabled = false
                confirmBtn.setTitleColor(UIColor.ud.textDisabled, for: .disabled)
                confirmBtn.tintColor = UIColor.ud.textDisabled
            }
            confirmBtn.setTitle(text, for: .normal)
        }

    }

}

final class DetailPickerSearchBar: UIView {

    private let placeholder: String
    private lazy var containerView = UIView()

    private(set) lazy var searchBar: UISearchBar = {
        let search = UISearchBar()
        search.barTintColor = UIColor.ud.bgBody
        search.backgroundImage = UIImage()
        if #available(iOS 13.0, *) {
            search.searchTextField.backgroundColor = UIColor.ud.udtokenInputBgDisabled
            search.searchTextField.attributedPlaceholder = placeholdAttri
        } else {
            search.subviews.forEach { subView in
                subView.subviews.forEach { view in
                    if let textField = view as? UITextField {
                        textField.backgroundColor = UIColor.ud.udtokenInputBgDisabled
                        textField.attributedPlaceholder = placeholdAttri
                        return
                    }
                }
            }
        }
        return search
    }()

    init(with placeholder: String) {
        self.placeholder = placeholder
        super.init(frame: .zero)
        containerView.backgroundColor = UIColor.ud.bgBody
        addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        containerView.addSubview(searchBar)
        searchBar.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(-8)
            make.height.equalTo(38)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var placeholdAttri: NSAttributedString {
        var attrs = [NSAttributedString.Key: Any]()
        attrs[.font] = UDFont.systemFont(ofSize: 16)
        attrs[.foregroundColor] = UIColor.ud.textPlaceholder
        return NSAttributedString(string: placeholder, attributes: attrs)
    }

}
