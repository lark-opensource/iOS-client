//
//  LKAssetsCollectionEmptyDataView.swift
//  LarkAssetsBrowser
//
//  Created by 王元洵 on 2021/5/25.
//

import Foundation
import LarkUIKit
import UIKit

final class LKAssetsCollectionEmptyDataView: UIView {
    let imageView: UIImageView
    let label: UILabel

    override init(frame: CGRect) {
        let imageView = UIImageView(image: Resources.emptyData)
        self.imageView = imageView

        let label = UILabel(frame: .zero)
        label.font = UIFont.ud.body0(.fixed)
        label.textColor = UIColor.ud.textPlaceholder
        label.text = BundleI18n.LarkAssetsBrowser.Lark_Legacy_PullEmptyResult
        self.label = label

        super.init(frame: .zero)
        self.backgroundColor = UIColor.clear

        self.addSubview(imageView)
        self.addSubview(label)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard let window = self.window else { return }
        let top = UIScreen.main.bounds.height / 3
        imageView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(window).offset(top)
        }

        label.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(imageView.snp.bottom).offset(10)
        }
    }
}
