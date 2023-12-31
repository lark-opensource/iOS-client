//
//  BTStageIndicatorView.swift
//  SKBitable
//
//  Created by X-MAN on 2023/6/15.
//

import Foundation
import UniverseDesignColor
import UniverseDesignFont
import SKResource

fileprivate final class BTStageStateIndicator: UIView {
    private lazy var indicator: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 4
        view.layer.borderWidth = 0.8
        return view
    }()
    
    private lazy var textLabel: UILabel = {
        let label = UILabel()
        label.font = UDFont.systemFont(ofSize: 12)
        label.textColor = UDColor.textCaption
        return label
    }()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(indicator)
        addSubview(textLabel)
        indicator.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(8)
        }
        textLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(indicator.snp.trailing).offset(4)
        }
    }
    
    func config(name: String, backgroundColor: UIColor, boardColor: UIColor) {
        textLabel.text = name
        indicator.backgroundColor = backgroundColor
        indicator.layer.borderColor = boardColor.cgColor
    }
    func width() -> CGFloat {
        textLabel.sizeToFit()
        return textLabel.frame.width + 12
    }
}

final class BTStageStateIndicatorView: UIView {
    
    private let notStartText = BundleI18n.SKResource.Bitable_Flow_RecordCard_NotStarted_Text
    private let progressingText = BundleI18n.SKResource.Bitable_Flow_RecordCard_InProgress_Text
    private let doneText = BundleI18n.SKResource.Bitable_Flow_RecordCard_Done_Text
    
    private lazy var notStartIndicator: BTStageStateIndicator = {
        let indicator = BTStageStateIndicator()
        indicator.config(name: notStartText, backgroundColor: UDColor.N350, boardColor: UDColor.N500)
        return indicator
    }()
    
    private lazy var processingIndicator: BTStageStateIndicator = {
        let indicator = BTStageStateIndicator()
        indicator.config(name: progressingText, backgroundColor: UDColor.O200, boardColor: UDColor.O350)
        return indicator
    }()
    
    private lazy var doneIndicator: BTStageStateIndicator = {
        let indicator = BTStageStateIndicator()
        indicator.config(name: doneText, backgroundColor: UDColor.G300, boardColor: UDColor.G500)
        return indicator
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        addSubview(notStartIndicator)
        addSubview(processingIndicator)
        addSubview(doneIndicator)
        notStartIndicator.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.width.equalTo(notStartIndicator.width())
        }
        processingIndicator.snp.makeConstraints { make in
            make.leading.equalTo(notStartIndicator.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
            make.width.equalTo(processingIndicator.width())
        }
        doneIndicator.snp.makeConstraints { make in
            make.leading.equalTo(processingIndicator.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
            make.width.equalTo(doneIndicator.width())
        }
    }
}
