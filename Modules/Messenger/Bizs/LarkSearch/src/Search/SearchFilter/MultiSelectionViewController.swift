//
//  ChatTypeFilterViewController.swift
//  LarkSearch
//
//  Created by SuPeng on 9/12/19.
//

import Foundation
import UIKit
import LarkUIKit
import LarkModel
import LarkSearchFilter
import LarkSDKInterface
import LarkFeatureGating
import LarkSearchCore

protocol SearchFilterMultiSelection {
    var title: String { get }
    var availableItems: [SearchFilterItem] { get }
    var selectedItems: [SearchFilterItem] { get }
}

struct GeneralMultiFilterType: SearchFilterItem {
    let name: String
    let id: String
    func equal(to item: SearchFilterItem?) -> Bool {
        guard let other = item, let other = other as? GeneralMultiFilterType else { return false }
        return self.id == other.id
    }
}

final class GeneralMultiSelection: SearchFilterMultiSelection {
    let title: String
    let availableItems: [SearchFilterItem]
    var selectedItems: [SearchFilterItem]

    init(title: String, availableItems: [SearchFilterItem], selectedItems: [SearchFilterItem]) {
        self.title = title
        self.availableItems = availableItems
        self.selectedItems = selectedItems
    }
}

// ChatFilterType
extension ChatFilterType: SearchFilterItem {
    func equal(to other: SearchFilterItem?) -> Bool {
        guard let otherType = other, let otherType = otherType as? ChatFilterType else { return false }
        return self == otherType
    }
}

final class ChatFilterSelection: SearchFilterMultiSelection {
    var title: String {
        return BundleI18n.LarkSearch.Lark_Search_SearchGroupByGroupType
    }

    var availableItems: [SearchFilterItem] {
        return ChatFilterType.allCases.filter { $0 != .unknowntab }
    }

    var selectedItems: [SearchFilterItem] {
        return defaultTypes
    }

    private let defaultTypes: [ChatFilterType]
    init(defaultTypes: [ChatFilterType]) {
        self.defaultTypes = defaultTypes
    }

}

// DocFormat

extension DocFormatType: SearchFilterItem {
    var name: String { title }

    func equal(to other: SearchFilterItem?) -> Bool {
        guard let otherType = other, let otherType = otherType as? DocFormatType else { return false }
        return self == otherType
    }

}

final class DocTypeFilterSelection: SearchFilterMultiSelection {
    var title: String {
        return BundleI18n.LarkSearch.Lark_Search_DocFormat
    }

    var availableItems: [SearchFilterItem] {
        var types = DocFormatType.allCases.filter { $0 != .all && $0 != .slide }
        let enableMindnote = SearchFeatureGatingKey.docMindNoteFilter.isEnabled
        let enableBitable = SearchFeatureGatingKey.bitableFilter.isEnabled
        let enableNewSlides = SearchFeatureGatingKey.docNewSlides.isEnabled
        if !enableMindnote {
            types.lf_remove(object: .mindNote)
        }
        if !enableBitable {
            types.lf_remove(object: .bitale)
        }
        if !enableNewSlides {
            types.lf_remove(object: .slides)
        }
        return types
    }

    var selectedItems: [SearchFilterItem] {
        return defaultTypes
    }

    private let defaultTypes: [DocFormatType]
    init(defaultTypes: [DocFormatType]) {
        self.defaultTypes = defaultTypes
    }

}

// Message Match

extension SearchFilter.MessageContentMatchType: SearchFilterItem {
    func equal(to other: SearchFilterItem?) -> Bool {
        guard let otherType = other, let otherType = otherType as? SearchFilter.MessageContentMatchType else { return false }
        return self == otherType
    }
}

final class MessageContentMatchSelection: SearchFilterMultiSelection {
    var title: String {
        return BundleI18n.LarkSearch.Lark_MessageSearch_MatchObject
    }

    var availableItems: [SearchFilterItem] {
        return SearchFilter.MessageContentMatchType.allCases
    }

    var selectedItems: [SearchFilterItem] {
        return defaultTypes
    }

    private let defaultTypes: [SearchFilter.MessageContentMatchType]
    init(defaultTypes: [SearchFilter.MessageContentMatchType]) {
        self.defaultTypes = defaultTypes
    }
}

final class MultiSelectionViewController: BaseUIViewController, PresentWithFadeAnimatorVC, UIViewControllerTransitioningDelegate, UIGestureRecognizerDelegate {
    var didSelecteItems: (([SearchFilterItem], UIViewController) -> Void)?

    private let selection: SearchFilterMultiSelection
    lazy var colorBgView = UIView()
    lazy var contentView = UIView()
    private lazy var titleLabel = UILabel()
    private lazy var stackView = UIStackView()
    private lazy var scrollView = UIScrollView()
    private lazy var cancelButton = ExpandRangeButton()
    private lazy var confirmButton = ExpandRangeButton()
    private lazy var groupView = UIView()
    private lazy var maskView = UIView()
    /// 模态框，ipad上使用. iPhone上还是在底部展示
    private let isModeled: Bool

    init(selection: SearchFilterMultiSelection, isModeled: Bool = false) {
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
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: confirmTitle(for: selection.selectedItems.count), style: UIBarButtonItem.Style.done,
            target: self, action: #selector(sureButtonDidClick)
            )
        self.navigationItem.rightBarButtonItem?.tintColor = UIColor.ud.primaryContentDefault

        self.view.addSubview(scrollView)
        scrollView.addSubview(stackView)
        scrollView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        configStackItems { (self, count) in
            self.navigationItem.rightBarButtonItem?.title = self.confirmTitle(for: count)
        }
    }

    func unModeledDisplay() {
        view.backgroundColor = UIColor.clear

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapDidInvoke))
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)

        view.addSubview(colorBgView)
        view.addSubview(contentView)
        contentView.addSubview(groupView)

        groupView.addSubview(titleLabel)
        groupView.addSubview(maskView)
        groupView.addSubview(cancelButton)
        groupView.addSubview(confirmButton)

        maskView.addSubview(scrollView)
        scrollView.addSubview(stackView)
        scrollView.snp.makeConstraints { (make) in
            make.top.left.right.bottom.equalToSuperview()
        }

        colorBgView.backgroundColor = UIColor.ud.bgMask
        colorBgView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        groupView.backgroundColor = UIColor.ud.bgFloat
        groupView.roundCorners(corners: [.topLeft, .topRight], radius: 16.0)
        groupView.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview()
            make.top.equalToSuperview().inset(238).priority(.low)
            make.width.equalToSuperview()
        }

        titleLabel.text = selection.title
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(14)
            make.centerX.equalToSuperview()
        }

        maskView.backgroundColor = UIColor.ud.bgBody
        maskView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().inset(56)
            make.bottom.equalToSuperview()
        }

        configStackItems { (_, _) in
        }

        cancelButton.addTarget(self, action: #selector(cancelButtonDidClick), for: .touchUpInside)
        cancelButton.setImage(Resources.chat_filter_close.withRenderingMode(.alwaysTemplate), for: .normal)
        cancelButton.tintColor = UIColor.ud.iconN1
        cancelButton.addedTouchArea = 14
        cancelButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(titleLabel)
            make.left.equalToSuperview().inset(16)
        }

        confirmButton.addTarget(self, action: #selector(sureButtonDidClick), for: .touchUpInside)
        confirmButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        confirmButton.setTitle(confirmTitle(for: selection.selectedItems.count), for: .normal)
        confirmButton.setTitleColor(UIColor.ud.primaryContentDefault.withAlphaComponent(0.6), for: .disabled)
        confirmButton.setTitleColor(UIColor.ud.primaryContentDefault.withAlphaComponent(0.6), for: .highlighted)
        confirmButton.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        confirmButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        confirmButton.contentHorizontalAlignment = .right
        confirmButton.setTitle(BundleI18n.LarkSearch.Lark_Legacy_Sure, for: .normal)
        confirmButton.sizeToFit()
        confirmButton.addedTouchArea = 16
        confirmButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(titleLabel)
            make.right.equalToSuperview().inset(16)
        }
    }

    func confirmTitle(for count: Int) -> String {
        if count > 0 { // swiftlint:disable:this all
            return "\(BundleI18n.LarkSearch.Lark_Legacy_Sure)(\(count))"
        } else {
            return BundleI18n.LarkSearch.Lark_Legacy_Sure
        }
    }

    func configStackItems(change: @escaping (MultiSelectionViewController, Int) -> Void) {
        stackView.axis = .vertical
        // should already add to superview
        stackView.snp.makeConstraints { (make) in
            make.top.left.bottom.equalToSuperview()
        }

        selection.availableItems
            .forEach { (item) in
                let button = MultiSelectionButton(item: item, isSelected: selection.selectedItems.contains(where: { $0.equal(to: item) }))
                button.selectedDidChange = { [weak self] _ in
                    guard let self = self else { return }
                    let selectedButtons = self.stackView.arrangedSubviews
                        .compactMap { $0 as? MultiSelectionButton }
                        .filter { $0.isSelected }

                    change(self, selectedButtons.count)
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
    private func sureButtonDidClick() {
        let selectedTypes = stackView.arrangedSubviews
            .compactMap { $0 as? MultiSelectionButton }
            .compactMap { $0.isSelected ? $0.item : nil }
        didSelecteItems?(selectedTypes, self)
    }
    // MARK: - UIViewControllerTransitioningDelegate
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PresentWithFadeAnimator()
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DismissWithFadeAnimator()
    }
}

private final class MultiSelectionButton: UIControl {
    var selectedDidChange: ((MultiSelectionButton) -> Void)?
    let item: SearchFilterItem
    private let checkBox = Checkbox()
    private let titleLabel = UILabel()

    init(item: SearchFilterItem, isSelected: Bool) {
        self.item = item
        super.init(frame: .zero)
        self.isSelected = isSelected
        self.backgroundColor = .ud.bgBody

        checkBox.isEnabled = false
        checkBox.lineWidth = 1.5
        checkBox.onCheckColor = UIColor.ud.primaryOnPrimaryFill
        checkBox.onFillColor = UIColor.ud.primaryContentDefault
        checkBox.offFillColor = UIColor.clear
        checkBox.strokeColor = UIColor.ud.lineBorderComponent
        checkBox.setOn(on: isSelected)
        addSubview(checkBox)
        checkBox.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 24, height: 24))
            make.left.equalTo(12)
            make.centerY.equalToSuperview()
        }

        titleLabel.text = item.name
        titleLabel.font = UIFont.systemFont(ofSize: 17)
        titleLabel.textColor = UIColor.ud.textTitle
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(checkBox.snp.right).offset(14.5)
            make.centerY.equalToSuperview()
        }

        lu.addBottomBorder(leading: 50, color: UIColor.ud.lineDividerDefault)

        addTarget(self, action: #selector(didClick), for: .touchUpInside)

        snp.makeConstraints { (make) in
            make.height.equalTo(62)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func didClick() {
        isSelected = !isSelected
        checkBox.setOn(on: isSelected)
        selectedDidChange?(self)
    }
}
