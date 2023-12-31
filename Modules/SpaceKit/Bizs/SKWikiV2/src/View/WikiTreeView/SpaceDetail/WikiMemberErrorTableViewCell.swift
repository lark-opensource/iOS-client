//
//  WikiMemberErrorTableViewCell.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2019/12/25.
//

import UIKit
import SnapKit
import SKCommon
import SKResource
import UniverseDesignColor
import UniverseDesignEmpty

class WikiMemberErrorTableViewCell: UITableViewCell {
    
    private lazy var errorView: UDEmptyView = {
        let errorView = UDEmptyView(config: .init(title: .init(titleText: ""),
                                                  description: .init(descriptionText: BundleI18n.SKResource.Doc_Facade_NetworkInterrutedRetry),
                                                  imageSize: 100,
                                                  type: .loadingFailure,
                                                  labelHandler: nil,
                                                  primaryButtonConfig: nil,
                                                  secondaryButtonConfig: nil))
        errorView.useCenterConstraints = true
        return errorView
    }()

    var retryBlock: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        retryBlock = nil
    }

    private func setupUI() {
        contentView.addSubview(errorView)
        errorView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didClick))
        contentView.addGestureRecognizer(tapGesture)
    }

    @objc
    private func didClick() {
        retryBlock?()
    }
}
