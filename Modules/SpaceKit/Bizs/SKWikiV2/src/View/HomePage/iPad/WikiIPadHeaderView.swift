//
//  WikiIPadHeaderView.swift
//  SKWikiV2
//
//  Created by Weston Wu on 2023/9/26.
//

import UIKit
import SnapKit
import UniverseDesignColor
import UniverseDesignIcon
import SpaceInterface
import SKResource
import SKWorkspace
import RxSwift

class WikiIPadHeaderView: UIView {

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .medium)
        label.text = BundleI18n.SKResource.Doc_Facade_Wiki
        return label
    }()

    private(set) lazy var createView: WorkspaceCreateView = {
        let view = WorkspaceCreateView(enableObservable: enableObeservable)
        view.setTemplate(hidden: true)
        return view
    }()
    
    private let enableObeservable: Observable<Bool>

    init(enableObeservable: Observable<Bool>) {
        self.enableObeservable = enableObeservable
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(12)
            make.left.right.equalToSuperview().inset(24)
            make.height.equalTo(32)
        }
        addSubview(createView)
        createView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.left.right.equalToSuperview()
            make.height.equalTo(64)
            make.bottom.equalToSuperview().inset(24)
        }
    }
}
