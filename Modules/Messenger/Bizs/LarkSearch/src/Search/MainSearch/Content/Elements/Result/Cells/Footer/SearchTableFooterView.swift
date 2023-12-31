//
//  File.swift
//  LarkSearch
//
//  Created by SuPeng on 4/18/19.
//

import UIKit
import Foundation
import RxSwift
import LarkInteraction
import UniverseDesignIcon

protocol SearchFooterProtocol: UITableViewHeaderFooterView, KeyBoardFocusable {
    func set(viewModel: SearchFooterViewModel?)
}

final class SearchTableFooterView: UITableViewHeaderFooterView, SearchFooterProtocol {
    var viewModel: SearchFooterViewModel?

    private let topContentView = UIView()
    private let bottomSeperatorView = UIView()
    private let divider = UIView()
    private let actionImageView = UIImageView()
    private let actionLabel = UILabel()
    private let arrowImageView = UIImageView(image: UDIcon.getIconByKey(.rightBoldOutlined, size: CGSize(width: 12, height: 12)).ud.withTintColor(.ud.iconN3))

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        topContentView.backgroundColor = UIColor.ud.bgBody
        topContentView.roundCorners(corners: [.bottomLeft, .bottomRight], radius: 8.0)
        contentView.addSubview(topContentView)
        topContentView.snp.makeConstraints { (make) in
            make.left.top.right.equalToSuperview()
            make.height.equalTo(12)
        }
        bottomSeperatorView.backgroundColor = UIColor.ud.bgBase
        contentView.addSubview(bottomSeperatorView)
        bottomSeperatorView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(topContentView.snp.bottom)
            make.height.equalTo(8)
        }
        divider.backgroundColor = UIColor.ud.lineDividerDefault
        divider.isHidden = true
        topContentView.addSubview(divider)
        divider.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.right.equalToSuperview().inset(16)
            make.top.equalToSuperview()
            make.height.equalTo(1)
        }

        actionImageView.isHidden = true
        topContentView.addSubview(actionImageView)

        actionLabel.font = UIFont.systemFont(ofSize: 16)
        actionLabel.textColor = UIColor.ud.textLinkNormal
        actionLabel.isHidden = true
        topContentView.addSubview(actionLabel)

        arrowImageView.isHidden = true
        topContentView.addSubview(arrowImageView)

        actionImageView.snp.makeConstraints({ make in
            make.top.leading.equalToSuperview().offset(16)
            make.width.height.equalTo(16)
        })

        actionLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(actionImageView.snp.trailing).offset(8)
            make.trailing.equalTo(arrowImageView.snp.leading).offset(-8)
            make.centerY.equalTo(actionImageView)
        }

        arrowImageView.snp.makeConstraints({ make in
            make.centerY.equalTo(actionImageView)
            make.trailing.equalToSuperview().offset(-16)
            make.width.height.equalTo(12)
        })

        topContentView.lu.addTapGestureRecognizer(action: #selector(didClickFooter), target: self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(viewModel: SearchFooterViewModel?) {
        defer {
            self.viewModel = viewModel
        }
        if let _viewMode = viewModel {
            topContentView.snp.remakeConstraints { (make) in
                make.left.top.right.equalToSuperview()
                make.height.equalTo(48)
            }

            actionImageView.image = _viewMode.icon
            actionLabel.text = _viewMode.actionText
            actionLabel.textColor = _viewMode.titleColor

            divider.isHidden = false
            actionImageView.isHidden = false
            actionLabel.isHidden = false
            arrowImageView.isHidden = false
        } else {
            topContentView.snp.remakeConstraints { (make) in
                make.left.top.right.equalToSuperview()
                make.height.equalTo(12)
            }
            divider.isHidden = true
            actionImageView.isHidden = true
            actionLabel.isHidden = true
            arrowImageView.isHidden = true
        }
    }

    @objc
    private func didClickFooter() {
        viewModel?.footerTappingAction(self)
    }

    func setFocused(_ focused: Bool, animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.25) {
                self.actionLabel.backgroundColor = focused ? UIColor.ud.fillFocus : UIColor.ud.bgBody
            }
        } else {
            actionLabel.backgroundColor = focused ? UIColor.ud.fillFocus : UIColor.ud.bgBody
        }
    }
}
