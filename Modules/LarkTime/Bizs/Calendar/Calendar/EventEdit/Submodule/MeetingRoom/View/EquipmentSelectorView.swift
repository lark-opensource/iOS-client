//
//  EquipmentSelectorView.swift
//  Calendar
//
//  Created by zhuheng on 2021/2/4.
//

import UIKit
import Foundation
import LarkUIKit

protocol EquipmentSelectorViewDataType {
    var equipmentInfos: [(equipment: String, isSelected: Bool)] { get }
}

final class EquipmentSelectorView: UIView, ViewDataConvertible {
    var viewData: EquipmentSelectorViewDataType? {
        didSet {
            equipmentStackView.arrangedSubviews.forEach { (view) in
                view.removeFromSuperview()
                equipmentStackView.removeArrangedSubview(view)
            }
            equipmentItem.removeAll()

            if let itemDatas = viewData?.equipmentInfos {
                for i in 0..<itemDatas.count {
                    let itemData = itemDatas[i]
                    let item = Item(equipment: itemData.equipment, isSelected: itemData.isSelected)
                    equipmentItem.append(item)
                    item.itemTapped = { [weak self] () in
                        guard let self = self else { return }
                        self.equipmentTapped?(self.selectedIndexs)
                    }
                    equipmentStackView.addArrangedSubview(item)
                }
            }
        }
    }

    var equipmentTapped: ((_ selectedIndex: [Int]) -> Void)?
    private var selectedIndexs: [Int] {
        var indexs: [Int] = []
        for i in 0..<equipmentItem.count {
            let item = equipmentItem[i]
            if item.checkBox.isSelected {
                indexs.append(i)
            }
        }
        return indexs
    }
    private var equipmentItem: [Item] = []
    private lazy var equipmentStackView = initEquipmentStackView()
    private(set) lazy var backGroundView = initBackgourdView()
    private let containerView = UIView()

    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func reset() {
        equipmentItem.forEach { (item) in
            item.checkBox.isSelected = false
        }
    }

    func show() {
        isHidden = false
        UIView.animate(withDuration: 0.3) {
            self.containerView.snp.updateConstraints {
                $0.bottom.equalToSuperview().offset(12)
            }
            self.layoutIfNeeded()
        }
    }

    private func setupViews() {
        addSubview(backGroundView)
        backGroundView.snp.makeConstraints { $0.edges.equalToSuperview() }

        addSubview(containerView)
        containerView.backgroundColor = UIColor.ud.bgBody
        containerView.layer.cornerRadius = 12
        containerView.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.height.equalTo(359)
            $0.bottom.equalToSuperview().offset(12 + 359)
        }

        let indicateView = UIView()
        indicateView.backgroundColor = UIColor.ud.lineDividerDefault
        containerView.addSubview(indicateView)

        indicateView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(8)
            $0.height.equalTo(4)
            $0.width.equalTo(40)
        }
        indicateView.layer.cornerRadius = 2

        let resetButton = UIButton(type: .system)
        resetButton.setTitle(BundleI18n.Calendar.Calendar_EventSearch_Reset, for: .normal)
        resetButton.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        containerView.addSubview(resetButton)
        resetButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.equalTo(indicateView.snp.bottom).offset(5)
        }
        _ = resetButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                if !self.selectedIndexs.isEmpty {
                    self.equipmentTapped?([])
                    self.reset()
                }
            })

        let lineView = UIView()
        lineView.backgroundColor = UIColor.ud.lineDividerDefault
        containerView.addSubview(lineView)

        lineView.snp.makeConstraints {
            $0.left.equalToSuperview().offset(16)
            $0.top.equalTo(resetButton.snp.bottom).offset(5)
            $0.right.equalToSuperview()
            $0.height.equalTo(0.5)
        }

        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        containerView.addSubview(scrollView)
        scrollView.snp.makeConstraints {
            $0.top.equalTo(lineView.snp.bottom)
            $0.left.right.bottom.equalToSuperview()
        }

        scrollView.addSubview(equipmentStackView)
        equipmentStackView.snp.makeConstraints {
            $0.edges.width.equalToSuperview()
        }
    }

    private func initBackgourdView() -> UIView {
        let view = UIView()
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addTarget(self, action: #selector(backgroundTapped))
        view.backgroundColor = UIColor.ud.bgMask
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(tapGesture)
        return view
    }

    private func initEquipmentStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        return stackView
    }

    @objc private func backgroundTapped() {
        UIView.animate(withDuration: 0.3) {
            self.containerView.snp.updateConstraints {
                $0.bottom.equalToSuperview().offset(12 + 359)
            }
            self.layoutIfNeeded()
        } completion: { (_) in
            self.isHidden = true
        }
    }

}

/// Item：设备名 + 是否选中按钮
extension EquipmentSelectorView {
    final class Item: UIView {
        struct UIStyle {
            static let height = 48
        }

        var itemTapped: (() -> Void)?

        let checkBox: LKCheckbox
        let titleLable: UILabel = UILabel()

        init(equipment: String, isSelected: Bool) {
            self.checkBox = LKCheckbox(boxType: .multiple, isEnabled: false, iconSize: CGSize(width: 19, height: 19))
            self.checkBox.isSelected = isSelected
            self.checkBox.isUserInteractionEnabled = false
            super.init(frame: .zero)
            snp.makeConstraints { $0.height.equalTo(48) }

            titleLable.textColor = UIColor.ud.textTitle
            titleLable.text = equipment
            titleLable.textAlignment = .left

            let containerView = UIView()
            addSubview(containerView)
            containerView.snp.makeConstraints {
                $0.left.equalToSuperview().offset(16)
                $0.right.top.bottom.equalToSuperview()
            }
            containerView.addBottomSepratorLine()

            let tapGesture = UITapGestureRecognizer()
            tapGesture.addTarget(self, action: #selector(contentTapped))
            containerView.addGestureRecognizer(tapGesture)

            containerView.addSubview(checkBox)
            checkBox.snp.makeConstraints {
                $0.left.centerY.equalToSuperview()
                $0.size.equalTo(CGSize(width: 19, height: 19))
            }

            containerView.addSubview(titleLable)
            titleLable.snp.makeConstraints {
                $0.left.equalTo(checkBox.snp.right).offset(10)
                $0.centerY.equalToSuperview()
                $0.right.equalToSuperview().offset(-15)
            }

        }

        @objc func contentTapped() {
            checkBox.isSelected = !checkBox.isSelected
            itemTapped?()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

    }

}
