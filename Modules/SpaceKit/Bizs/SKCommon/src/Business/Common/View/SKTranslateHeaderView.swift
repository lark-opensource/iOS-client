//
//  SKTranslateHeaderView.swift
//  SKCommon
//
//  Created by tanyunpeng on 2023/8/8.
//  


import UIKit
import EENavigator
import SKCommon
import SKUIKit
import SKFoundation
import SKResource
import UniverseDesignIcon
import UniverseDesignColor
import RxSwift

public typealias SKCenterViewClickCallback = (_ data: SKCenterViewData) -> Void

public struct SKCenterViewData {
    public var title: String? // 标题文字
    public var position: String? // 标题位置
    public var isLoading: Bool? // 标题是否处于isLoading态
    public var titleIcon: String? //标题icon
    public var id: String?       // 标题id
    public var clickable: Bool?  // 是否可点击
    public var showFoldBtn: Bool? //是否展示折叠按钮
    
    public var viewTypeImage: UIImage? {
        var image: UIImage?
        guard let type = titleIcon else {
            return nil
        }
        switch type {
        case "empty": image = nil
        case "translate": image = UDIcon.translateOutlined.ud.withTintColor(UDColor.iconN2)
        default:
            // 不应该走到这里
            let msg = "use titleIcon error"
            DocsLogger.error(msg)
            assertionFailure(msg)
        }
        return image
    }
    
    public init() {
    }
}

public class SKCenterViewButton: UIView {
    
    fileprivate var callback: SKCenterViewClickCallback?
    fileprivate var centerViewData: SKCenterViewData?
    
    fileprivate lazy var translateBtn: UIButton = {
        let btn = UIButton()
        btn.addTarget(self, action: #selector(makeLanguageChangeVC), for: .touchUpInside)
        btn.setImage(UDIcon.translateOutlined.ud.withTintColor(UDColor.iconN2), for: .normal)
        return btn
    }()

    fileprivate lazy var selectLanBtn: UIButton = {
        let lanBtn: UIButton
        lanBtn = UIButton()
        lanBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        lanBtn.setTitleColor(UDColor.textTitle, for: .normal)
        lanBtn.setTitleColor(UDColor.textPlaceholder, for: .highlighted)
        lanBtn.setTitle(BundleI18n.SKResource.Doc_Doc_LanguageJapanese, for: .normal)
        lanBtn.addTarget(self, action: #selector(makeLanguageChangeVC), for: .touchUpInside)
        if SKDisplay.pad {
            lanBtn.addTarget(self, action: #selector(selectTouchDown), for: .touchDown)
            lanBtn.addTarget(self, action: #selector(selectTouchCancel), for: .touchCancel)
            lanBtn.addTarget(self, action: #selector(selectTouchCancel), for: .touchDragExit)
        }
        return lanBtn
    }()

    fileprivate lazy var selectTranslateBtn: UIButton = {
        let btn: UIButton
        btn = UIButton()
        btn.addTarget(self, action: #selector(makeLanguageChangeVC), for: .touchUpInside)
        btn.setImage(BundleResources.SKResource.Common.Tool.icon_expand_down_filled.ud.withTintColor(UDColor.iconN2), for: .normal)
        btn.setImage(BundleResources.SKResource.Common.Tool.icon_expand_down_filled.ud.withTintColor(UDColor.iconN3), for: .highlighted)
        if SKDisplay.pad {
            btn.addTarget(self, action: #selector(selectTouchDown), for: .touchDown)
            btn.addTarget(self, action: #selector(selectTouchCancel), for: .touchCancel)
            btn.addTarget(self, action: #selector(selectTouchCancel), for: .touchDragExit)
        }
        return btn
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupSubviews()
    }


    private func setupSubviews() {
        addSubview(translateBtn)
        addSubview(selectTranslateBtn)
        addSubview(selectLanBtn)
        setupConstraints()
    }

    private func setupConstraints() {
        selectTranslateBtn.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.height.width.equalTo(16)
        }
        selectLanBtn.snp.makeConstraints { (make) in
            make.right.equalTo(selectTranslateBtn.snp.left).offset(-4)
            make.centerX.centerY.equalToSuperview()
            make.height.equalTo(22)
        }
        translateBtn.snp.makeConstraints { (make) in
            make.right.equalTo(selectLanBtn.snp.left).offset(-4)
            make.centerY.equalTo(selectLanBtn.snp.centerY)
            make.width.height.equalTo(20)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    private func makeLanguageChangeVC() {
        guard let centerViewData = self.centerViewData else {
            DocsLogger.warning("translateData is nil")
            return
        }
        guard let callback = callback else {
            DocsLogger.warning("callback is nil")
            return
        }
        guard let id = centerViewData.id else {
            DocsLogger.warning("id is nil")
            return
        }
        callback(centerViewData)
    }
    
    @objc
    func selectTouchDown() {
        self.selectLanBtn.isHighlighted = true
        self.selectTranslateBtn.isHighlighted = true
    }

    @objc
    func selectTouchCancel() {
        self.selectLanBtn.isHighlighted = false
        self.selectTranslateBtn.isHighlighted = false
    }
    
    public func setSelectLanBtn(_ data: SKCenterViewData, callback: SKCenterViewClickCallback?) {
        self.callback = callback
        self.centerViewData = data
        DocsLogger.info("update catalog views")
        if let title = data.title {
            selectLanBtn.setTitle(title, for: .normal)
        } else {
            selectLanBtn.setTitle("", for: .normal)
        }
        if let showButton = data.showFoldBtn ,showButton {
            selectTranslateBtn.isHidden = false
        } else {
            selectTranslateBtn.isHidden = true
        }
        if let titleIcon = data.titleIcon, let icon = data.viewTypeImage {
            translateBtn.setImage(icon, for: .normal)
            translateBtn.isHidden = false
        } else {
            translateBtn.setImage(nil, for: .normal)
            translateBtn.isHidden = true
        }
    }
}

