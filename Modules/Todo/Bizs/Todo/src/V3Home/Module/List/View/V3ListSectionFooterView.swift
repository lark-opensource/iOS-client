//
//  V3ListSectionFooterView.swift
//  Todo
//
//  Created by wangwanxin on 2022/8/24.
//

import Foundation
import UIKit
import UniverseDesignFont

// MARK: - Section Footer
///     +----------------------------------------+
///     | content - 48?                          |
///     | section space - 16!                    |
///     +----------------------------------------+
///

final class V3ListSectionFooterView: UICollectionReusableView {

    var viewData: V3ListSectionFooterData? {
        didSet {
            guard let viewData = viewData else {
                isHidden = true
                return
            }
            if viewData.isFold {
                titleLable.isHidden = true
                containerView.isHidden = true
            } else {
                titleLable.isHidden = viewData.isHidden
                containerView.isHidden = viewData.isHidden
            }
        }
    }

    var tapSectionHandler: (() -> Void)?

    private(set) lazy var containerView: UIView = {
        let view = UIView()
        view.isHidden = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(clickSectionFooter))
        view.addGestureRecognizer(tap)
        view.backgroundColor = ListConfig.Cell.bgColor
        return view
    }()
    private lazy var titleLable: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.isHidden = true
        label.font = UDFont.systemFont(ofSize: 16)
        label.text = I18N.Todo_Task_AddTask
        return label
    }()

    // 用于section space
    private lazy var spaceView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        addSubview(containerView)
        containerView.addSubview(titleLable)
        addSubview(spaceView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        typealias Config = ListConfig.Section
        var offsetY: CGFloat = 0
        if !containerView.isHidden {
            containerView.frame = CGRect(
                x: ListConfig.Cell.leftPadding,
                y: 0,
                width: bounds.width - ListConfig.Cell.leftPadding - ListConfig.Cell.rightPadding,
                height: Config.footerTitleHeight
            )
            titleLable.frame = CGRect(
                x: Config.footerLeftPadding,
                y: 0,
                width: frame.width - Config.footerLeftPadding - Config.horizontalPadding,
                height: Config.footerTitleHeight
            )
            offsetY = Config.footerTitleHeight
        }
        spaceView.frame = CGRect(
            x: 0,
            y: offsetY,
            width: frame.width,
            height: Config.footerSpaceHeight
        )
    }

    @objc
    func clickSectionFooter() {
        tapSectionHandler?()
    }
}
