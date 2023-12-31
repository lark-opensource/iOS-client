//
//  EmptyListPlaceholderCell.swift
//  SpaceKit
//
//  Created by nine on 2019/7/25.
//

import Foundation
import SKCommon
import SKResource
import UniverseDesignEmpty

class DirectoryPickerEmptyPlaceholderCell: UICollectionViewCell {
    public enum EmptyType: Int {
        case noList = 1
        case noShareFolder
    }

    lazy var emptyView: UDEmptyView = {
        let emptyView = UDEmptyView(config: .init(title: .init(titleText: ""),
                                                  description: .init(descriptionText: ""),
                                                  imageSize: 100,
                                                  type: .noContent))
        emptyView.useCenterConstraints = true
        return emptyView
    }()

    public override init(frame _: CGRect) {
        super.init(frame: CGRect.zero)
        addSubview(emptyView)
        emptyView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    public func config(with type: EmptyType, title: String?, keyword _: String?) {
        var config = emptyConfig(for: type)
        config.description = .init(descriptionText: title ?? "")
        emptyView.update(config: config)
    }

    private func emptyConfig(for emptyType: EmptyType) -> UDEmptyConfig {
        var config = UDEmptyConfig(title: .init(titleText: ""),
                                   description: .init(descriptionText: ""),
                                   type: .noContent)
        switch emptyType {
            case .noList:
                config.type = .noContent
            case .noShareFolder:
                config.type = .noContent
        }
        return config
    }

    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
