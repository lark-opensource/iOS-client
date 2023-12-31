//
//  SKPDFRollingBallView.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2019/7/22.
//  

import UIKit
import SnapKit

class SKPDFRollingBallView: UIView {

    private let label: UILabel
    private let imageView: UIImageView

    var image: UIImage? {
        get {
            return imageView.image
        }
        set {
            imageView.image = newValue
        }
    }

    var text: String? {
        get {
            return label.text
        }
        set {
            label.text = newValue
        }
    }

    override init(frame: CGRect) {
        imageView = UIImageView(frame: .zero)
        label = UILabel(frame: .zero)
        super.init(frame: .zero)
        setupUI()
    }

    func setupUI() {
        addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        addSubview(label)
        label.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.equalTo(28)
        }
    }

    func update(label configuration: (UILabel) -> Void) {
        configuration(label)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
