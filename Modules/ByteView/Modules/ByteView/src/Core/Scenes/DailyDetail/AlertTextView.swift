//
//  AlertTextView.swift
//  Pods
//
//  Created by LUNNER on 2019/6/13.
//

import Foundation

class AlertTextView: UIView {
    private lazy var contentLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.N00
        self.layer.cornerRadius = 8
        self.addSubview(self.contentLabel)
        self.contentLabel.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(16)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setText(text: String) {
        self.contentLabel.text = text
    }

    func show() {
        self.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        self.alpha = 0
        self.isHidden = false
        // nolint-next-line: magic number
        UIView.animate(withDuration: 0.25) {
            self.alpha = 1
            self.transform = CGAffineTransform.identity
        }
    }

    func hide() {
        // nolint-next-line: magic number
        UIView.animate(withDuration: 0.25, animations: {
            self.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.alpha = 0
        }, completion: { (_) in
            self.isHidden = true
        })
    }

}
