//
//  SearchNaviBar.swift
//  LarkUIKit
//
//  Created by CharlieSu on 2018/11/27.
//

import Foundation
import UIKit

public final class SearchNaviBar: UIView {
    private let topPlaceHolderView = UIView()
    private let contentView = UIView()
    public let searchbar: SearchBar

    public init(style: SearchBarLeftButtonStyle) {
        searchbar = SearchBar(style: style)
        super.init(frame: .zero)

        addSubview(topPlaceHolderView)
        topPlaceHolderView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(20)
        }

        addSubview(contentView)
        contentView.snp.makeConstraints { (make) in
            make.top.equalTo(topPlaceHolderView.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(44)
            make.bottom.equalToSuperview()
        }

        contentView.addSubview(searchbar)
        searchbar.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(12)
            make.right.equalToSuperview().offset(-12)
            make.top.bottom.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func safeAreaInsetsDidChange() {
        if self.safeAreaInsets.top != 0 {
            topPlaceHolderView.snp.updateConstraints({ (make) in
                make.height.equalTo(self.safeAreaInsets.top)
            })
        }
    }
}
