//
//  MinutesFloatBackView.swift
//  Minutes
//
//  Created by chenlehui on 2021/11/4.
//

import UIKit
import MinutesFoundation
import UniverseDesignShadow
import UniverseDesignIcon

class MinutesFloatBackView: UIControl {

    enum ShowType {
        case up
        case down

        var iconImage: UIImage {
            switch self {
            case .up:
                return UDIcon.getIconByKey(.upTopOutlined, iconColor: UIColor.ud.iconN1)
            case .down:
                return UDIcon.getIconByKey(.downBottomOutlined, iconColor: UIColor.ud.iconN1)
            }
        }
    }

    private lazy var icon: UIImageView = UIImageView()

    private lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 17)
        l.textColor = UIColor.ud.textTitle
        l.text = BundleI18n.Minutes.MMWeb_G_BackToCurrentPosition
        return l
    }()

    var isShowing = false
    var bottomInset: CGFloat = 24
    var showType: ShowType = .up
    var isTipsShow = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.ud.bgFloat
        layer.ud.setShadow(type: .s4Down)
        layer.borderColor = UIColor.ud.lineBorderCard.cgColor
        layer.borderWidth = 0.5
        layer.cornerRadius = 24
        addSubview(icon)
        icon.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.size.equalTo(20)
            make.centerY.equalToSuperview()
        }

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(icon.snp.right).offset(8)
            make.right.equalTo(-16)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(in view: UIView, with type: ShowType) {
        if isShowing { return }
        showType = type
        icon.image = type.iconImage
        view.addSubview(self)
        isHidden = false
        switch type {
        case .up:
            self.snp.makeConstraints { make in
                make.top.equalTo(24)
                make.right.equalTo(-16)
                make.left.greaterThanOrEqualToSuperview().offset(16)
                make.height.equalTo(48)
            }
        case .down:
            self.snp.makeConstraints { make in
                make.bottom.equalTo(-bottomInset)
                make.left.greaterThanOrEqualToSuperview().offset(16)
                make.right.equalTo(-16)
                make.height.equalTo(48)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.changeToSmall()
        }
        isShowing = true
    }

    func hide() {
        guard isShowing else { return }
        removeFromSuperview()
        isShowing = false
        resetConstraints()
    }

    private func resetConstraints() {
        if isTipsShow { return }
        icon.snp.remakeConstraints { make in
            make.left.equalTo(16)
            make.size.equalTo(20)
            make.centerY.equalToSuperview()
        }
        titleLabel.snp.remakeConstraints { make in
            make.left.equalTo(icon.snp.right).offset(8)
            make.right.equalTo(-16)
            make.centerY.equalToSuperview()
        }
        titleLabel.alpha = 1
    }

    private func changeToSmall() {
        if isTipsShow { return }
        icon.snp.remakeConstraints { make in
            make.left.equalTo(14)
            make.right.equalTo(-14)
            make.size.equalTo(20)
            make.centerY.equalToSuperview()
        }
        titleLabel.snp.remakeConstraints { make in
            make.left.equalTo(icon.snp.right).offset(8)
            make.centerY.equalToSuperview()
        }
        UIView.animate(withDuration: 0.2) {
            self.titleLabel.alpha = 0
            self.layoutIfNeeded()
        }
        isTipsShow = true
    }
}
