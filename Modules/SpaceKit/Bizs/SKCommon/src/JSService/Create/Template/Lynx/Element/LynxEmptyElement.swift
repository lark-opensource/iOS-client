//
//  LynxEmptyElement.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2021/11/12.
//  


import Foundation
import Lynx
import UniverseDesignEmpty
import UniverseDesignButton
import UIKit

class EmptyView: UIView {
    private var udEmpty: UDEmpty?
    func update(config: UDEmptyConfig) {
        if let udEmpty = udEmpty {
            udEmpty.removeFromSuperview()
        }
        let udEmpty = UDEmpty(config: config)
        self.addSubview(udEmpty)
        udEmpty.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.udEmpty = udEmpty
    }
}

class LynxEmptyElement: LynxUI<EmptyView> {
    private var emptyConfig = UDEmptyConfig(type: .noContent)
    
    static let name = "ud-empty"
    override var name: String {
        return Self.name
    }
    
    override func createView() -> EmptyView {
        return EmptyView()
    }
    
    override func layoutDidFinished() {
        super.layoutDidFinished()
        self.view().update(config: emptyConfig)
    }
    
    @objc
    public static func propSetterLookUp() -> [[String]] {
        return [
            ["img-res-id-str", NSStringFromSelector(#selector(setImgResIdStr(value:requestReset:)))],
            ["image-size", NSStringFromSelector(#selector(setImageSize(value:requestReset:)))],
            ["title", NSStringFromSelector(#selector(setTitle(value:requestReset:)))],
            ["desc", NSStringFromSelector(#selector(setDesc(value:requestReset:)))],
            ["primary-text", NSStringFromSelector(#selector(setButtonConfig(value:requestReset:)))],
            ["image-bottom-margin", NSStringFromSelector(#selector(setImageBottomMargin(value:requestReset:)))],
            ["title-bottom-margin", NSStringFromSelector(#selector(setTitleBottomMargin(value:requestReset:)))]
        ]
    }
    @objc
    func setImgResIdStr(value: String, requestReset: Bool) {
        emptyConfig.type = UDEmptyType(id: value) ?? .noContent
        view().update(config: emptyConfig)
        self.view().update(config: emptyConfig)
    }
    @objc
    func setImageSize(value: NSNumber, requestReset: Bool) {
        emptyConfig.imageSize = value.intValue
        view().update(config: emptyConfig)
        self.view().update(config: emptyConfig)
    }
    @objc
    func setTitle(value: String, requestReset: Bool) {
        emptyConfig.title = UDEmptyConfig.Title(titleText: value)
        view().update(config: emptyConfig)
        self.view().update(config: emptyConfig)
    }
    @objc
    func setDesc(value: String, requestReset: Bool) {
        emptyConfig.description = UDEmptyConfig.Description(descriptionText: value)
        view().update(config: emptyConfig)
        self.view().update(config: emptyConfig)
    }
    @objc
    func setImageBottomMargin(value: NSNumber, requestReset: Bool) {
        let space = CGFloat(value.floatValue)
        emptyConfig.spaceBelowImage = space
        view().update(config: emptyConfig)
        self.view().update(config: emptyConfig)
    }
    @objc
    func setTitleBottomMargin(value: NSNumber, requestReset: Bool) {
        let space = CGFloat(value.floatValue)
        emptyConfig.spaceBelowTitle = space
        view().update(config: emptyConfig)
        self.view().update(config: emptyConfig)
    }
    @objc
    func setButtonConfig(value: String, requestReset: Bool) {
        guard !value.isEmpty else {
            // 未设置button，lynx会传过来空字符，需要重置隐藏掉
            emptyConfig.primaryButtonConfig = nil
            self.view().update(config: emptyConfig)
            return
        }
        let config: (String, (UIButton) -> Void) = (value, { [weak self] _ in
            guard let self = self else { return }
            let event = LynxDetailEvent(name: "primaryclick", targetSign: self.sign, detail: nil)
            self.context?.eventEmitter?.send(event)
        })
        emptyConfig.primaryButtonConfig = config
        self.view().update(config: emptyConfig)
    }
}

extension UDEmptyType {
    init?(id: String) {
        let mapper: [String: UDEmptyType] = [
            "illustration_empty_neutral_no_content": .noContent,
            "illustration_empty_negative_load_failed": .loadingFailure,
            "illustration_empty_neutral_no_data": .noData,
            "illustration_empty_neutral_no_file": .noFile
        ]
        guard let type = mapper[id] else {
            return nil
        }
        self = type
    }
}
