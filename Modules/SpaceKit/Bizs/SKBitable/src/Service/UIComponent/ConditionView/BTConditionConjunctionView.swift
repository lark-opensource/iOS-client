//
//  BTConditionConjunctionView.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/7/15.
//  

import UIKit
import UniverseDesignColor
import UniverseDesignIcon
import SKResource
import SKFoundation
import SpaceInterface

public struct BTConditionConjuctionModel {
    var id: String
    var text: String
    var disableAction: Bool?
}

struct BTNewConditionConjunctionModel: BTWidgetModelProtocol, Codable {
    struct Center: BTWidgetModelProtocol, Codable {
        var backgroundColor: String?
        var borderColor: String?
        var content: BTTextWidgetModel?
        var icon: BTImageWidgetModel?
        var onClick: String?
    }
    var onClick: String?
    var backgroundColor: String?
    var borderColor: String?
    var center: Center?
    var left: BTTextWidgetModel?
    var right: BTTextWidgetModel?
    
}

// 顶部选择所有和任一的视图
final class BTConditionConjunctionView: UIView {
    
    var didTapConjuctionButton: ((BTConditionSelectButton) -> Void)?
    
    private let prefixLabel = UILabel().construct {
        $0.textColor = UDColor.textTitle
        $0.font = .systemFont(ofSize: 16)
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
    
    private let subfixLabel = UILabel().construct {
        $0.textColor = UDColor.textTitle
        $0.lineBreakMode = .byTruncatingTail
        $0.font = .systemFont(ofSize: 16)
    }
    
    private lazy var conjuctionBtn = BTConditionSelectButton(frame: .zero).construct {
        $0.addTarget(self, action: #selector(conjuctionBtnTapped), for: .touchUpInside)
    }
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        self.backgroundColor = UDColor.bgFloat
        self.layer.cornerRadius = 10
        
        addSubview(prefixLabel)
        addSubview(conjuctionBtn)
        addSubview(subfixLabel)
        
        let text = BundleI18n.SKResource.Bitable_Relation_MeetFollowingCondition("##")
        let components = text.components(separatedBy: "##")
        prefixLabel.text = components.first
        subfixLabel.text = components.count > 1 ? components[1] : nil
        
        prefixLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
        }
        conjuctionBtn.snp.makeConstraints { make in
            make.height.equalTo(28)
            make.centerY.equalToSuperview()
            make.left.equalTo(prefixLabel.snp.right).offset(8)
        }
        subfixLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(conjuctionBtn.snp.right).offset(8)
            make.right.lessThanOrEqualToSuperview().offset(-16)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configModel(_ model: BTConditionConjuctionModel) {
        conjuctionBtn.update(text: model.text, textColor: UDColor.textTitle)
        if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
            if model.disableAction == true {
                conjuctionBtn.update(text: model.text, textColor: UDColor.textDisabled)
            } else {
                conjuctionBtn.update(text: model.text, textColor: UDColor.textTitle)
            }
        }
    }
    
    func setData(_ model: BTNewConditionConjunctionModel) {
        conjuctionBtn.update(text: model.center?.content?.text ?? "", textColor: UDColor.textTitle)
        prefixLabel.text = model.left?.text
        subfixLabel.text = model.right?.text
    }
    
    @objc
    private func conjuctionBtnTapped(_ btn: BTConditionSelectButton) {
        self.didTapConjuctionButton?(btn)
    }
}

public final class BTConditionConjunctionCell: UITableViewCell {
    
    var didTapConjuctionButton: ((BTConditionSelectButton) -> Void)? {
        didSet {
            conjuctionView.didTapConjuctionButton = didTapConjuctionButton
        }
    }
    
    private var conjuctionView = BTConditionConjunctionView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        backgroundColor = .clear

        contentView.addSubview(conjuctionView)
        conjuctionView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview()
        }
    }
    
    func configModel(_ model: BTConditionConjuctionModel) {
        conjuctionView.configModel(model)
    }
    
    func setData(_ model: BTNewConditionConjunctionModel) {
        conjuctionView.setData(model)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
