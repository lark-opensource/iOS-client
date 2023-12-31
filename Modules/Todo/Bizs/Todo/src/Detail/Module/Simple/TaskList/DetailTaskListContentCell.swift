//
//  DetailTaskListContentCell.swift
//  Todo
//
//  Created by wangwanxin on 2022/12/23.
//

import Foundation
import LarkSwipeCellKit
import UniverseDesignIcon
import UniverseDesignFont

struct DetailTaskListContentData {

    var taskListGuid: String

    var taskListText: String

    var sectionText: String

    var hideArrow: Bool = false
}

final class DetailTaskListContentCell: SwipeTableViewCell {

    static let cellHeight: CGFloat = 36.0
    static let sectionFooterHeight: CGFloat = 8.0

    var viewData: DetailTaskListContentData? {
        didSet {
            guard let viewData = viewData else {
                isHidden = true
                return
            }
            isHidden = false
            leftView.text = viewData.taskListText
            rightView.text = viewData.sectionText
            rightView.hideArrow = viewData.hideArrow
        }
    }

    var onTapLeftHandler: (() -> Void)?
    var onTapRightHandler: (() -> Void)? {
        didSet { rightView.onTapHandler = onTapRightHandler }
    }

    private lazy var leftView = DetailTaskListContentLeftView()
    private lazy var rightView = DetailTaskListContentRightView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        swipeView.backgroundColor = UIColor.ud.bgBody
        contentView.backgroundColor = UIColor.ud.bgBody
        swipeView.addSubview(leftView)
        leftView.label.textAlignment = .center
        swipeView.addSubview(rightView)
        let left = UITapGestureRecognizer(target: self, action: #selector(onLeftViewClick))
        leftView.addGestureRecognizer(left)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // 这里有一些碰撞检测，手动布局更为合适,
        /**
         基本规则是【清单】和【分组】最小宽度是64；
         if
         当都可以展示下的时候，都展示；
         else
         优先展示能展示下的那一方;
         否则 都展示不开则6 4开
         */
        let taskListSize = leftView.label.sizeThatFits(
            CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        )
        let sectionSize = rightView.label.sizeThatFits(
            CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        )
        // total一共可显示内容的宽度, 去掉各种icon，space等
        let totalMaxWidth = bounds.width - 16 - 48 - 14
        // rightMaxWidth 需要额外减去icon的宽和左右padding
        let leftMaxWidth = bounds.width - 64 - 24 - 16, rightMaxWidth = bounds.width - 64 - 32 - 14 - 16
        if taskListSize.width + sectionSize.width >= totalMaxWidth {
            switch (taskListSize.width - leftMaxWidth >= 0, sectionSize.width - rightMaxWidth >= 0) {
            case (true, true), (false, false):
                let leftWidth = totalMaxWidth * 0.6, rightWidth = totalMaxWidth * 0.4
                leftView.frame = CGRect(x: 0, y: 0, width: leftWidth + 16, height: 36)
                rightView.frame = CGRect(
                    x: leftView.frame.maxX + 8,
                    y: 0,
                    width: rightWidth + 38,
                    height: 36
                )
            case (true, false):
                leftView.frame = CGRect(x: 0, y: 0, width: totalMaxWidth - sectionSize.width + 16, height: 36)
                rightView.frame = CGRect(
                    x: leftView.frame.maxX + 8,
                    y: 0,
                    width: sectionSize.width + 38,
                    height: 36
                )
            case (false, true):
                leftView.frame = CGRect(x: 0, y: 0, width: taskListSize.width + 16, height: 36)
                rightView.frame = CGRect(
                    x: leftView.frame.maxX + 8,
                    y: 0,
                    width: totalMaxWidth - taskListSize.width + 38,
                    height: 36
                )
            }
        } else {
            leftView.frame = CGRect(x: 0, y: 0, width: max(taskListSize.width + 16, 64), height: 36)

            rightView.frame = CGRect(
                x: leftView.frame.maxX + 8,
                y: 0,
                width: max(sectionSize.width + 16 + 22, 64),
                height: 36
            )
        }
    }

    @objc
    private func onLeftViewClick() {
        onTapLeftHandler?()
    }

    static func getLabel() -> UILabel {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = UDFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textTitle
        label.textAlignment = .center
        return label
    }

}

final class DetailTaskListContentRightView: UIView {

    var text: String? {
        didSet { label.text = text }
    }
    var hideArrow: Bool = false {
        didSet { arrowView.isHidden = hideArrow }
    }

    var onTapHandler: (() -> Void)?

    private lazy var arrowView: UIImageView = {
        let icon = UDIcon.getIconByKey(
            .downOutlined,
            iconColor: UIColor.ud.iconN1,
            size: CGSize(width: 14.0, height: 14.0)
        )
        return UIImageView(image: icon)
    }()
    private(set) lazy var label = DetailTaskListContentCell.getLabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(label)
        addSubview(arrowView)
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTap))
        addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = CGRect(x: 8, y: (bounds.height - 20) * 0.5, width: bounds.width - 38, height: 20)
        arrowView.frame = CGRect(x: label.frame.maxX + 8, y: (bounds.height - 14) * 0.5, width: 14, height: 14)
    }

    @objc
    private func onTap() {
        onTapHandler?()
    }

    override var intrinsicContentSize: CGSize {
        let width = label.intrinsicContentSize.width + arrowView.frame.width + 24.0
        return CGSize(width: width, height: 20)
    }

}

final class DetailTaskListContentLeftView: UIView {

    var text: String? {
        didSet { label.text = text }
    }

    private(set) lazy var label = DetailTaskListContentCell.getLabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 8
        layer.masksToBounds = true
        backgroundColor = UIColor.ud.bgBodyOverlay
        addSubview(label)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = CGRect(x: 8, y: 8, width: bounds.width - 16, height: 20)
    }

}

final class DetailTaskListContentFooterView: UITableViewHeaderFooterView {

    private lazy var containerView = UIView()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        addSubview(containerView)
        containerView.backgroundColor = UIColor.ud.bgBody
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
