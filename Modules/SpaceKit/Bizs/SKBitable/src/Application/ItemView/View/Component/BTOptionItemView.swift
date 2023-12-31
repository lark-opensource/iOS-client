//
//  BTOptionItemView.swift
//  SKBitable
//
//  Created by zoujie on 2021/10/22.
//  


import Foundation
import SnapKit
import SKBrowser
import UIKit

final class BTOptionItemView: UIView {
    private var model: BTCapsuleModel

    private var labelEdges: UIEdgeInsets
    private var textLabel: UILabel = {
        let textLabel = UILabel()
        textLabel.textAlignment = .center
        textLabel.font = .systemFont(ofSize: 14, weight: .medium)
        return textLabel
    }()

    init(model: BTCapsuleModel, labelEdges: UIEdgeInsets = UIEdgeInsets(top: 2,
                                                                        left: 12,
                                                                        bottom: 2,
                                                                        right: 12)) {
        self.labelEdges = labelEdges
        self.model = model
        super.init(frame: .zero)

        setUpView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpView() {
        textLabel.textColor = UIColor.docs.rgb(model.color.textColor)
        textLabel.text = model.text

        self.addSubview(textLabel)
        textLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.equalToSuperview().offset(labelEdges.left)
            make.right.equalToSuperview().offset(-labelEdges.right)
            make.top.equalToSuperview().offset(labelEdges.top)
            make.bottom.equalToSuperview().offset(-labelEdges.bottom)
        }

        self.backgroundColor = UIColor.docs.rgb(model.color.color)
        self.layer.cornerRadius = 12
    }

    public func update(model: BTCapsuleModel) {
        self.model = model
        self.textLabel.text = model.text
        self.textLabel.textColor = UIColor.docs.rgb(model.color.textColor)
        
        self.backgroundColor = UIColor.docs.rgb(model.color.color)
    }
}
