//
//  AddAdditionanalTimeZoneCell.swift
//  Calendar
//
//  Created by chaishenghua on 2023/10/23.
//

import Foundation
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignFont
import RxSwift

class AddAdditionanalTimeZoneCell: UITableViewCell {
    static let identifier = String(describing: AddAdditionanalTimeZoneCell.self)
    private var addAdditionanalTimeZoneAction: (() -> Void)?
    private let disposebag = DisposeBag()
    private lazy var icon = {
        let imageView = UIImageView()
        imageView.image = UDIcon.moreAddOutlined.ud.resized(to: CGSize(width: 20, height: 20)).colorImage(UDColor.primaryContentDefault)
        return imageView
    }()

    private lazy var title = {
        let label = UILabel()
        label.text = BundleI18n.Calendar.Calendar_G_AddSecondaryTimeZone
        label.textColor = UDColor.textTitle
        label.font = UDFont.body0(.fixed)
        return label
    }()

    private lazy var addTimeZoneBtn = {
        let btn = UIButton()
        btn.backgroundColor = .clear
        return btn
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    private func setupView() {
        self.selectionStyle = .none
        self.contentView.backgroundColor = UDColor.bgBody
        self.contentView.addSubview(icon)
        self.contentView.addSubview(title)
        self.contentView.addSubview(addTimeZoneBtn)

        icon.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.height.width.equalTo(20)
        }
        title.snp.makeConstraints { make in
            make.leading.equalTo(icon.snp.trailing).offset(12)
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        addTimeZoneBtn.snp.makeConstraints { $0.edges.equalToSuperview() }

        addTimeZoneBtn.rx.tap
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.addAdditionanalTimeZoneAction?()
            }).disposed(by: disposebag)
    }

    func setViewData(viewData: AddAdditionalTimeZoneViewData) {
        self.addAdditionanalTimeZoneAction = viewData.clickAction
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
