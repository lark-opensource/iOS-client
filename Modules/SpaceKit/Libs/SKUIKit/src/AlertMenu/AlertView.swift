//
//   AlertController.swift
//   Alert
//
//  Created by WangXiaoZhen on 2018/1/20.
//  Copyright © 2018年 WangXiaoZhen. All rights reserved.
//

import UIKit
import SKFoundation
import SKResource
import UniverseDesignColor

class AlertView: UIView {
    weak var delegate: AlertActionDelegate?
    var headerView: UIView?
    let redpointTag = Int(Date().timeIntervalSince1970)
    init(frame: CGRect, delegate: AlertActionDelegate) {
        self.delegate = delegate
        super.init(frame: frame)
        self.backgroundColor = UDColor.bgFloat
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AlertView {
    //swiftlint:disable cyclomatic_complexity
    //swiftlint:disable function_body_length
    func setAlertView(_ width: CGFloat) {
        subviews.forEach { (subview) in
            subview.removeFromSuperview()
        }
        guard let delegate = delegate else { return }
        self.backgroundColor = delegate.getItemColor()
        if let headerView = self.headerView {
            self.addSubview(headerView)
            headerView.snp.remakeConstraints { (make) in
                make.width.equalToSuperview()
                make.height.equalTo(86)
            }
        }

        var offsetY: CGFloat = 0
        if let headerView = self.headerView {
            offsetY = headerView.frame.size.height
        }
        for (index, alertAction) in delegate.getAlertAction().enumerated() {
            let itemHeight = delegate.getItemHeightFor(alertAction)
            let itemWeight: CGFloat = itemHeight * 0.43
            let itemX: CGFloat = (width - itemWeight * CGFloat(delegate.getAlertAction().count)) / CGFloat(delegate.getAlertAction().count + 1)

            let itemBtn = UIButton()
            itemBtn.setBackgroundImage(UIImage.docs.create(by: UDColor.bgFiller), for: .highlighted)
            if delegate.getAlertDirection() == .vertical {
                itemBtn.frame = CGRect(x: CGFloat(0), y: offsetY,
                                       width: width,
                                       height: itemHeight)
            } else {
                itemBtn.frame = CGRect(x: itemX + (itemX + itemWeight) * CGFloat(index) - itemWeight * 0.25, y: itemHeight * 0.16 - itemWeight * 0.25 + offsetY,
                                       width: itemWeight * 1.5,
                                       height: itemWeight * 1.5)
            }
            offsetY += itemHeight
            if alertAction.image != nil {
                itemBtn.tag = index
                itemBtn.addTarget(self, action: #selector(alertViewAction(sender:)), for: .touchUpInside)
                let image = UIImageView()
                let label = UILabel()
                image.image = alertAction.image
                label.text = alertAction.title
                label.backgroundColor = UDColor.bgFloat
                label.textColor = delegate.getTitleColor().withAlphaComponent(0.75)
                label.textAlignment = .center
                label.font = UIFont.systemFont(ofSize: 13, weight: UIFont.Weight.medium)
                if delegate.getAlertDirection() == .vertical {
                    image.frame = CGRect(x: width / 2 - itemHeight * 0.23,
                                         y: 0.13 * itemHeight,
                                         width: itemHeight * 0.46, height: itemHeight * 0.46)
                    label.frame = CGRect(x: 0, y: 0.71 * itemHeight,
                                         width: width, height: itemHeight * 0.15)
                } else {
                    image.frame = CGRect(x: itemWeight * 0.25, y: itemHeight * 0.16,
                                         width: itemWeight,
                                         height: itemWeight)
                    label.frame = CGRect(x: itemWeight * 0.05, y: itemHeight * 0.61,
                                         width: itemWeight * 1.4,
                                         height: itemHeight * 0.15)
                }
                itemBtn.addSubview(image)
                itemBtn.addSubview(label)
            } else {
                setTitle(for: itemBtn, alertAction: alertAction)
                switch alertAction.style {
                case .normal:
                    itemBtn.setTitleColor(delegate.getTitleColor(), for: .normal)
                    itemBtn.setTitleColor(delegate.getTitleColor().withAlphaComponent(0.5), for: .highlighted)
                    itemBtn.tag = index
                    itemBtn.addTarget(self, action: #selector(alertViewAction(sender:)), for: .touchUpInside)
                case .notenabled:
                    itemBtn.setTitleColor(UIColor.ud.N300, for: .normal)
                case .option:
                    var font = UIFont.systemFont(ofSize: 16, weight: .medium)
                    if let titleFont = alertAction.titleFont {
                        font = titleFont
                    }
                    itemBtn.titleLabel?.font = font
                    if let alignment = alertAction.horizontalAlignment {
                        itemBtn.contentHorizontalAlignment = alignment
                    }
                    itemBtn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
                    if let canBeSelected = alertAction.canBeSelected, !canBeSelected {
                        itemBtn.setTitleColor(UIColor.ud.N300, for: .normal)
                    } else {
                        itemBtn.setTitleColor(delegate.getTitleColor(), for: .normal)
                        itemBtn.setTitleColor(delegate.getTitleColor().withAlphaComponent(0.5), for: .highlighted)
                        itemBtn.tag = index
                        itemBtn.addTarget(self, action: #selector(alertViewAction(sender:)), for: .touchUpInside)
                    }
                case .destructive:
                    var font = UIFont.systemFont(ofSize: 16, weight: .medium)
                    if let titleFont = alertAction.titleFont {
                        font = titleFont
                    }
                    itemBtn.titleLabel?.font = font
                    if let alignment = alertAction.horizontalAlignment {
                        itemBtn.contentHorizontalAlignment = alignment
                    }
                    itemBtn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
                    if let canBeSelected = alertAction.canBeSelected, !canBeSelected {
                        itemBtn.setTitleColor(UIColor.ud.N300, for: .normal)

                    } else {
                        itemBtn.setTitleColor(UIColor.ud.colorfulRed, for: .normal)
                        itemBtn.tag = index
                        itemBtn.addTarget(self, action: #selector(alertViewAction(sender:)), for: .touchUpInside)
                        if delegate.checkDestructiveUsingDifferentColor() == false {
                            itemBtn.setTitleColor(delegate.getTitleColor(), for: .normal)
                        }
                    }

                }
                checkToAddRedPoint(itemBtn: itemBtn, alertAction: alertAction)
            }

            if let isSelected = alertAction.isSelected {
                let checkIcon = UIImageView()
                checkIcon.image = BundleResources.SKResource.DocsApp.checkMark
                checkIcon.isHidden = !isSelected
                let checkSize = CGSize(width: 24, height: 24)
                checkIcon.frame = CGRect(x: itemBtn.frame.size.width - checkSize.width - 30, y: (itemBtn.frame.size.height - checkSize.height) / 2, width: checkSize.width, height: checkSize.height)
                itemBtn.addSubview(checkIcon)
            }
            if alertAction.needSeparateLine {
                let dividingLine = UIView()
                dividingLine.backgroundColor = UIColor.ud.N300
                itemBtn.addSubview(dividingLine)
                dividingLine.snp.makeConstraints { (make) in
                    make.bottom.equalTo(itemBtn)
                    make.left.equalTo(itemBtn).offset(19)
                    make.right.equalTo(itemBtn).offset(-19)
                    make.height.equalTo(0.5)
                }
            }
            itemBtn.docs.addStandardHover()
            self.addSubview(itemBtn)
        }
    }
    //swiftlint:enable cyclomatic_complexity
    //swiftlint:enable function_body_length

    @objc
    func alertViewAction(sender: UIButton) {
        delegate?.alertDismiss()
        removeRedPoint(sender: sender)
        if let delegate = delegate,
            let handler = delegate.getAlertAction()[sender.tag].handler {
            handler()
        }
    }
    private func setTitle(for itemBtn: UIButton, alertAction: AlertAction) {
        if alertAction.subtitle == nil {
            itemBtn.setTitle(alertAction.title, for: .normal)
        } else {
            let mainLabel = UILabel(frame: CGRect(x: 20, y: 5, width: itemBtn.frame.width, height: 24))
            mainLabel.textColor = UIColor.ud.N900
            mainLabel.font = UIFont.systemFont(ofSize: 16)
            var subLabelWidth = itemBtn.frame.width - 20
            if let isSelected = alertAction.isSelected, isSelected {
                subLabelWidth -= 60
            }
            let subLabel = UILabel(frame: CGRect(x: 20, y: 24, width: subLabelWidth, height: 40))
            subLabel.numberOfLines = 2
            subLabel.textColor = UIColor.ud.N500
            subLabel.font = UIFont.systemFont(ofSize: 14)
            mainLabel.text = alertAction.title
            subLabel.text = alertAction.subtitle
            itemBtn.addSubview(mainLabel)
            itemBtn.addSubview(subLabel)
            if let canBeSelected = alertAction.canBeSelected, !canBeSelected {
                itemBtn.setTitleColor(UIColor.ud.N300, for: .normal)
                mainLabel.textColor = UIColor.ud.N300
                subLabel.textColor = UIColor.ud.N300
            } else {
                itemBtn.setTitleColor(UIColor.ud.N900, for: .normal)
                mainLabel.textColor = UIColor.ud.N900
                subLabel.textColor = UIColor.ud.N500
            }
        }
        if alertAction.needSeparateLine {
            let dividingLine = UIView()
            dividingLine.backgroundColor = UIColor.ud.N300
            itemBtn.addSubview(dividingLine)
            dividingLine.snp.makeConstraints { (make) in
                make.bottom.equalTo(itemBtn)
                make.left.equalTo(itemBtn).offset(19)
                make.right.equalTo(itemBtn).offset(-19)
                make.height.equalTo(0.5)
            }
        }
    }
}

// MARK: - 小红点逻辑
extension AlertView {

    private func checkToAddRedPoint(itemBtn: UIButton, alertAction: AlertAction) {

        guard alertAction.needRedPoint, let titleLabel = itemBtn.titleLabel else { return }
        let redPointView = UIView()
        redPointView.tag = redpointTag
        let width: CGFloat = 8
        redPointView.layer.cornerRadius = width / 2
        redPointView.layer.backgroundColor = UIColor.ud.colorfulRed.cgColor

        itemBtn.addSubview(redPointView)
        redPointView.snp.makeConstraints { (make) in
            make.left.equalTo(titleLabel.snp.right).offset(4.5)
            make.bottom.equalTo(titleLabel.snp.top).offset(3)
            make.width.height.equalTo(width)
        }
    }

    private func removeRedPoint(sender: UIButton) {
        sender.subviews.forEach { (view) in
            if view.tag == redpointTag { view.removeFromSuperview() }
        }
    }
}
