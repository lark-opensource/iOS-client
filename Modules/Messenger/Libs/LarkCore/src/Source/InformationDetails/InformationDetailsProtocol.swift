//
//  InformationDetailsProtocol.swift
//  LarkContact
//
//  Created by 姚启灏 on 2018/8/9.
//

import Foundation
import UIKit
import LarkUIKit
import LarkInteraction
import ByteWebImage

public enum NavigationItemStyle {
    case left
    case right
}

public protocol InformationDetailsProtocol: AnyObject {
    var backgroundImageView: UIImageView? { get set }
    var groupAvatar: UIImageView { get set }
    var containerBackgoundView: UIView? { get set }
    var tableView: UITableView? { get set }
    var mutilBy: CGFloat { get set }

    func setupSubviews(isAddGradientView: Bool)
    func setNavigationItem(image: UIImage, highlightImage: UIImage, style: NavigationItemStyle, title: String?, selector: Selector, target: Any) -> UIView
    func updateBackgoundImageViewBouncesZoom(_ offset: CGFloat)
}

extension InformationDetailsProtocol where Self: BaseUIViewController & UITableViewDelegate & UITableViewDataSource {
    public var thresholdOffset: CGFloat {
        let offset = UIScreen.main.bounds.height * self.mutilBy
        // iPad 最大偏移不使用高度计算
        if Display.pad {
            return min(offset, 375)
        }
        return offset
    }

    public var navigationItemWH: CGFloat {
        return 24
    }

    public var navigationItemLeftSpace: CGFloat {
        return 15
    }

    public var navigationItemTopSpace: CGFloat {
        return 35
    }

    public func setupSubviews(isAddGradientView: Bool) {
        self.view.backgroundColor = UIColor.ud.N00

        // table
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = UIColor.clear
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 66
        tableView.rowHeight = UITableView.automaticDimension
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.contentInset = UIEdgeInsets(top: self.thresholdOffset, left: 0, bottom: 40, right: 0)
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        tableView.contentInsetAdjustmentBehavior = .never
        self.tableView = tableView

        // 触发点击头像看大图
        let backView = UIView()
        backView.backgroundColor = UIColor.clear
        backView.isUserInteractionEnabled = true
        self.tableView?.backgroundView = backView

        // 容器背景
        let containerBackgoundView = UIView()
        containerBackgoundView.backgroundColor = UIColor.ud.N00
        self.view.insertSubview(containerBackgoundView, belowSubview: tableView)
        containerBackgoundView.snp.makeConstraints { (make) in
            make.left.right.equalTo(tableView)
            make.height.equalTo(UIScreen.main.bounds.height)
            make.top.equalTo(self.thresholdOffset)
        }
        self.containerBackgoundView = containerBackgoundView
        // 给containerBackgoundView添加阴影
        self.addBlurShadow(on: containerBackgoundView)

        // 背景图
        let backgroundImageView = UIImageView()
        backgroundImageView.backgroundColor = UIColor.ud.N300
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        backgroundImageView.isUserInteractionEnabled = true
        self.view.addSubview(backgroundImageView)
        backgroundImageView.ud.setMaskView()
        backgroundImageView.snp.makeConstraints { (make) in
            make.left.top.right.equalToSuperview()
            make.height.equalTo(self.thresholdOffset)
        }
        self.backgroundImageView = backgroundImageView

        if isAddGradientView {
            // 渐变 view
            let gradientView = GradientView()
            gradientView.backgroundColor = UIColor.clear
            gradientView.colors = [UIColor.ud.staticBlack.withAlphaComponent(0.0), UIColor.ud.staticBlack.withAlphaComponent(0.7)]
            gradientView.locations = [0.0, 1.0]
            gradientView.direction = .vertical
            backgroundImageView.addSubview(gradientView)
            gradientView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
    }

    @discardableResult
    public func setNavigationItem(image: UIImage, highlightImage: UIImage, style: NavigationItemStyle, title: String? = nil, selector: Selector, target: Any) -> UIView {
        let item = self.navigationItem(image: image, highlightImage: highlightImage, title: title, selector: selector, target: target)
        self.view.addSubview(item)
        item.snp.makeConstraints({ (make) in
            switch style {
            case .left:
                make.left.equalTo(self.navigationItemLeftSpace)
            case .right:
                make.right.equalTo(-self.navigationItemLeftSpace)
            }
            make.top.equalTo(self.view.safeAreaLayoutGuide).offset(navigationItemLeftSpace)
        })

        item.addPointer(
            .init(
                effect: .highlight,
                shape: { (size) -> PointerInfo.ShapeSizeInfo in
                    return (CGSize(width: max(44, size.width), height: 36), 8)
                }
            )
        )
        return item
    }

    public func setGroupAvatar(entityId: String?, avatarKey: String?, completion: ((UIImage?, Error?) -> Void)? = nil) {
        guard let key = avatarKey else {
            completion?(nil, nil)
            return
        }
        // 部分接口返回中rust没有处理好avatarKey,此处做容错，待rust修正后去除
        let fixedKey = key.replacingOccurrences(of: "lark.avatar/", with: "")
        groupAvatar.bt.setLarkImage(with: .avatar(key: fixedKey, entityID: entityId ?? ""),
                                    trackStart: {
                                        return TrackInfo(scene: .Profile, fromType: .avatar)
                                    },
                                    completion: { result in
                                        switch result {
                                        case let .success(imageResult):
                                            completion?(imageResult.image, nil)
                                        case let .failure(error):
                                            completion?(nil, error)
                                        }
                                    })
    }

    public func updateBackgoundImageViewBouncesZoom(_ offset: CGFloat) {
        let screenSize = UIScreen.main.bounds
        if offset < -self.thresholdOffset, offset > -screenSize.height {
            let offsetY = abs(offset) - self.thresholdOffset
            self.containerBackgoundView?.snp.updateConstraints({ (make) in
                make.top.equalTo(-offset)
            })

            self.backgroundImageView?.snp.updateConstraints({ (make) in
                make.top.equalToSuperview()
                make.height.equalTo(self.thresholdOffset + offsetY)
            })
        }

        if offset >= -self.thresholdOffset, offset < 0 {
            let offsetY = self.thresholdOffset - abs(offset)
            self.containerBackgoundView?.snp.updateConstraints({ (make) in
                make.height.equalTo(screenSize.height + offsetY)
                make.top.equalTo(-offset)
            })

            let minHeight: CGFloat = 180
            if -offset >= minHeight {
                self.backgroundImageView?.snp.updateConstraints({ (make) in
                    make.top.equalToSuperview().offset(-offsetY)
                    make.height.equalTo(self.thresholdOffset)
                })
            } else {
                self.backgroundImageView?.snp.updateConstraints({ (make) in
                    make.top.equalToSuperview().offset(minHeight - self.thresholdOffset)
                    make.height.equalTo(self.thresholdOffset)
                })
            }
        }
    }

    private func navigationItem(image: UIImage, highlightImage: UIImage, title: String? = nil, selector: Selector, target: Any) -> UIView {
        let item = UIButton(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        item.hitTestEdgeInsets = UIEdgeInsets(top: -10, left: -20, bottom: -10, right: -20)
        item.setTitle(title, for: .normal)
        item.setImage(image, for: .normal)
        item.setImage(highlightImage, for: .highlighted)
        item.addTarget(target, action: selector, for: .touchUpInside)
        return item
    }

    private func addBlurShadow(on view: UIView) {
        view.layoutIfNeeded()
        let shadowPath = UIBezierPath(rect: view.bounds)
        view.layer.masksToBounds = false
        view.layer.ud.setShadowColor(UIColor.ud.shadowDefaultSm)
        view.layer.shadowOffset = CGSize(width: 0, height: 5)
        view.layer.shadowRadius = 6
        view.layer.shadowOpacity = 0.2
        view.layer.shadowPath = shadowPath.cgPath
    }
}
