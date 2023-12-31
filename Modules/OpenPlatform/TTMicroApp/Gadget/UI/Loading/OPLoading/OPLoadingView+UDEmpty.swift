//
//  OPLoadingView+UDEmpty.swift
//  OPSDK
//
//  Created by liuyou on 2021/5/21.
//

import Foundation
import UniverseDesignEmpty
import SnapKit

@objc public extension OPLoadingView {
    
    enum EmptyViewImageType: String {
        case loadError = "loadError"
        case serverError = "serverError"
        case noNetwork = "noNetwork"
    }
    
    func createEmptyView(tipInfo: String, retryBlock: @escaping (UIButton) -> Void) -> UDEmpty {
        let config = UDEmptyConfig(
            title: nil,
            description: .init(descriptionText: tipInfo, font: .systemFont(ofSize: 15), textAlignment: .left),
            type: .loadingFailure,
            primaryButtonConfig: (BDPI18n.retry, retryBlock)
        )
        let emptyView = UDEmpty(config: config)
        addSubview(emptyView)
        emptyView.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
            maker.leading.equalToSuperview().offset(15)
            maker.trailing.equalToSuperview().offset(-15)
        }

        return emptyView
    }
    
    @nonobjc func createEmptyView(imageType:EmptyViewImageType,title: String,content: String,primaryText:String?,primaryCallback: @escaping (UIButton) -> Void) -> UDEmpty {
        
        // 错误配置和UD组件的枚举类型映射关系，默认值.error
        var type :UDEmptyType = .error
        switch imageType {
        case .loadError:
            type = .error
        case .serverError:
            type = .code500
        case .noNetwork:
            type = .noWifi
        default:
            type = .error
        }
        
        let config = UDEmptyConfig(
            title: .init(titleText: title, font: .systemFont(ofSize: 17)),
            description: .init(descriptionText: content, font: .systemFont(ofSize: 14), textAlignment: .center),
            type: type,
            primaryButtonConfig: (primaryText, primaryCallback)
        )
        let emptyView = UDEmpty(config: config)
        addSubview(emptyView)
        emptyView.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
            maker.leading.equalToSuperview().offset(15)
            maker.trailing.equalToSuperview().offset(-15)
        }

        return emptyView
    }

}
