//
//  SearchEmptyView.swift
//  LarkOpenPlatform
//
//  Created by houjihu on 2021/3/23.
//

import LarkUIKit
import UniverseDesignEmpty

/// 搜索结果为空的提示视图
class SearchEmptyView: UIView {
    private lazy var emptyDetailLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()

    init() {
        super.init(frame: .zero)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        let imageView = UIImageView()
        imageView.image = UDEmptyType.noSearchResult.defaultImage()
        addSubview(imageView)
        imageView.snp.makeConstraints({ (make) in
            make.width.height.equalTo(125)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(123)
        })

        addSubview(self.emptyDetailLabel)
        emptyDetailLabel.snp.makeConstraints({ (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(imageView.snp.bottom).offset(10)
        })
    }

    func updateViews(tips: String) {
        emptyDetailLabel.text = tips
    }
}
