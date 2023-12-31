//
//  UnsupportPreviewView.swift
//  SpaceKit
//
//  Created by bytedance on 2018/10/10.
//

import UIKit
import SKFoundation
import SKResource

protocol UnsupportPreviewViewDelegate: AnyObject {
    func didClickPreviewButton(button: UIButton)
}

class UnsupportPreviewView: UIView {
    weak var delegate: UnsupportPreviewViewDelegate?
    private var filePreviewModel: FilePreviewModel

    private lazy var iconImageView: UIImageView = {
        var image: UIImage?
        switch filePreviewModel.type {
        case .zip:
            image = BundleResources.SKResource.Common.Other.unsupport_file_zip
        case .apk:
            image = BundleResources.SKResource.Common.Other.unsupport_file_apk
        case .unKnown:
            image = BundleResources.SKResource.Common.Other.unsupport_file_unknown
        default:
            image = BundleResources.SKResource.Common.Other.unsupport_file_unknown
        }
        return UIImageView(image: image)
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.text = filePreviewModel.name
        label.textColor = UIColor.ud.N900
        label.font = UIFont.systemFont(ofSize: 16)
        label.textAlignment = .center
        label.lineBreakMode = .byTruncatingMiddle
        return label
    }()

    private lazy var sizeLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.N500
        label.font = UIFont.systemFont(ofSize: 12)
        label.textAlignment = .center
        label.text = filePreviewModel.size.memoryFormat
        return label
    }()

    private lazy var previewButton: UIButton = {
        var previewButton = UIButton()
        previewButton.setTitle("用其他应用打开", for: .normal)
        previewButton.setTitleColor(.white, for: .normal)
        previewButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        previewButton.backgroundColor = UIColor.ud.colorfulBlue
        previewButton.layer.cornerRadius = 4
        previewButton.layer.masksToBounds = true
        previewButton.addTarget(self, action: #selector(click(_:)), for: .touchUpInside)
        return previewButton
    }()

    init(file: FilePreviewModel, delegate: UnsupportPreviewViewDelegate) {
        self.filePreviewModel = file
        self.delegate = delegate
        super.init(frame: .zero)

        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(iconImageView)
        addSubview(nameLabel)
        addSubview(sizeLabel)
        addSubview(previewButton)

        iconImageView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(92)
            make.width.height.equalTo(72)
        }

        nameLabel.snp.makeConstraints { (make) in
            make.top.equalTo(iconImageView.snp.bottom).offset(17)
            make.centerX.equalToSuperview()
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }

        sizeLabel.snp.makeConstraints { (make) in
            make.top.equalTo(nameLabel.snp.bottom).offset(10)
            make.centerX.equalToSuperview()
        }

        previewButton.snp.makeConstraints { (make) in
            make.top.equalTo(sizeLabel.snp.bottom).offset(127)
            make.centerX.equalToSuperview()
            make.width.equalTo(180)
            make.height.equalTo(44)
        }
    }

    @objc
    func click(_ button: UIButton) {
        delegate?.didClickPreviewButton(button: button)
    }
}
