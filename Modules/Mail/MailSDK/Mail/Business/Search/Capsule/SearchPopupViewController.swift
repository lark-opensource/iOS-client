//
//  SearchPopupViewController.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2023/11/15.
//

import Foundation
import LarkUIKit
import SnapKit

final class SearchPopupViewController: BaseUIViewController {

    private let contentView: ISearchPopupContentView

    init(contentView: ISearchPopupContentView) {
        self.contentView = contentView
        super.init(nibName: nil, bundle: nil)
        self.view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.contentView.updateContainerSize(size: self.view.frame.size)
    }

}
