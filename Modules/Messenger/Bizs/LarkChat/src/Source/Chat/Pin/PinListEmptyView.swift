//
//  PinListEmptyView.swift
//  LarkChat
//
//  Created by chengzhipeng-bytedance on 2018/9/18.
//

import Foundation
import UIKit

final class PinListEmptyView: UIView {
    private(set) var imageView: UIImageView = .init(image: nil)
    private(set) var tipsLabel: UILabel = .init()

    var tipsText: String = "" {
        didSet {
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.ud.textPlaceholder,
                .font: UIFont.systemFont(ofSize: 16)
            ]
            self.tipsLabel.attributedText = NSAttributedString(string: tipsText, attributes: attributes)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.backgroundColor = UIColor.clear

        let imageView = UIImageView()
        imageView.image = Resources.pin_empty_view
        self.addSubview(imageView)
        self.imageView = imageView

        let tipsLabel = UILabel()
        tipsLabel.numberOfLines = 0
        tipsLabel.font = UIFont.systemFont(ofSize: 16)
        tipsLabel.textColor = UIColor.ud.textPlaceholder
        tipsLabel.textAlignment = .center
        self.addSubview(tipsLabel)
        self.tipsLabel = tipsLabel
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

        tipsLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.left.greaterThanOrEqualTo(80)
            make.right.lessThanOrEqualTo(-80)
            make.top.equalTo(imageView.snp.bottom).offset(10)
        }
    }
}
