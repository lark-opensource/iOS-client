//
//  FileListBlankView.swift
//  SpaceKit
//
//  Created by litao_dev on 2019/8/28.
//  

import SKFoundation
import SKResource
import UniverseDesignColor
import UniverseDesignEmpty

public final class TemplateListBlankView: UIView {
    public let emptyView: UDEmpty
    public let button: UIButton = UIButton(type: .custom).construct { it in
        it.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        it.setTitleColor(UDColor.textLinkNormal, for: .normal)
        it.isHidden = true
    }

    init(title: String, desc: String) {
        let titleConfig = UDEmptyConfig.Title(titleText: title,
                                              font: .systemFont(ofSize: 17, weight: .medium))
        let descConfig = UDEmptyConfig.Description(descriptionText: desc,
                                                   font: .systemFont(ofSize: 14, weight: .regular))
        let config = UDEmptyConfig(title: titleConfig,
                                   description: descConfig,
                                   spaceBelowImage: 20,
                                   spaceBelowTitle: 8,
                                   spaceBelowDescription: 0,
                                   spaceBetweenButtons: 0,
                                   type: .noContent)
        emptyView = UDEmpty(config: config)
        emptyView.backgroundColor = UDColor.bgBase
        super.init(frame: .zero)
        setupSubviews()
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        self.backgroundColor = UDColor.bgBase
        
        self.addSubview(button)
        button.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        self.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(button.snp.top).offset(-24)
        }

        
    }
}
