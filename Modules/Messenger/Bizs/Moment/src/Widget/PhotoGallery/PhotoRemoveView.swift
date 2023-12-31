//
//  PhotoRemoveView.swift
//  Moment
//
//  Created by bytedance on 2021/1/18.
//

import Foundation
import UIKit
import SnapKit

final class PhotoRemoveView: UIView {
    let deleCallBack: (() -> Void)?

    static let bestSize = CGSize(width: 24, height: 24)

    init(deleCallBack: (() -> Void)?) {
        self.deleCallBack = deleCallBack
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        let deleImageView = UIImageView(image: Resources.momentsClose)
        self.addSubview(deleImageView)
        let tap = UITapGestureRecognizer(target: self, action: #selector(itemClick))
        self.addGestureRecognizer(tap)
        deleImageView.snp.makeConstraints { (make) in
            make.width.height.equalTo(CGSize(width: 22, height: 22))
            make.center.equalToSuperview()
        }
    }

    func setCornerStyle(width: CGFloat) {
        self.layer.cornerRadius = width / 2.0
        self.backgroundColor = UIColor.ud.bgBody
        self.clipsToBounds = true
    }

    @objc
    func itemClick() {
        self.deleCallBack?()
    }
}
