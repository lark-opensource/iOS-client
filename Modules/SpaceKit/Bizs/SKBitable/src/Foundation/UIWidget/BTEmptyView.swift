//
//  BTEmptyView.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/7/14.
//  


import Foundation
import UniverseDesignColor
import UniverseDesignEmpty


final class BTEmptyView: UIView {
    
    struct UIConfig {
        var backgroudColor: UIColor
    }
    
    private lazy var udEmptyView = UDEmptyView(config: createConfig(type: .noData, desc: "")).construct { it in
        it.backgroundColor = UDColor.bgFloatBase
        it.useCenterConstraints = true
    }
    
    enum ShowType {
        case showNoData(desc: String)
        case showNoRearchResult(desc: String)
        case noAccess(desc: String)
        case hide
        case show
    }

    init() {
        super.init(frame: .zero)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateShowType(_ type: ShowType) {
        self.isHidden = false
        switch type {
        case .hide:
            self.isHidden = true
        case .show:
            self.isHidden = false
        case .showNoData(let desc):
            udEmptyView.update(config: createConfig(type: .noContent, desc: desc))
        case .showNoRearchResult(let desc):
            udEmptyView.update(config: createConfig(type: .searchFailed, desc: desc))
        case .noAccess(let desc):
            udEmptyView.update(config: createConfig(type: .noAccess, desc: desc))
        }
    }
    
    func updateConfig(_ config: UDEmptyConfig) {
        udEmptyView.update(config: config)
    }
    
    func updateUIConfig(_ config: UIConfig) {
        udEmptyView.backgroundColor = config.backgroudColor
    }
    
    private func setupViews() {
        self.clipsToBounds = true
        self.isHidden = true
        self.addSubview(udEmptyView)
        udEmptyView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    private func createConfig(type: UDEmptyType, desc: String) -> UDEmptyConfig {
        return UDEmptyConfig(
            title: .init(titleText: ""),
            description: .init(descriptionText: desc),
            type: type,
            labelHandler: nil,
            primaryButtonConfig: nil,
            secondaryButtonConfig: nil
        )
    }
}
