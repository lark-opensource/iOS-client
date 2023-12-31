//
//  MeetingCollectionNaviBar.swift
//  ByteViewTab
//
//  Created by fakegourmet on 2022/6/8.
//

import Foundation
import UniverseDesignIcon
import UniverseDesignColor
import ByteViewNetwork

class MeetingCollectionNavigationBar: UIView {

    var backgroundView = UIView()
    var backButton = UIButton()
    var navigationTitle = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayout()
    }

    func setupSubviews() {
        backgroundColor = .clear
        backgroundView.backgroundColor = UIColor.ud.bgFloat

        backButton.setImage(UDIcon.getIconByKey(.leftOutlined, iconColor: UIColor.ud.iconN1), for: .normal)

        addSubview(backgroundView)
        addSubview(backButton)
        addSubview(navigationTitle)

        updateLayout()
        updateBgAlpha(0.0)
    }

    func updateLayout() {
        backgroundView.snp.remakeConstraints {
            $0.edges.equalToSuperview()
        }
        navigationTitle.snp.remakeConstraints {
            $0.centerY.equalTo(backButton)
            $0.left.equalTo(backButton.snp.right).offset(8.0)
        }
        backButton.snp.remakeConstraints {
            $0.left.equalToSuperview().inset(16.0)
            if traitCollection.isRegular {
                $0.top.equalToSuperview().inset(34.0)
            } else {
                $0.top.equalToSuperview().inset(54.0)
            }
        }
    }

    func bindViewModel(collection: CollectionInfo) {
        navigationTitle.attributedText = .init(string: collection.titleContent,
                                               config: .h3,
                                               alignment: .left,
                                               lineBreakMode: .byTruncatingTail,
                                               textColor: UIColor.ud.textTitle)
    }

    func setTitle(_ title: String) {
        navigationTitle.attributedText = .init(string: title,
                                               config: .h3,
                                               alignment: .left,
                                               lineBreakMode: .byTruncatingTail,
                                               textColor: UIColor.ud.textTitle)
    }

    func updateBgAlpha(_ alpha: CGFloat) {
        let alpha = min(1, max(0, alpha))
        backgroundView.alpha = alpha
        navigationTitle.alpha = alpha
    }
}
