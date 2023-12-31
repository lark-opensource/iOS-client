//
//  InlineAISecondaryOperationView.swift
//  LarkInlineAI
//
//  Created by liujinwei on 2023/6/26.
//  


import Foundation
import SnapKit
import UniverseDesignIcon
import UniverseDesignColor

final class InlineAISheetOperationView: InlineAIItemBaseView {
    
    private let contentView = UIView()
    private let textLabel = UILabel()
    private let imageView = UIImageView()
    
    struct Metric {
        static let cornerRadius: CGFloat = 4
        static let maxWidth: CGFloat = 347
        static let verticalInset: CGFloat = 12
        static let buttonFont = UIFont.systemFont(ofSize: 14)
        static let contentOffset: CGFloat = 8
        static let contentHeight: CGFloat = 24
        static let contentTopOffset: CGFloat = 6
        static let contentBottomOffset: CGFloat = 6
        static let imageSize = CGSize(width: 14, height: 14)
        static let labelHeight: CGFloat = 20
        static let imageOffset: CGFloat = 5
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupInit()
        setupLayout()
        contentView.addSubview(textLabel)
        contentView.addSubview(imageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupInit() {
        contentView.layer.cornerRadius = Metric.cornerRadius
        contentView.backgroundColor = UDColor.bgFiller
        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapView)))
        textLabel.numberOfLines = 0
        textLabel.preferredMaxLayoutWidth = Metric.maxWidth
        textLabel.font = Metric.buttonFont
        textLabel.lineBreakMode = .byTruncatingTail
    }
    
    @objc
    func tapView() {
        eventRelay.accept(.chooseSheetOperation)
    }
    
    private func setupLayout() {
        addSubview(contentView)
        contentView.addSubview(textLabel)
        contentView.addSubview(imageView)
        
        contentView.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset(Metric.contentBottomOffset)
            make.top.equalToSuperview().inset(Metric.contentTopOffset)
            make.left.equalToSuperview()
            make.height.equalTo(Metric.contentHeight)
            make.right.equalTo(imageView.snp.right).offset(Metric.imageOffset)
        }
        textLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(Metric.contentOffset)
            make.centerY.equalToSuperview()
            make.height.equalTo(Metric.labelHeight)
        }
        imageView.snp.makeConstraints { make in
            make.left.equalTo(textLabel.snp.right).offset(Metric.contentOffset)
            make.centerY.equalToSuperview()
            make.size.equalTo(Metric.imageSize)
        }
    }
    
    func update(operate: InlineAIPanelModel.SheetOperate?) {
        guard let operate else { return }
        textLabel.text = operate.text
        if operate.enable {
            textLabel.textColor = nil
            imageView.image = UDIcon.editOutlined
            contentView.isUserInteractionEnabled = true
        } else {
            textLabel.textColor = UDColor.textLinkDisabled
            imageView.image = UDIcon.editOutlined.ud.withTintColor(UDColor.iconDisabled)
            contentView.isUserInteractionEnabled = false
        }
    }
    
}
