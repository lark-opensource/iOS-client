//
//  BitableFormResultView.swift
//  SKBitable
//
//  Created by ZhangYuanping on 2022/4/17.
//  


import SKFoundation
import SKResource
import UniverseDesignColor
import UniverseDesignEmpty
import UniverseDesignFont
import SKUIKit

protocol BitableFormResultViewDelegate: AnyObject {
    /// 再填一次表单
    func refillForm(baseId: String, tableId: String, callback: String)
}

final class BitableFormResultView: UIView {
    weak var delegate: BitableFormResultViewDelegate?
    
    private lazy var emptyConfig: UDEmptyConfig = {
        let config = UDEmptyConfig(title: .init(titleText: ""),
                                   description: nil,
                                   imageSize: 120,
                                   spaceBelowImage: 30,
                                   spaceBelowTitle: 8,
                                   type: .done,
                                   labelHandler: nil,
                                   primaryButtonConfig: nil,
                                   secondaryButtonConfig: nil)
        return config
    }()
    
    private(set) lazy var resultView: UDEmpty = {
        let view = UDEmpty(config: emptyConfig)
        return view
    }()
    
    init() {
        DocsLogger.btInfo("[LifeCycle] BitableFormResultView init")
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        DocsLogger.btInfo("[LifeCycle] BitableFormResultView deinit")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        var offset = 64
        if UIApplication.shared.statusBarOrientation.isLandscape && SKDisplay.phone {
            offset = 0
        }
        resultView.snp.updateConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-offset)
        }
    }
    
    func update(data: FormResultViewData) {
        emptyConfig.title = .init(titleText: data.title, font: UDFont.title2)
        let fillAgainText = BundleI18n.SKResource.Bitable_Form_FillInAgain
        if data.resubmitEnable {
            let resubmitConfig: (String?, (UIButton) -> Void)? = (fillAgainText, { [weak self] button in
                guard let self = self else { return }
                self.removeFromSuperview()
                self.delegate?.refillForm(baseId: data.baseId, tableId: data.tableId, callback: data.actionCallback)
            })
            emptyConfig.spaceBelowTitle = 30
            emptyConfig.description = nil
            emptyConfig.primaryButtonConfig = resubmitConfig
        } else {
            emptyConfig.description = .init(descriptionText: data.description)
            emptyConfig.spaceBelowTitle = 8
            emptyConfig.primaryButtonConfig = nil
        }
        resultView.update(config: emptyConfig)
    }
    
    private func setupUI() {
        backgroundColor = UDColor.bgBody
        addSubview(resultView)
        resultView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-64)
        }
    }
    
}

extension BitableFormResultView {
    struct FormResultViewData {
        let title: String
        let description: String
        let resubmitEnable: Bool
        let baseId: String
        let tableId: String
        let actionCallback: String
    }
}
