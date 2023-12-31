//
//  NameFailedFieldCell.swift
//  LarkContact
//
//  Created by shizhengyu on 2019/12/11.
//

import Foundation
import UIKit
import LarkUIKit
import RxSwift
import SnapKit

final class NameFailedFieldCell: UITableViewCell, FieldCellAbstractable {
    let disposeBag = DisposeBag()

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
        .disposed(by: self.disposeBag)
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
    private var viewModel: NameFieldViewModel! {
        didSet {
            contentLabel.text = viewModel.contentSubject.value
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
        guard let viewModel: NameFieldViewModel = viewModel as? NameFieldViewModel else { return }
        self.viewModel = viewModel
    }

    func beActive() {}

    private func layoutPageSubviews() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.addSubview(contentLabel)
        contentView.addSubview(bottomLine)
        contentView.addSubview(failReasonLabel)

        contentLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(24)
            make.right.equalToSuperview().offset(-24)
            make.top.equalToSuperview().offset(8)
            make.height.equalTo(35)
        }
        bottomLine.snp.makeConstraints { (make) in
            make.left.equalTo(contentLabel)
            make.top.equalTo(contentLabel.snp.bottom)
            make.height.equalTo(1)
            make.centerX.equalToSuperview()
        }
        failReasonLabel.snp.makeConstraints { (make) in
            make.left.right.equalTo(contentLabel)
            make.height.equalTo(20)
            make.top.equalTo(bottomLine.snp.bottom)
        }
    }
}
