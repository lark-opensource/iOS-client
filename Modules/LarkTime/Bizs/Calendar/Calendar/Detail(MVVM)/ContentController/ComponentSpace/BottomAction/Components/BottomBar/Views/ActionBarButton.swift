//
//  ActionBarButton.swift
//  Calendar
//
//  Created by jiayi zou on 2018/11/22.
//  Copyright © 2018 EE. All rights reserved.
//

import UIKit
import CalendarFoundation
final class ActionBarButton: UIControl {
    private var _isSelected: Bool = false

    override var isSelected: Bool {
        get {
            return _isSelected
        }
        set {
            if _isSelected != newValue {
                _isSelected = newValue
                if self.isSelected {
                    self.titleLabel.text = self.selectedTitle
                    self.titleLabel.textColor = self.selectedColor
                    self.imageView.image = self.selectedImage
                } else {
                    self.titleLabel.text = self.normalTitle
                    self.titleLabel.textColor = self.normalColor
                    self.imageView.image = self.normalImage
                }
                self.imageView.alpha = 0
                self.imageView.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
            }
        }
    }

    func setFinalStatus() {
        self.imageView.alpha = 1
        self.imageView.transform = CGAffineTransform(scaleX: 1, y: 1)
    }

    private var selectedTitle = ""
    private var normalTitle = ""
    private var selectedImage: UIImage
    private var normalImage: UIImage
    private var selectedColor: UIColor
    private var normalColor: UIColor

    private var titleLabel = UILabel()
    private var wrapper: UIView

    init(selectedTitle: String,
         normalTitle: String,
         selectedImage: UIImage,
         normalImage: UIImage,
         selectedColor: UIColor,
         normalColor: UIColor) {
        self.selectedTitle = selectedTitle
        self.normalTitle = normalTitle
        self.selectedImage = selectedImage
        self.normalImage = normalImage
        self.selectedColor = selectedColor
        self.normalColor = normalColor
        wrapper = UIView()
        super.init(frame: .zero)
        self.addSubview(wrapper)
        wrapper.snp.makeConstraints { (make) in
            make.centerX.centerY.equalToSuperview()
        }
        setupImageView()
        setupTitle()
    }

    func setupTitle() {
        titleLabel.text = normalTitle
        titleLabel.font = UIFont.cd.regularFont(ofSize: 16)
        wrapper.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.right.centerY.equalToSuperview()
            make.left.equalTo(imageView.snp.right).offset(6)
        }
    }

    func setupImageView() {
        wrapper.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.width.height.equalTo(16)
            make.left.centerY.equalToSuperview()
        }
    }

    private lazy var imageView: UIImageView = {
        return UIImageView(image: normalImage)
    }()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
