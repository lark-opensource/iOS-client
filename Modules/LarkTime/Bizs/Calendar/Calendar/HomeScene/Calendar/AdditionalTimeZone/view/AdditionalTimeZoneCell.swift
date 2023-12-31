//
//  AdditionalTimeZoneCell.swift
//  Calendar
//
//  Created by chaishenghua on 2023/10/18.
//

import Foundation
import SnapKit
import LarkUIKit
import UniverseDesignFont
import UniverseDesignColor
import UniverseDesignIcon
import RxSwift

class DeleteButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let biggerFrame = self.bounds.inset(by: UIEdgeInsets.init(top: -6, left: -6, bottom: -6, right: -6))
        let isInside = biggerFrame.contains(point)
        if isInside {
            return isInside
        } else {
            return super.point(inside:point, with: event)
        }
    }
}

class AdditionalTimeZoneCell: UITableViewCell {
    static let identifier = String(describing: AdditionalTimeZoneCell.self)
    private var deleteAction: ((UITableViewCell) -> Void)?
    private let disposebag = DisposeBag()
    private var isSelectable: Bool = true
    private let margin = 16
    private var bottomBorder: UIView?

    private lazy var checkBox = {
        return LKCheckbox(boxType: .single, isEnabled: true, iconSize: CGSize(width: 20, height: 20))
    }()

    private lazy var titleView = {
       let label = UILabel()
        label.font = UDFont.body0(.fixed)
        label.textColor = UDColor.textTitle
        return label
    }()

    private lazy var subTitleView = {
       let label = UILabel()
        label.font = UDFont.body2(.fixed)
        label.textColor = UDColor.textPlaceholder
        return label
    }()

    private lazy var deleteBtn = {
        let btn = DeleteButton()
        btn.setImage(UDIcon.deleteTrashOutlined.colorImage(UDColor.iconN3)?.ud.resized(to: CGSize(width: 20, height: 20)),
                     for: .normal)
        return btn
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        setupView()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        checkBox.isSelected = selected
    }

    private func setupView() {
        self.contentView.backgroundColor = UDColor.bgBody
        self.contentView.addSubview(checkBox)
        self.contentView.addSubview(titleView)
        self.contentView.addSubview(subTitleView)
        self.contentView.addSubview(deleteBtn)
        bottomBorder = self.contentView.addCellBottomBorder()
        checkBox.isUserInteractionEnabled = false

        checkBox.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(margin)
            make.centerY.equalToSuperview()
            make.height.width.equalTo(20)
        }
        titleView.snp.makeConstraints { make in
            make.leading.equalTo(checkBox.snp.trailing).offset(12)
            make.height.equalTo(22)
            make.bottom.equalTo(self.contentView.snp.centerY)
            make.trailing.lessThanOrEqualTo(deleteBtn.snp.leading).offset(-12)
        }
        subTitleView.snp.makeConstraints { make in
            make.leading.equalTo(checkBox.snp.trailing).offset(12)
            make.height.equalTo(22)
            make.top.equalTo(self.contentView.snp.centerY)
            make.trailing.lessThanOrEqualTo(deleteBtn.snp.leading).offset(-12)
        }
        deleteBtn.snp.makeConstraints { make in
            make.height.width.equalTo(20)
            make.trailing.equalToSuperview().inset(margin)
            make.centerY.equalToSuperview()
        }

        deleteBtn.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.deleteAction?(self)
            }).disposed(by: disposebag)
    }

    func setViewData(viewData: AdditionalTimeZoneViewData) {
        self.isSelectable = viewData.isSelectable
        if !isSelectable {
            checkBox.snp.updateConstraints {
                $0.width.height.equalTo(0)
            }
            titleView.snp.updateConstraints {
                $0.leading.equalTo(checkBox.snp.trailing)
            }
            subTitleView.snp.updateConstraints {
                $0.leading.equalTo(checkBox.snp.trailing)
            }
            checkBox.isHidden = true
        }
        titleView.text = viewData.title
        subTitleView.text = viewData.subTitle
        self.deleteAction = viewData.deleteAction
        bottomBorder?.isHidden = !viewData.showBottomBorder
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
