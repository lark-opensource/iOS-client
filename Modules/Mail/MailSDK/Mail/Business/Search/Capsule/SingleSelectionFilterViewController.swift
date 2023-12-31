//
//  SingleSelectionFilterViewController.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2023/11/18.
//

import Foundation
import UIKit
import LarkUIKit
import LarkModel
//import LarkSDKInterface
//import LarkFeatureGating
import UniverseDesignIcon
//import LarkSearchCore

protocol SearchFilterItem {
    var name: String { get }
    func equal(to item: SearchFilterItem?) -> Bool
}

//protocol SearchFilterSingleSelection {
//    var title: String { get }
//    var availableItems: [SearchFilterItem] { get }
//    var selectedItem: SearchFilterItem? { get }
//}

protocol SearchFilterMultiSelection {
    var title: String { get }
    var availableItems: [SearchFilterItem] { get }
    var selectedItems: [SearchFilterItem] { get }
}


//extension SearchFilterSingleSelection {
//    var hasSelectedItem: Bool {
//        return selectedItem != nil
//    }
//}

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

struct GeneralMultiFilterType: SearchFilterItem {
    let name: String
    let id: String
    func equal(to item: SearchFilterItem?) -> Bool {
        guard let other = item, let other = other as? GeneralMultiFilterType else { return false }
        return self.id == other.id
    }
}



// MessageFilterType

//extension MessageFilterType: SearchFilterItem {
//    func equal(to other: SearchFilterItem?) -> Bool {
//        guard let otherType = other, let otherType = otherType as? MessageFilterType else { return false }
//        return self == otherType
//    }
//}

//final class MessageSelection: SearchFilterSingleSelection {
//
//    var title: String {
//        return BundleI18n.LarkSearch.Lark_MessageSearch_TypeOfMessage
//    }
//
//    var availableItems: [SearchFilterItem] {
//        return MessageFilterType.allCases.filter { (type) -> Bool in
//            if !searchFile {
//                return type != .file && type != .all
//            }
//            return type != .all
//        }
//    }
//
//    var selectedItem: SearchFilterItem? {
//        return selectedType != .all ? selectedType : selectedType
//    }
//
//    private let selectedType: MessageFilterType
//    @FeatureGating(.searchFile) private var searchFile: Bool
//
//    init(selectedType: MessageFilterType) {
//        self.selectedType = selectedType
//    }
//
//}

// docType

//extension SearchFilter.DocType: SearchFilterItem {
//    func equal(to other: SearchFilterItem?) -> Bool {
//        guard let otherType = other, let otherType = otherType as? SearchFilter.DocType else { return false }
//        return self == otherType
//    }
//}


// GroupSortType

//extension SearchFilter.GroupSortType: SearchFilterItem {
//    func equal(to other: SearchFilterItem?) -> Bool {
//        guard let otherType = other, let otherType = otherType as? SearchFilter.GroupSortType else { return false }
//        return self == otherType
//    }
//}

//final class GroupSortTypeSelection: SearchFilterSingleSelection {
//    var title: String {
//        return SearchFilter.GroupSortType.mostRelated.title
//    }
//
//    var availableItems: [SearchFilterItem] {
//        return SearchFilter.GroupSortType.allCases.filter { (type) -> Bool in
//            if !SearchFeatureGatingKey.groupSortUpdatedTime.isEnabled {
//                return type != .mostRecentUpdated
//            }
//            return true
//        }
//    }
//
//    var selectedItem: SearchFilterItem? {
//        return selectedType
//    }
//
//    private let selectedType: SearchFilter.GroupSortType
//
//    init(selectedType: SearchFilter.GroupSortType) {
//        self.selectedType = selectedType
//    }
//}

final class MultiSelectionViewController: BaseUIViewController, PresentWithFadeAnimatorVC, UIViewControllerTransitioningDelegate, UIGestureRecognizerDelegate {
    var didSelecteItems: (([SearchFilterItem], UIViewController) -> Void)?

    private let selection: SearchFilterMultiSelection
    lazy var colorBgView = UIView()
    lazy var contentView = UIView()
    private lazy var titleLabel = UILabel()
    private lazy var stackView = UIStackView()
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

    func modeledDisplay() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UDIcon.closeSmallOutlined.withRenderingMode(.alwaysTemplate), style: UIBarButtonItem.Style.plain,
            target: self, action: #selector(cancelButtonDidClick))
        self.navigationItem.leftBarButtonItem?.tintColor = UIColor.ud.iconN1
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: confirmTitle(for: selection.selectedItems.count), style: UIBarButtonItem.Style.done,
            target: self, action: #selector(sureButtonDidClick)
            )
        self.navigationItem.rightBarButtonItem?.tintColor = UIColor.ud.primaryPri500

        self.view.addSubview(stackView)
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

        maskView.addSubview(stackView)

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
        let bottomOffset = UIView()
        maskView.addSubview(bottomOffset)
        bottomOffset.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(stackView.snp.bottom)
            make.height.equalTo(44)
        }

        configStackItems { (_, _) in
        }

        cancelButton.addTarget(self, action: #selector(cancelButtonDidClick), for: .touchUpInside)
        cancelButton.setImage(UDIcon.closeSmallOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        cancelButton.tintColor = UIColor.ud.iconN1
        cancelButton.addedTouchArea = 14
        cancelButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(titleLabel)
            make.left.equalToSuperview().inset(16)
        }

        confirmButton.addTarget(self, action: #selector(sureButtonDidClick), for: .touchUpInside)
        confirmButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        confirmButton.setTitle(confirmTitle(for: selection.selectedItems.count), for: .normal)
        confirmButton.setTitleColor(UIColor.ud.primaryPri500.withAlphaComponent(0.6), for: .disabled)
        confirmButton.setTitleColor(UIColor.ud.primaryPri500.withAlphaComponent(0.6), for: .highlighted)
        confirmButton.setTitleColor(UIColor.ud.primaryPri500, for: .normal)
        confirmButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        confirmButton.contentHorizontalAlignment = .right
        confirmButton.setTitle(BundleI18n.MailSDK.Mail_Alert_Confirm, for: .normal)
        confirmButton.sizeToFit()
        confirmButton.addedTouchArea = 16
        confirmButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(titleLabel)
            make.right.equalToSuperview().inset(16)
        }
    }

    func confirmTitle(for count: Int) -> String {
        if count > 0 { // swiftlint:disable:this all
            return "\(BundleI18n.MailSDK.Mail_Alert_Confirm)(\(count))"
        } else {
            return BundleI18n.MailSDK.Mail_Alert_Confirm
        }
    }

    func configStackItems(change: @escaping (MultiSelectionViewController, Int) -> Void) {
        stackView.axis = .vertical
        // should already add to superview
        stackView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
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
        checkBox.onCheckColor = UIColor.ud.staticWhite
        checkBox.onFillColor = UIColor.ud.primaryPri500
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

final class ExpandRangeButton: UIButton {
    var addedTouchArea = CGFloat(0)

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {

        let newArea = CGRect(
            x: self.bounds.origin.x - addedTouchArea,
            y: self.bounds.origin.y - addedTouchArea,
            width: self.bounds.width + 2 * addedTouchArea,
            height: self.bounds.width + 2 * addedTouchArea
        )
        return newArea.contains(point)
    }
}

extension UIView {
    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        clipsToBounds = true
        layer.cornerRadius = radius
        layer.maskedCorners = CACornerMask(rawValue: corners.rawValue)
    }
}
