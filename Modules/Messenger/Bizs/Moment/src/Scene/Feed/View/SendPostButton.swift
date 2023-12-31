//
//  SendPostButton.swift
//  Moment
//
//  Created by bytedance on 2021/9/14.
//

import Foundation
import UIKit
import FigmaKit

final class SendPostButton: UIButton {
    private let backgroundColorNormal = UIColor.ud.primaryContentDefault
    private let backgroundColorPress = UIColor.ud.primaryContentPressed
    private let backgroundColorDisable = UIColor.ud.iconDisabled

    private let iconViewSize: CGFloat = 48
    //外部使用的时候把整个button size设置的80，而实际视觉上蓝色圆背景的大小是48，所以包了一层
    private lazy var iconView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = backgroundColorNormal
        view.image = Resources.addOutlined
        view.tintColor = .white
        view.contentMode = .center
        view.layer.cornerRadius = iconViewSize / 2
        view.layer.ud.setShadow(type: .s3DownPri)
        return view
    }()
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(iconViewSize)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = self.bounds.height / 2
    }

    override var isHighlighted: Bool {
        didSet {
            if !self.isEnabled {
                return
            }
            if isHighlighted {
                iconView.backgroundColor = self.backgroundColorPress
            } else {
                iconView.backgroundColor = self.backgroundColorNormal
            }
        }
    }

    override var isEnabled: Bool {
        didSet {
            if isEnabled {
                iconView.backgroundColor = self.backgroundColorNormal
                iconView.layer.ud.setShadow(type: .s3DownPri)
            } else {
                iconView.backgroundColor = self.backgroundColorDisable
                iconView.layer.ud.setShadow(type: .s3Down)
            }
        }
    }
}
