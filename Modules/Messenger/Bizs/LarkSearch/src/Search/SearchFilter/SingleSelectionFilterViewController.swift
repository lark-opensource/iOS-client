//
//  SingleSelectionFilterViewController.swift
//  LarkSearch
//
//  Created by ZhangHongyun on 2021/3/11.
//

import Foundation
import UIKit
import LarkUIKit
import LarkModel
import LarkSearchFilter
import LarkSDKInterface
import LarkFeatureGating
import UniverseDesignIcon
import LarkSearchCore
import ServerPB
import LarkContainer

protocol SearchFilterItem {
    var name: String { get }
    func equal(to item: SearchFilterItem?) -> Bool
}

protocol SearchFilterSingleSelection {
    var title: String { get }
    var availableItems: [SearchFilterItem] { get }
    var selectedItem: SearchFilterItem? { get }
}

struct GeneralSingleFilterType: SearchFilterItem {
    let name: String
    let id: String
    func equal(to item: SearchFilterItem?) -> Bool {
        guard let other = item, let other = other as? GeneralSingleFilterType else { return false }
        return self.id == other.id
    }
    init(name: String, id: String) {
        self.name = name
        self.id = id
    }
    init?(value: SearchFilter.GeneralFilter.Option?) {
        guard let value = value,
              case let .predefined(info) = value else { return nil }
        self.id = info.id
        self.name = info.name
    }
}

final class GeneralSinleSelection: SearchFilterSingleSelection {
    let title: String
    let availableItems: [SearchFilterItem]
    var selectedItem: SearchFilterItem?

    init(title: String, availableItems: [SearchFilterItem], selectedItem: SearchFilterItem?) {
        self.title = title
        self.availableItems = availableItems
        self.selectedItem = selectedItem
    }
}

extension SearchFilterSingleSelection {
    var hasSelectedItem: Bool {
        return selectedItem != nil
    }
}

// MessageFilterType

extension MessageFilterType: SearchFilterItem {
    func equal(to other: SearchFilterItem?) -> Bool {
        guard let otherType = other, let otherType = otherType as? MessageFilterType else { return false }
        return self == otherType
    }
}

extension MessageAttachmentFilterType: SearchFilterItem {
    func equal(to other: SearchFilterItem?) -> Bool {
        guard let otherType = other, let otherType = otherType as? MessageAttachmentFilterType else { return false }
        return self == otherType
    }
}

final class MessageSelection: SearchFilterSingleSelection {

    var title: String {
        return BundleI18n.LarkSearch.Lark_MessageSearch_TypeOfMessage
    }

    var availableItems: [SearchFilterItem] {
        return MessageFilterType.allCases.filter { (type) -> Bool in
            if !searchFile {
                return type != .file && type != .all
            }
            return type != .all
        }
    }

    var selectedItem: SearchFilterItem? {
        return selectedType != .all ? selectedType : selectedType
    }
    let userResovler: UserResolver
    private let selectedType: MessageFilterType
    private var searchFile: Bool

    init(userResolver: UserResolver, selectedType: MessageFilterType) {
        self.userResovler = userResolver
        self.selectedType = selectedType
        searchFile = SearchFeatureGatingKey.searchFile.isUserEnabled(userResolver: userResolver)
    }

}

final class MessageAttachmentSelection: SearchFilterSingleSelection {

    var title: String {
        return BundleI18n.LarkSearch.Lark_MessageSearch_TypeOfMessage
    }

    var availableItems: [SearchFilterItem] {
        return MessageAttachmentFilterType.allCases.filter { (type) -> Bool in
            return type != .unknownAttachmentType
        }
    }

    var selectedItem: SearchFilterItem? {
        return selectedType != .unknownAttachmentType ? selectedType : selectedType
    }

    private let selectedType: MessageAttachmentFilterType

    init(selectedType: MessageAttachmentFilterType) {
        self.selectedType = selectedType
    }

}

// docType

extension SearchFilter.DocType: SearchFilterItem {
    func equal(to other: SearchFilterItem?) -> Bool {
        guard let otherType = other, let otherType = otherType as? SearchFilter.DocType else { return false }
        return self == otherType
    }
}

final class DocTypeSelection: SearchFilterSingleSelection {
    var title: String {
        return SearchFilter.DocType.all.name
    }

    var availableItems: [SearchFilterItem] {
        return SearchFilter.DocType.allCases.filter { (type) -> Bool in
            return type != .all
        }
    }

    var selectedItem: SearchFilterItem? {
        return selectedType != .all ? selectedType : selectedType
    }

    private let selectedType: SearchFilter.DocType

    init(selectedType: SearchFilter.DocType) {
        self.selectedType = selectedType
    }
}

// Doc Content

extension DocContentType: SearchFilterItem {
    func equal(to other: SearchFilterItem?) -> Bool {
        guard let otherType = other, let otherType = otherType as? DocContentType else { return false }
        return self == otherType
    }
}

final class DocContentSelection: SearchFilterSingleSelection {
    var title: String {
        return DocContentType.fullContent.name
    }

    var availableItems: [SearchFilterItem] {
        return DocContentType.allCases.filter { (type) -> Bool in
            return type != .fullContent
        }
    }

    var selectedItem: SearchFilterItem? {
        return selectedType != .fullContent ? selectedType : selectedType
    }

    private let selectedType: DocContentType

    init(selectedType: DocContentType) {
        self.selectedType = selectedType
    }
}

/// MessageChatType
extension SearchFilter.MessageChatFilterType: SearchFilterItem {
    func equal(to other: SearchFilterItem?) -> Bool {
        guard let otherType = other, let otherType = otherType as? SearchFilter.MessageChatFilterType else { return false }
        return self == otherType
    }
}

final class ChatTypeSelection: SearchFilterSingleSelection {
    var title: String {
        return SearchFilter.MessageChatFilterType.all.name
    }

    var availableItems: [SearchFilterItem] {
        return SearchFilter.MessageChatFilterType.allCases.filter { (type) -> Bool in
            return type != .all
        }
    }

    var selectedItem: SearchFilterItem? {
        return selectedType != .all ? selectedType : selectedType
    }

    private let selectedType: SearchFilter.MessageChatFilterType

    init(selectedType: SearchFilter.MessageChatFilterType) {
        self.selectedType = selectedType
    }
}
// DocSortType

extension SearchFilter.DocSortType: SearchFilterItem {
    func equal(to other: SearchFilterItem?) -> Bool {
        guard let otherType = other, let otherType = otherType as? SearchFilter.DocSortType else { return false }
        return self == otherType
    }
}

final class DocSortTypeSelection: SearchFilterSingleSelection {
    var title: String {
        return SearchFilter.DocSortType.mostRelated.title
    }

    var availableItems: [SearchFilterItem] {
        return SearchFilter.DocSortType.allCases
    }

    var selectedItem: SearchFilterItem? {
        return selectedType
    }

    private let selectedType: SearchFilter.DocSortType

    init(selectedType: SearchFilter.DocSortType) {
        self.selectedType = selectedType
    }
}

// GroupSortType

extension SearchFilter.GroupSortType: SearchFilterItem {
    func equal(to other: SearchFilterItem?) -> Bool {
        guard let otherType = other, let otherType = otherType as? SearchFilter.GroupSortType else { return false }
        return self == otherType
    }
}

final class GroupSortTypeSelection: SearchFilterSingleSelection {
    var title: String {
        return SearchFilter.GroupSortType.mostRelated.title
    }

    var availableItems: [SearchFilterItem] {
        return SearchFilter.GroupSortType.allCases.filter { (type) -> Bool in
            if !SearchFeatureGatingKey.groupSortUpdatedTime.isEnabled {
                return type != .mostRecentUpdated
            }
            return true
        }
    }

    var selectedItem: SearchFilterItem? {
        return selectedType
    }

    private let selectedType: SearchFilter.GroupSortType

    init(selectedType: SearchFilter.GroupSortType) {
        self.selectedType = selectedType
    }
}

final class SingleSelectionFilterViewController: BaseUIViewController, PresentWithFadeAnimatorVC, UIViewControllerTransitioningDelegate, UIGestureRecognizerDelegate {
    var didSelectType: ((SearchFilterItem?, UIViewController) -> Void)?

    private let selection: SearchFilterSingleSelection
    let colorBgView = UIView()
    let contentView = UIView()
    private let titleLabel = UILabel()
    private let stackView = UIStackView()
    private lazy var scrollView = UIScrollView()
    private let cancelButton = ExpandRangeButton()
    private let groupView = UIView()
    private let maskView = UIView()
    /// 模态框，ipad上使用. iPhone上还是在底部展示
    private let isModeled: Bool

    private lazy var resetButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.setTitle(BundleI18n.LarkSearch.Lark_Chat_ClearText, for: .normal)
        button.setTitleColor(.ud.textTitle, for: .normal)
        button.setTitleColor(.ud.textDisabled, for: .disabled)
        button.addTarget(self, action: #selector(resetButtonDidClick), for: .touchUpInside)
        return button
    }()

    init(selection: SearchFilterSingleSelection, isModeled: Bool = false) {
        self.selection = selection
        self.isModeled = isModeled

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = selection.title

        setResetButtonStatus()

        if isModeled {
            modeledDisplay()
        } else {
            unModeledDisplay()
        }
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        stackView.snp.makeConstraints { make in
            make.width.equalTo(view.frame.width)
        }
        stackView.layoutIfNeeded()
        scrollView.contentSize = CGSize(width: view.frame.width, height: stackView.frame.height + (self.isModeled ? 0 : 44))
        if !isModeled {
            scrollView.snp.remakeConstraints { make in
                make.bottom.leading.trailing.equalToSuperview()
                make.height.equalTo(stackView.frame.height + (self.isModeled ? 0 : 44)).priority(.low)
                make.top.greaterThanOrEqualToSuperview().priority(.high)
            }
            groupView.snp.remakeConstraints { make in
                make.height.equalTo(scrollView.snp.height).offset(56).priority(.medium)
                make.top.greaterThanOrEqualToSuperview().inset(238).priority(.high)
                make.bottom.equalToSuperview()
                make.width.equalToSuperview()
            }
        }
    }
    func modeledDisplay() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: Resources.chat_filter_close.withRenderingMode(.alwaysTemplate), style: UIBarButtonItem.Style.plain,
            target: self, action: #selector(cancelButtonDidClick))
        self.navigationItem.leftBarButtonItem?.tintColor = UIColor.ud.iconN1
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: resetButton)
        resetButton.isEnabled = selection.hasSelectedItem
        self.view.addSubview(scrollView)
        scrollView.addSubview(stackView)
        scrollView.snp.makeConstraints { (make) in
            make.top.left.right.bottom.equalToSuperview()
        }
        configStackItems()
    }

    func unModeledDisplay() {
        view.backgroundColor = UIColor.clear

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapDidInvoke))
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)

        colorBgView.backgroundColor = UIColor.ud.bgMask
        view.addSubview(colorBgView)
        colorBgView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        view.addSubview(contentView)
        contentView.snp.makeConstraints { (make) in
            make.size.equalTo(view.bounds.size)
            make.left.equalTo(0)
            make.top.equalTo(view.snp.top)
        }

        groupView.backgroundColor = UIColor.ud.bgFloat
        contentView.addSubview(groupView)
        groupView.roundCorners(corners: [.topLeft, .topRight], radius: 16.0)
        groupView.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview()
            make.top.equalToSuperview().inset(238).priority(.low)
            make.width.equalToSuperview()
        }

        groupView.addSubview(titleLabel)
        titleLabel.text = selection.title
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(14)
            make.centerX.equalToSuperview()
        }

        groupView.addSubview(maskView)
        maskView.backgroundColor = UIColor.ud.bgBody
        maskView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().inset(56)
            make.bottom.equalToSuperview()
        }

        maskView.addSubview(scrollView)
        scrollView.addSubview(stackView)
        scrollView.snp.makeConstraints { (make) in
            make.top.left.right.bottom.equalToSuperview()
        }
        configStackItems()

        groupView.addSubview(cancelButton)
        groupView.addSubview(resetButton)
        cancelButton.addTarget(self, action: #selector(cancelButtonDidClick), for: .touchUpInside)
        cancelButton.setImage(Resources.chat_filter_close.withRenderingMode(.alwaysTemplate), for: .normal)
        cancelButton.tintColor = UIColor.ud.iconN1
        cancelButton.addedTouchArea = 14
        cancelButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(titleLabel)
            make.left.equalToSuperview().inset(16)
        }
        resetButton.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.right.equalToSuperview().inset(16)
        }
        resetButton.isEnabled = selection.hasSelectedItem
    }

    private func setResetButtonStatus() {
        switch self.selection {
        case is DocSortTypeSelection: resetButton.isHidden = true
        case is GroupSortTypeSelection: resetButton.isHidden = true
        default: resetButton.isHidden = false
        }
    }

    func configStackItems() {
        stackView.axis = .vertical
        // should already add to superview
        stackView.isUserInteractionEnabled = true
        stackView.snp.makeConstraints { (make) in
            make.top.left.bottom.equalToSuperview()
        }

        selection.availableItems
        .forEach { (item) in
            let button = SingleSelectionButton(item: item, isSelected: item.equal(to: selection.selectedItem))
            button.selectedDidChange = { [weak self] button in
                guard let self = self else { return }
                self.stackView.arrangedSubviews.forEach { (cell) in
                    if let cell = cell as? SingleSelectionButton {
                        cell.setStatus(selected: false)
                    }
                }
                button.setStatus(selected: true)
                self.resetButton.isEnabled = self.selection.hasSelectedItem
                self.didSelectType?(button.item, self)
            }
            stackView.addArrangedSubview(button)
        }
    }

    @objc
    private func backgroundTapDidInvoke() {
        dismiss(animated: true, completion: nil)
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let location = gestureRecognizer.location(in: contentView)
        if groupView.frame.contains(location) {
            return false
        } else {
            return true
        }
    }

    @objc
    private func cancelButtonDidClick() {
        self.dismiss(animated: true, completion: nil)
    }

    @objc
    private func resetButtonDidClick() {
        didSelectType?(nil, self)
        self.dismiss(animated: true, completion: nil)
    }

    // MARK: - UIViewControllerTransitioningDelegate
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PresentWithFadeAnimator()
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DismissWithFadeAnimator()
    }
}

private final class SingleSelectionButton: UIControl {
    var selectedDidChange: ((SingleSelectionButton) -> Void)?
    let item: SearchFilterItem
    private let selectIcon = UIImageView()
    private let titleLabel = UILabel()

    init(item: SearchFilterItem, isSelected: Bool) {
        self.item = item
        super.init(frame: .zero)
        self.isSelected = isSelected
        self.backgroundColor = .ud.bgBody

        self.selectIcon.image = UDIcon.getIconByKey(.doneOutlined, size: CGSize(width: 18, height: 18)).ud.withTintColor(UIColor.ud.colorfulBlue)
        self.selectIcon.isHidden = true
        addSubview(self.selectIcon)
        self.selectIcon.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalTo(-16)
        }
        setStatus(selected: isSelected)

        titleLabel.text = item.name
        titleLabel.font = UIFont.systemFont(ofSize: 17)
        titleLabel.textColor = UIColor.ud.textTitle
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }

        lu.addBottomBorder(leading: 50, color: UIColor.ud.lineDividerDefault)

        addTarget(self, action: #selector(didClick), for: .touchUpInside)

        snp.makeConstraints { (make) in
            make.height.equalTo(62)
        }
    }
    func setStatus(selected: Bool) {
        selectIcon.isHidden = !selected
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func didClick() {
        isSelected = !isSelected
        selectIcon.isHidden = !isSelected
        selectedDidChange?(self)
    }
}
