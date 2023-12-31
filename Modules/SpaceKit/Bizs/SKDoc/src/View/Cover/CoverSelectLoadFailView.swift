//
//  CoverSelectLoadFailView.swift
//  SKDoc
//
//  Created by lizechuang on 2021/2/3.
//

import Foundation
import SKResource
import RxSwift
import UniverseDesignEmpty

// TODO: UDEmpty 组件接入
class CoverSelectLoadFailView: UIView {

    let retryAction = PublishSubject<()>()
    lazy var imageView: UIImageView = {
        let imgView = UIImageView()
        imgView.contentMode = .center
        imgView.image = UDEmptyType.loadingFailure.defaultImage()
        return imgView
    }()

    lazy var contentLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.N600
        label.text = BundleI18n.SKResource.CreationMobile_Docs_DocCover_UnableToLoad_Tooltip
        label.textAlignment = .right
        return label
    }()

    lazy var retryLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.isUserInteractionEnabled = true
        label.textColor = UIColor.ud.colorfulBlue
        label.text = BundleI18n.SKResource.CreationMobile_Docs_DocCover_ClickToReload_Button
        label.textAlignment = .left
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = UIColor.ud.N50
        addSubview(imageView)
        addSubview(contentLabel)
        addSubview(retryLabel)
        imageView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(196)
            make.width.height.equalTo(125)
        }
        contentLabel.snp.makeConstraints { (make) in
            make.top.equalTo(imageView.snp.bottom).offset(16)
            make.right.equalTo(imageView.snp.centerX)
        }
        retryLabel.snp.makeConstraints { (make) in
            make.top.equalTo(contentLabel.snp.top)
            make.left.equalTo(contentLabel.snp.right)
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(retry(_:)))
        tap.numberOfTouchesRequired = 1
        tap.numberOfTapsRequired = 1
        retryLabel.addGestureRecognizer(tap)
    }

    @objc
    private func retry(_  tapGesture: UITapGestureRecognizer) {
        retryAction.onNext(())
    }
}
