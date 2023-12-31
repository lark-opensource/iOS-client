//
//  DetailAncestorTaskView.swift
//  Todo
//
//  Created by 迟宇航 on 2022/7/18.
//

import CTFoundation
import UIKit
import UniverseDesignIcon

protocol DetailAncestorTaskViewDataType {
    var items: [DetailAncestorItemData]? { get }
}

final class DetailAncestorTaskView: UIView, ViewDataConvertible {

    var viewData: DetailAncestorTaskViewDataType? {
        didSet {
            guard let viewData = viewData, let items = viewData.items else {
                isHidden = true
                return
            }
            isHidden = false
            updateAncestorTaskList(with: items)
        }
    }
    var onTapAncestorHandler: ((String?) -> Void)?

    private let containerView = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setComponents()
        setConstraints()
        setApperance()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setComponents() {
        addSubview(containerView)
    }

    private func setConstraints() {
        containerView.axis = .vertical
        containerView.spacing = 4
        containerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
        }
    }

    private func setApperance() {
        backgroundColor = UIColor.ud.bgBody
    }

    private func updateAncestorTaskList(with list: [DetailAncestorItemData]) {
        containerView.arrangedSubviews.forEach {
            containerView.removeArrangedSubview($0)
            // 必须调用removeFromSuperview。不然不能被销毁
            $0.removeFromSuperview()
        }
        if list.isEmpty {
            // 自身需要隐藏
            isHidden = true
            containerView.isHidden = true
        } else {
            isHidden = false
            containerView.isHidden = false
            for item in list.prefix(4) {
                let itemView = DetailAncestorItemView()
                itemView.onTapAncestorHandler = { [weak self] guid in
                    guard item.guid == guid else { return }
                    self?.onTapAncestorHandler?(guid)
                }
                itemView.viewData = item
                containerView.addArrangedSubview(itemView)
            }
        }
    }
}

// MARK: - Item Struct
struct DetailAncestorItemData {
    // 标题
    var titleInfo: (title: AttrText, outOfRangeText: AttrText)
    // guid
    var guid: String
}

final class DetailAncestorItemView: UIView {

    var viewData: DetailAncestorItemData? {
        didSet {
            titleLabel.clearRenderContent()
            titleLabel.outOfRangeText = viewData?.titleInfo.outOfRangeText
            titleLabel.attributedText = viewData?.titleInfo.title
        }
    }

    var onTapAncestorHandler: ((String?) -> Void)?

    private lazy var titleLabel: RichContentLabel = {
        var titleLabel = RichContentLabel()
        titleLabel.isUserInteractionEnabled = false
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.numberOfLines = 1
        return titleLabel
    }()
    private lazy var iconView: UIImageView = {
        let iconView = UIImageView()
        iconView.image = UDIcon.getIconByKey(
            .rightOutlined,
            iconColor: UIColor.ud.iconDisabled,
            size: CGSize(width: 12, height: 12)
        )
        return iconView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setComponents()
        setApperance()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: Self.noIntrinsicMetric, height: 24)
    }

    private func setComponents() {
        addSubview(titleLabel)
        addSubview(iconView)
        titleLabel.snp.makeConstraints { make in
            make.left.top.equalToSuperview()
            make.height.equalTo(24)
            make.width.lessThanOrEqualToSuperview().offset(-20)
        }
        iconView.snp.makeConstraints { make in
            make.left.equalTo(titleLabel.snp.right).offset(4)
            make.centerY.equalTo(titleLabel.snp.centerY)
            make.height.width.equalTo(12)
        }
    }

    private func setApperance() {
        backgroundColor = UIColor.ud.bgBody
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTapAncestorItem))
        self.addGestureRecognizer(tap)
    }

    @objc
    private func onTapAncestorItem() {
        onTapAncestorHandler?(viewData?.guid)
    }

}
