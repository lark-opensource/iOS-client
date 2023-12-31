//
//  SearchEntrenceOnPadView.swift
//  LarkSearch
//
//  Created by chenyanjie on 2023/11/9.
//

import Foundation
import LarkContainer
import UniverseDesignIcon
import UniverseDesignFont
import UniverseDesignColor

public protocol SearchEntrenceOnPadViewDelegate: AnyObject {
    func cancelSaveState(isSelected: Bool?)
}

class SearchEntrenceOnPadView: UIView {
    weak var delegate: SearchEntrenceOnPadViewDelegate?
    lazy var searchContainerView: UIView = {
        let view = UIView()
        return view
    }()

    lazy var backGroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 10
        view.layer.borderWidth = 1
        return view
    }()

    lazy var iconView: UIImageView = {
        var imageView = UIImageView()
        imageView.image = UDIcon.searchOutlined.ud.withTintColor(UIColor.ud.iconN1)
        return imageView
    }()

    lazy var closeIcon: UIImageView = {
        var imageView = UIImageView()
        imageView.image = UDIcon.getIconByKey(.closeFilled, size: CGSize(width: 17, height: 17)).ud.withTintColor(UIColor.ud.N400)
        let gesture = UITapGestureRecognizer(target: self, action: #selector(closeIconTapped(_:)))
        imageView.addGestureRecognizer(gesture)
        imageView.isHidden = true
        return imageView
    }()

    lazy var defaultLabel: UILabel = {
        var label = UILabel()
        label.text = BundleI18n.LarkSearch.Lark_Search_iPad_SearchBoxPlaceholder_SearchShortcutKey("⌘+K")
        label.textColor = UIColor.ud.staticBlack60 & UIColor.ud.staticWhite80
        label.font = UDFont.systemFont(ofSize: 16)
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    lazy var queryTextLabel: UILabel = {
        var label = UILabel()
        label.text = ""
        label.textColor = UIColor.ud.staticBlack60 & UIColor.ud.staticWhite80
        label.font = UDFont.systemFont(ofSize: 16)
        label.isHidden = true
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    @objc func closeIconTapped(_ gesture: UITapGestureRecognizer) {
        self.cancelSaveState()
        self.delegate?.cancelSaveState(isSelected: self.isSelect)
    }

    let userResolver: UserResolver
    var isSelect = false

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setupView() {
        addSubview(backGroundView)
        addSubview(iconView)
        addSubview(searchContainerView)
        searchContainerView.addSubview(closeIcon)
        searchContainerView.addSubview(defaultLabel)
        searchContainerView.addSubview(queryTextLabel)

        backGroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(18)
        }

        searchContainerView.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(10)
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
            make.height.equalTo(42)
        }

        defaultLabel.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
        }

        closeIcon.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-13)
            make.width.height.equalTo(16.5)
            make.centerY.equalToSuperview()
        }

        queryTextLabel.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.lessThanOrEqualTo(closeIcon.snp.left).offset(-5)
            make.centerY.equalToSuperview()
        }

        changeSelectedState(isSelect: false)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let layoutProgress = max(0, min(1, (self.frame.width - 58) / 166))
        updateUI(layoutProgress: layoutProgress)
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        if searchContainerView.alpha == 0 { return hitView } //窄栏
        let convertPoint = closeIcon.convert(point, from: self)
        if closeIcon.bounds.contains(convertPoint) { return closeIcon }
        return hitView
    }

    func updateUI(layoutProgress: CGFloat) {
        let horizontalAlpha = max(0, min(1, (layoutProgress - 0.5) * 2))
        searchContainerView.alpha = horizontalAlpha

        iconView.btd_width = 24 - 4 * horizontalAlpha
        iconView.btd_height = 24 - 4 * horizontalAlpha
        iconView.btd_x = 18 - 5 * horizontalAlpha
        iconView.btd_y = 9 + 2 * horizontalAlpha

        if horizontalAlpha == 1 || horizontalAlpha == 0 {
            changeSelectedState(isSelect: self.isSelect)
        }
    }

    // MARK: public
    func queryTextChange(query: String?) {
        defaultLabel.isHidden = true
        queryTextLabel.isHidden = true
        closeIcon.isHidden = true
        if let query = query, !query.isEmpty {
            queryTextLabel.text = BundleI18n.LarkSearch.Lark_Search_iPad_SearchBoxPlaceholder_QueryCache(query)
            queryTextLabel.isHidden = false
            closeIcon.isHidden = false
        } else {
            defaultLabel.isHidden = false
        }
    }

    func changeSelectedState(isSelect: Bool) {
        if self.isSelect != isSelect {
            self.isSelect = isSelect
        }
        backGroundView.layer.ud.setBorderColor(UIColor.clear)
        if isSelect {
            backGroundView.backgroundColor = UIColor.ud.staticWhite70 & UIColor.ud.N90010
        } else if searchContainerView.alpha == 0 { //窄栏 非选中
            backGroundView.backgroundColor = UIColor.clear
        } else {
            backGroundView.backgroundColor = UIColor.ud.staticBlack5 & UIColor.ud.staticWhite5
            backGroundView.layer.ud.setBorderColor(UIColor.ud.staticBlack5 & UIColor.ud.staticWhite5)
        }
    }

    func cancelSaveState() {
        defaultLabel.isHidden = false
        queryTextLabel.text = ""
        queryTextLabel.isHidden = true
        closeIcon.isHidden = true
    }
}
