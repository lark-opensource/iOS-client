//
//  ShareContentMagicShareHeaderView.swift
//  ByteView
//
//  Created by liurundong.henry on 2021/9/4.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import UIKit
import RxSwift
import UniverseDesignIcon

class ShareContentMagicShareHeaderView: UITableViewHeaderFooterView {

    var tapSearchBarClosure: (() -> Void)?

    private let searchBarBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloat
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.layer.cornerRadius = 10.0
        return view
    }()

    private let searchBar: SearchBarView = {
        let searchBar = SearchBarView(frame: .zero)
        searchBar.iconImageLeftMargin = 8.0
        searchBar.iconImageToContentMargin = 8.0
        searchBar.iconImageDimension = 18.0
        searchBar.iconImageView.image = UDIcon.getIconByKey(.searchOutlined, iconColor: .ud.iconN3, size: CGSize(width: 18.0, height: 18.0))
        searchBar.setPlaceholder(I18n.View_M_Search, attributes: [
            .foregroundColor: UIColor.ud.textPlaceholder,
            .font: UIFont.systemFont(ofSize: 16.0)
        ])
        searchBar.layer.cornerRadius = 6.0
        searchBar.textField.isUserInteractionEnabled = false
        searchBar.contentView.layer.cornerRadius = 6.0
        searchBar.contentView.backgroundColor = UIColor.ud.N900.withAlphaComponent(0.05)
        return searchBar
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = UIColor.ud.bgFloatBase
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        addSubview(searchBarBackgroundView)
        searchBarBackgroundView.addSubview(searchBar)

        searchBarBackgroundView.snp.makeConstraints { maker in
            maker.left.right.bottom.equalToSuperview()
            maker.height.equalTo(60.0)
        }
        searchBar.snp.makeConstraints { maker in
            maker.left.right.equalToSuperview().inset(16.0)
            maker.top.equalToSuperview().offset(16.0)
            maker.height.equalTo(36.0)
        }
    }

    func configTapAction(tapSearchBarClosure searchClosure: @escaping (() -> Void)) {
        self.tapSearchBarClosure = searchClosure
        let tapGr = UITapGestureRecognizer(target: self, action: #selector(tapSearchBar))
        searchBar.addGestureRecognizer(tapGr)
    }

    func handleEnabled(_ isEnabled: Bool) {
        isUserInteractionEnabled = isEnabled
    }

    @objc
    func tapSearchBar() {
        self.tapSearchBarClosure?()
    }

}
