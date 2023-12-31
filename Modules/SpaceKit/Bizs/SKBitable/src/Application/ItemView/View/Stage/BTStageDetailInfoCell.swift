//
//  BTStageDetailInfoCell.swift
//  SKBitable
//
//  Created by X-MAN on 2023/5/29.
//

import Foundation
import UniverseDesignColor
import UniverseDesignIcon
import SKBrowser
import UniverseDesignNotice
import SKResource

final class BTStageDetailInfoCell: UICollectionViewCell {
    
    private var model: BTFieldModel = BTFieldModel(recordID: "")
    private var currentOptionId: String = ""
    private let sepLine = UIView()
//    private let topLine = UIView()
    private let inset: CGFloat = 15.0
    
    // UI 显示的数据，过滤endDone和endCancel
    private var dataSource: [BTStageModel] {
        return model.property.stages.filter({ $0.type == .defualt })
    }
    
    weak var delegate: BTFieldDelegate?
    
    private lazy var indictatorView: BTStageStateIndicatorView = {
        let view = BTStageStateIndicatorView(frame: .zero)
        return view
    }()
    
    private lazy var moreButton: UIButton = {
        let button = UIButton()
        let icon = UDIcon.moreOutlined
        button.setImage(icon, for: [.normal, .highlighted])
        button.addTarget(self, action: #selector(moreButtonClick), for: .touchUpInside)
        return button
    }()
    
    private lazy var processorView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.contentInset = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
        view.delegate = self
        view.dataSource = self
        view.showsHorizontalScrollIndicator = false
        view.backgroundColor = .clear
        view.register(BTStageProcessorItemView.self, forCellWithReuseIdentifier: BTStageProcessorItemView.reuseIdentifier)
        return view
    }()
    
    private lazy var convertView: BTStageDetailConvertView = {
        let convertView = BTStageDetailConvertView(frame: .zero)
        return convertView
    }()
    
    private lazy var stopNotice: UDNotice = {
        let attr = NSMutableAttributedString(string: BundleI18n.SKResource.Bitable_Flow_RecordCard_Ended_Toast, attributes: [.font: UIFont.systemFont(ofSize: 14), .foregroundColor: UDColor.textTitle])
        var config = UDNoticeUIConfig(type: .warning, attributedText: attr)
        var notice = UDNotice(config: config)
        notice.delegate = self
        notice.layer.cornerRadius = 4.0
        return notice
    }()
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        sepLine.backgroundColor = UDColor.lineBorderCard
//        topLine.backgroundColor = UDColor.lineBorderCard
//        contentView.addSubview(topLine)
        contentView.addSubview(stopNotice)
        contentView.addSubview(indictatorView)
        contentView.addSubview(processorView)
        contentView.addSubview(moreButton)
        contentView.addSubview(sepLine)
        contentView.addSubview(convertView)
        
//        topLine.snp.makeConstraints { make in
//            make.top.leading.trailing.equalToSuperview()
//            make.height.equalTo(0.5)
//        }
        
        stopNotice.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(12)
//            make.trailing.equalToSuperview().offset(-12)
//            make.top.equalTo(topLine.snp.bottom).offset(12)
        }
        
        moreButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(17)
            make.trailing.equalToSuperview().offset(-16)
            make.size.equalTo(16)
        }
        indictatorView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalTo(stopNotice.snp.bottom)
            make.height.equalTo(58)
            make.trailing.equalTo(moreButton.snp.leading).offset(-12)
        }
        processorView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(indictatorView.snp.bottom).offset(2)
            make.height.equalTo(40)
        }
        sepLine.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.top.equalTo(processorView.snp.bottom).offset(40)
            make.height.equalTo(0.5)
        }
        convertView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.top.equalTo(sepLine.snp.bottom)
        }
        
        convertView.convertButtonClick = { [weak self] in
            guard let self = self else { return }
            self.delegate?.stageDetailFieldClickDone(fieldModel: self.model, currentOptionId: self.currentOptionId)
        }
        convertView.revertButtonClick = { [weak self] sourceView in
            guard let self = self else { return }
            self.delegate?.stageDetailFieldClickRevert(sourceView: sourceView, fieldModel: self.model, currentOptionId: self.currentOptionId)
        }
    }
    
    func setData(_ model: BTFieldModel) {
        self.model = model
        let canceled = model.isStageCancel
        if let currentOptionId = model.optionIDs.first,
            let currentOption = dataSource.first(where: { $0.id == currentOptionId }) {
            self.currentOptionId = currentOptionId
            let hasPermission = model.fieldPermission?.stageConvert.contains(where: {
                $0.key == currentOptionId && $0.value == true
            }) ?? true && model.editable
            convertView.setData(currentOption, canceled: canceled, hasPermission: hasPermission)
        }
        if !model.editable {
            moreButton.isHidden = true
        } else {
            moreButton.isHidden = canceled
        }
        // cancel状态都显示，但是不可编辑不能recover
        stopNotice.isHidden = !canceled
        var config = stopNotice.config
        config.leadingButtonText = model.editable ? BundleI18n.SKResource.Bitable_Flow_RecordCard_RestoreStep_Button : nil
        stopNotice.updateConfigAndRefreshUI(config)
        indictatorView.snp.remakeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalTo(stopNotice.isHidden ? contentView.snp.top : stopNotice.snp.bottom)
            make.height.equalTo(58)
            make.trailing.equalTo(moreButton.snp.leading).offset(-12)
        }
        processorView.reloadData()
    }
    
    @objc
    private func moreButtonClick() {
        // 点击更多
        let cancelOptionId = model.property.stages.first(where: { $0.type == .endCancel })?.id ?? ""
        delegate?.stageDetailFieldClickCancel(sourceView: moreButton, fieldModel: model, cancelOptionId: cancelOptionId)
    }
}

extension BTStageDetailInfoCell: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BTStageProcessorItemView.reuseIdentifier, for: indexPath)
        if let cell = cell as? BTStageProcessorItemView,
           var stage = dataSource.safe(index: indexPath.row) {
            let style: BTStageProcessorItemView.Style
            switch indexPath.row {
            case 0:
                style = .first
            case dataSource.count - 1:
                style = .last
            default:
                style = .center
            }
            stage.isCurrent = stage.id == currentOptionId
            var color: UIColor? = nil
            if stage.status == .progressing {
                let colorHex = model.colors.first(where: { $0.id == stage.color })?.color
                color = UIColor.docs.rgb(colorHex ?? "")
            }
            cell.config(stage, style: style, progressingColor: color)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard indexPath.row < dataSource.count else {
            return .zero
        }
        let contentWidth: CGFloat = (model.width - 2.0 * inset) / 3.0
        return CGSize(width: contentWidth, height: 40)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 通知刷新
        delegate?.stageDetailFieldChange(with: indexPath.row)
    }
    
}

extension BTStageDetailInfoCell: UDNoticeDelegate {
    
    func handleLeadingButtonEvent(_ button: UIButton) {
        delegate?.stageDetailFieldClickRecover(fieldModel: model)

    }
    
    func handleTrailingButtonEvent(_ button: UIButton) {
        delegate?.stageDetailFieldClickRecover(fieldModel: model)
    }
    
    func handleTextButtonEvent(URL: URL, characterRange: NSRange) {
    }
}
