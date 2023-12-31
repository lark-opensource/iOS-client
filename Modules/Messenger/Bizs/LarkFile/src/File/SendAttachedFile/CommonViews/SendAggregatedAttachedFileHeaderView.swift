//
//  SendAggregatedAttachedFileHeaderView.swift
//  LarkFile
//
//  Created by ChalrieSu on 2018/9/20.
//

import UIKit
import Foundation

final class SendAggregatedAttachedFileHeaderView: UIView {
    private let expandImageView = UIImageView()
    private let titleLabel = UILabel()

    private var tapBlock: ((SendAggregatedAttachedFileHeaderView) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.ud.bgBody

        addSubview(expandImageView)
        expandImageView.image = Resources.read_status_arrow
        expandImageView.snp.makeConstraints { (make) in
            make.width.height.equalTo(12)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(17)
        }

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(expandImageView.snp.right).offset(12)
            make.centerY.equalToSuperview()
        }

        lu.addTapGestureRecognizer(action: #selector(didTap), target: self)
        lu.addBottomBorder()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setContent(name: String,
                    count: Int,
                    expand: Bool,
                    tapBlock: @escaping (SendAggregatedAttachedFileHeaderView) -> Void) {
        self.tapBlock = tapBlock

        titleLabel.text = "\(name) (\(count))"
        if expand {
            expandImageView.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
        } else {
            expandImageView.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi * 0.5))
        }
    }

    @objc
    func didTap() {
        tapBlock?(self)
    }
}
