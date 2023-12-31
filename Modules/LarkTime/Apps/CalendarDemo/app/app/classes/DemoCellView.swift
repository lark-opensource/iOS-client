//
//  NewHomeViewCell.swift
//  CalendarDemo
//
//  Created by huoyunjie on 2021/9/30.
//

import Foundation
import UIKit
import UniverseDesignIcon

struct DemoCellModel {
    enum Style {
        case switch_(() -> Bool)
        case vc
    }
    var title: String
    var targetVC: () -> UIViewController = { UIViewController() }
    var customAction: (() -> Void)? = nil
    var style: Style = .vc
}

final class DemoCellView: UITableViewCell {

    var viewData: DemoCellModel? {
        didSet {
            guard let viewData = viewData else { return }
            switchButton.isHidden = true
            icon.isHidden = true
            label.text = viewData.title
            switch viewData.style {
            case .switch_(let action):
                switchButton.isHidden = false
//                switchButton.isUserInteractionEnabled = false
                switchButton.setOn(action(), animated: false)
                switchButton.addTarget(self, action: #selector(clickHandle), for: .valueChanged)
            case .vc:
                icon.isHidden = false
            }
        }
    }

    private let wrapperView: UIView = UIView()
    private let label: UILabel = UILabel()

    private var icon: UIImageView = {
        let icon = UIImageView(image: UDIcon.getIconByKeyNoLimitSize(.rightOutlined).ud.resized(to: CGSize(width: 20, height: 20)).renderColor(with: .n3))
        return icon
    }()

    var switchButton: UISwitch = UISwitch.blueSwitch()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupView()
    }


    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        contentView.backgroundColor = UIColor.ud.bgFloatBase
        wrapperView.backgroundColor = UIColor.ud.bgFloat
        contentView.addSubview(wrapperView)
        wrapperView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.height.equalToSuperview()
        }


        wrapperView.addSubview(label)
        label.font = UIFont.cd.font(ofSize: 16)
        label.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }

        wrapperView.addSubview(switchButton)
        switchButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.leading.greaterThanOrEqualTo(label.snp.trailing).offset(2)
            make.centerY.equalToSuperview()
        }

        wrapperView.addSubview(icon)
        icon.snp.makeConstraints { make in
            make.size.equalTo(16)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-16)
            make.leading.greaterThanOrEqualTo(label.snp.trailing).offset(2)
        }
    }

    private func setupAction() {
        guard let style = viewData?.style else { return }
        switch style {
        case .vc:
            let tap = UITapGestureRecognizer(target: self, action: #selector(clickHandle))
            wrapperView.addGestureRecognizer(tap)
        case .switch_(_):
            switchButton.addTarget(self, action: #selector(clickHandle), for: .valueChanged)
        }
    }

    @objc
    private func clickHandle() {
        viewData?.customAction?()
    }

    func setCornersRadius(radius: CGFloat, roundingCorners: UIRectCorner) {
        let rect = CGRect(x: 0, y: 0, width: contentView.bounds.width - 32, height: contentView.bounds.height)
        let maskPath = UIBezierPath(roundedRect: rect, byRoundingCorners: roundingCorners, cornerRadii: CGSize(width: radius, height: radius))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = rect
        maskLayer.path = maskPath.cgPath
        maskLayer.shouldRasterize = true
        maskLayer.rasterizationScale = UIScreen.main.scale
        wrapperView.layer.mask = maskLayer
    }
}
