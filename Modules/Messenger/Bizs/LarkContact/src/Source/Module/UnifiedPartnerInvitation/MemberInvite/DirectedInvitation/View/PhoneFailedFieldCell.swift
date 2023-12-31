//
//  PhoneFailedFieldCell.swift
//  LarkContact
//
//  Created by SlientCat on 2019/6/9.
//

import Foundation
import UIKit
import LarkUIKit
import RxSwift
import SnapKit

final class PhoneFailedFieldCell: UITableViewCell, FieldCellAbstractable {
    let disposeBag = DisposeBag()
    lazy var countryCodeLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textAlignment = NSTextAlignment.left
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.N900
        label.isUserInteractionEnabled = true

        let tap = UITapGestureRecognizer()
        tap.rx.event.subscribe(onNext: { [weak self] (_) in
            guard let self else { return }
            self.viewModel.switchCountryCodeSubject.onNext((self.viewModel))
        })
        .disposed(by: disposeBag)
        label.addGestureRecognizer(tap)

        return label
    }()
    lazy var arrowView: UIImageView = {
        let imageView = UIImageView(frame: CGRect.zero)
        imageView.image = Resources.arrow_down_country_code
        return imageView
    }()
    lazy var contentLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.textAlignment = NSTextAlignment.left
        label.lineBreakMode = NSLineBreakMode.byTruncatingTail
        label.textColor = UIColor.ud.N900
        label.font = UIFont.systemFont(ofSize: 16)
        label.isUserInteractionEnabled = true

        let tap = UITapGestureRecognizer()
        tap.rx.event.subscribe(onNext: { [weak self] (_) in
            guard let self else { return }
            self.viewModel.backToEditSubject.onNext(self.viewModel)
        })
        .disposed(by: disposeBag)
        label.addGestureRecognizer(tap)

        return label
    }()
    lazy var bottomLine: UIView = {
        let line = UIView(frame: CGRect.zero)
        line.backgroundColor = UIColor.ud.color(245, 74, 69)
        return line
    }()
    lazy var failReasonLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.textAlignment = NSTextAlignment.left
        label.lineBreakMode = NSLineBreakMode.byTruncatingTail
        label.textColor = UIColor.ud.color(245, 74, 69)
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()
    private var viewModel: PhoneFieldViewModel! {
        didSet {
            contentLabel.text = viewModel.contentSubject.value
            countryCodeLabel.text = "\(viewModel.countryCodeSubject.value)"
            failReasonLabel.text = viewModel.failReason
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        layoutPageSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// FieldCellAbstractable
    func bindWithViewModel(viewModel: FieldViewModelAbstractable) {
        guard let viewModel: PhoneFieldViewModel = viewModel as? PhoneFieldViewModel else { return }
        self.viewModel = viewModel
    }

    func beActive() {}

    private func layoutPageSubviews() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.addSubview(countryCodeLabel)
        contentView.addSubview(arrowView)
        contentView.addSubview(contentLabel)
        contentView.addSubview(bottomLine)
        contentView.addSubview(failReasonLabel)

        countryCodeLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(24)
            make.right.equalTo(arrowView.snp.left)
            make.top.equalToSuperview().offset(8)
            make.height.equalTo(35)
        }
        arrowView.snp.makeConstraints { (make) in
            make.centerY.equalTo(contentLabel)
            make.width.height.equalTo(12)
            make.left.equalToSuperview().offset(65)
        }
        contentLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(8)
            make.height.equalTo(35)
            make.left.equalTo(arrowView.snp.right).offset(12)
            make.right.equalToSuperview().offset(-24)
        }
        bottomLine.snp.makeConstraints { (make) in
            make.top.equalTo(contentLabel.snp.bottom)
            make.left.equalTo(countryCodeLabel)
            make.right.equalTo(contentLabel)
            make.height.equalTo(1)
        }
        failReasonLabel.snp.makeConstraints { (make) in
            make.left.equalTo(countryCodeLabel)
            make.right.equalTo(contentLabel)
            make.height.equalTo(20)
            make.top.equalTo(bottomLine.snp.bottom)
        }
    }
}
