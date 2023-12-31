//
//  FilterDrawerSubItemCell.swift
//  Todo
//
//  Created by baiyantao on 2022/8/17.
//

import Foundation
import UniverseDesignIcon
import UniverseDesignFont

struct FilterDrawerSubItemCellData {
    var containerGuid: String
    var joinTime: Int64 = 0
    var archivedTime: Int64 = 0

    var title: String
    var isSelected: Bool = false
    var accessoryType: AccessoryType = .none
}

extension FilterDrawerSubItemCellData {
    enum AccessoryType: Equatable {
        case none
        case moreBtn
        case archivedBtn
    }

    func backgroundColor(_ highlighted: Bool) -> UIColor {
        if isSelected {
            return UIColor.ud.primaryFillSolid01
        }
        return highlighted ? UIColor.ud.fillHover : UIColor.ud.bgBody
    }
}

final class FilterDrawerSubItemCell: UITableViewCell {

    var viewData: FilterDrawerSubItemCellData? {
        didSet {
            guard let data = viewData else { return }
            titleLabel.text = data.title
            titleLabel.textColor = data.isSelected ? UIColor.ud.primaryContentDefault : UIColor.ud.textTitle
            titleLabel.font = data.isSelected ? UDFont.systemFont(ofSize: 14, weight: .semibold) : UDFont.systemFont(ofSize: 14)

            relayout(type: data.accessoryType)
        }
    }

    var moreBtnHandler: ((_ sourceView: UIView, _ containerGuid: String?) -> Void)?

    private lazy var titleLabel = UILabel()
    private lazy var moreBtn = initMoreBtn()
    private lazy var archivedBtn = initArchivedBtn()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupBackgroundViews(highlightOn: true)
        setBackViewLayout(UIEdgeInsets(top: 1, left: 16, bottom: 1, right: 16), 6)

        let containerView = UIView()
        contentView.addSubview(containerView)
        containerView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.left.equalToSuperview().offset(8)
            $0.right.equalToSuperview().offset(-8)
        }

        containerView.addSubview(titleLabel)
        containerView.addSubview(moreBtn)
        containerView.addSubview(archivedBtn)
        relayout(type: .none)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func relayout(type: FilterDrawerSubItemCellData.AccessoryType) {
        moreBtn.isHidden = true
        archivedBtn.isHidden = true
        switch type {
        case .none:
            titleLabel.snp.remakeConstraints {
                $0.centerY.equalToSuperview()
                $0.left.equalToSuperview().offset(48)
                $0.right.equalToSuperview().offset(-16)
            }
        case .moreBtn:
            moreBtn.isHidden = false
            moreBtn.snp.remakeConstraints {
                $0.centerY.equalToSuperview()
                $0.width.height.equalTo(16)
                $0.right.equalToSuperview().offset(-18)
            }
            titleLabel.snp.remakeConstraints {
                $0.centerY.equalToSuperview()
                $0.left.equalToSuperview().offset(48)
                $0.right.equalTo(moreBtn.snp.left).offset(-16)
            }
        case .archivedBtn:
            moreBtn.isHidden = false
            archivedBtn.isHidden = false
            moreBtn.snp.remakeConstraints {
                $0.centerY.equalToSuperview()
                $0.width.height.equalTo(16)
                $0.right.equalToSuperview().offset(-18)
            }
            archivedBtn.snp.remakeConstraints {
                $0.centerY.equalToSuperview()
                $0.width.height.equalTo(16)
                $0.right.equalTo(moreBtn.snp.left).offset(-15)
            }
            titleLabel.snp.remakeConstraints {
                $0.centerY.equalToSuperview()
                $0.left.equalToSuperview().offset(48)
                $0.right.equalTo(archivedBtn.snp.left).offset(-16)
            }
        }
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        setBackViewColor(viewData?.backgroundColor(highlighted) ?? UIColor.ud.bgBody)
    }

    private func initMoreBtn() -> UIButton {
        let button = UIButton(type: .custom)
        let image = UDIcon.moreOutlined
            .ud.resized(to: CGSize(width: 16, height: 16))
            .ud.withTintColor(UIColor.ud.iconN2)
        button.setImage(image, for: .normal)
        button.setImage(image, for: .selected)
        button.hitTestEdgeInsets = UIEdgeInsets(top: -10, left: -7.5, bottom: -10, right: -7.5)
        button.addTarget(self, action: #selector(onMoreBtnClick), for: .touchUpInside)
        return button
    }

    private func initArchivedBtn() -> UIButton {
        let button = UIButton(type: .custom)
        let image = UDIcon.massageBoxOutOutlined
            .ud.resized(to: CGSize(width: 16, height: 16))
            .ud.withTintColor(UIColor.ud.iconN3)
        button.setImage(image, for: .normal)
        button.setImage(image, for: .selected)
        button.hitTestEdgeInsets = UIEdgeInsets(top: -10, left: -7.5, bottom: -10, right: -7.5)
        button.addTarget(self, action: #selector(onMoreBtnClick), for: .touchUpInside)
        return button
    }

    @objc
    private func onMoreBtnClick() {
        switch viewData?.accessoryType {
        case .moreBtn, .archivedBtn: break
        default:
            assertionFailure()
            return
        }
        moreBtnHandler?(moreBtn, viewData?.containerGuid)
    }
}
