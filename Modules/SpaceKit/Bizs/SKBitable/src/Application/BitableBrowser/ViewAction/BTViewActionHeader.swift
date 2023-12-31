//
//  BTViewActionHeader.swift
//  SKBitable
//
//  Created by X-MAN on 2023/9/12.
//

import Foundation
import UniverseDesignFont
import UniverseDesignColor
import UniverseDesignButton
import UniverseDesignIcon

struct BTViewActionSyncButtonModel: Codable {
    enum State: String, Codable {
        case show
//        case loading
//        case finish
        case hide
    }
    var text: String?
    var state: State = .hide
    var btnAction: String = ""
}

final class BTViewActionHeader: UIView {
    
    private lazy var closeButton: UIButton = {
        let button = UIButton()
        var image = UDIcon.closeSmallOutlined.ud.resized(to: CGSize(width: 24.0, height: 24.0))
        image = image.ud.withTintColor(UDColor.iconN1)
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(closeButtonClick), for: .touchUpInside)
        return button
    }()
    
    private lazy var titleLaebl: UILabel = {
        let label = UILabel()
        label.font = UDFont.title3
        label.textColor = UDColor.textTitle
        return label
    }()
    
    private lazy var syncButton: UDButton = {
        let button = UDButton()
        return button
    }()
    
    private lazy var dragViewLine = UIView().construct { it in
        it.backgroundColor = UDColor.lineBorderCard
        it.layer.cornerRadius = 2
    }
    
    private var model: BTViewActionSyncButtonModel = BTViewActionSyncButtonModel(text: "", state: .hide)
    
    var syncClick: (() -> Void)?
    
    var closeClick: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        addSubview(closeButton)
        addSubview(dragViewLine)
        addSubview(titleLaebl)
        addSubview(syncButton)
        dragViewLine.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.centerX.equalToSuperview()
            make.width.equalTo(40)
            make.height.equalTo(4)
        }
        syncButton.snp.makeConstraints { make in
            // UDButton文本有内边距
            make.right.equalToSuperview().offset(-4)
            make.centerY.equalTo(titleLaebl)
            make.height.equalTo(24)
        }
        syncButton.isHidden = true
    }
    
    func updateRegular(_ regular: Bool) {
        dragViewLine.isHidden = regular
        closeButton.isHidden = !regular
        if !regular {
            // iPhone模式
            titleLaebl.snp.remakeConstraints { make in
                make.top.equalTo(dragViewLine.snp.bottom).offset(10)
                make.left.equalToSuperview().offset(16)
                make.right.lessThanOrEqualTo(syncButton.snp.left)
            }
        } else {
            closeButton.snp.remakeConstraints { make in
                make.left.equalToSuperview().offset(16)
                make.top.equalTo(18)
            }
            
            titleLaebl.snp.remakeConstraints { make in
                make.centerY.equalTo(closeButton)
                make.centerX.equalToSuperview()
                make.left.greaterThanOrEqualTo(closeButton.snp.right).offset(8)
                make.right.lessThanOrEqualTo(syncButton.snp.left).offset(-8)
            }
        }
        
    }
    
    func setTitle(_ title: String?) {
        titleLaebl.text = title
    }
    
    func setData(model: BTViewActionSyncButtonModel) {
        self.model = model
        let successColor = UDColor.functionSuccessContentDefault
        let normalColor = UDColor.functionInfoContentDefault
        let font = UIFont.systemFont(ofSize: 16)
        switch model.state {
        case .hide:
//            syncButton.hideLoading()
            syncButton.isHidden = true
        case .show:
            let normalTheme = UDButtonUIConifg.ThemeColor(borderColor: .clear,
                                                          backgroundColor: .clear,
                                                          textColor: normalColor)
            let config = UDButtonUIConifg(normalColor: normalTheme, loadingIconColor: normalColor)
            syncButton.config = config
            syncButton.setTitle(model.text, for: .normal)
            syncButton.titleLabel?.font = font
            syncButton.isHidden = false
            syncButton.addTarget(self, action: #selector(syncButtonClick), for: .touchUpInside)
//        case .loading:
//            let normalTheme = UDButtonUIConifg.ThemeColor(borderColor: .clear,
//                                                          backgroundColor: .clear,
//                                                          textColor: normalColor)
//            let loadingTheme = UDButtonUIConifg.ThemeColor(borderColor: .clear,
//                                                           backgroundColor: .clear,
//                                                           textColor: normalColor)
//            var config = UDButtonUIConifg(normalColor: normalTheme,
//                                          loadingColor: loadingTheme,
//                                          loadingIconColor: normalColor)
//            config.type = .middle
//            syncButton.config = config
//            syncButton.setTitle(model.text, for: .normal)
//            syncButton.showLoading()
//        case .finish:
//            syncButton.hideLoading()
//            let themeColor = UDButtonUIConifg.ThemeColor(borderColor: .clear,
//                                                          backgroundColor: .clear,
//                                                          textColor: successColor)
//            let config = UDButtonUIConifg(normalColor: themeColor)
//            syncButton.config = config
//            syncButton.setTitle(model.text, for: .normal)
//            let icon = UDIcon.doneOutlined.ud.withTintColor(successColor)
//            syncButton.setImage(icon, for: .normal)
//            syncButton.removeTarget(self, action: #selector(syncButtonClick), for: .touchUpInside)
        }
    }
    
    @objc
    private func syncButtonClick() {
        self.syncClick?()
    }
    
    @objc
    private func closeButtonClick() {
        self.closeClick?()
    }
}
