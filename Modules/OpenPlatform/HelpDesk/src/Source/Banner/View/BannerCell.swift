//
//  BannerCell.swift
//  LarkHelpdesk
//
//  Created by yinyuan on 2021/8/27.
//

import Foundation
import UniverseDesignButton
import LarkSetting

private let cellHeight: CGFloat = 30
private let cellPadding: CGFloat = 8
private let imageIconWidth: CGFloat = 16
private let imageTitleMarging: CGFloat = 4
private let cornerRadius: CGFloat = 6

class BannerCell: UICollectionViewCell {

    private lazy var progressView: UDButton = {
        let progressView = UDButton(.init(
                                        normalColor: .init(
                                            borderColor: .clear,
                                            backgroundColor: .clear,
                                            textColor: .ud.textTitle
                                        ),
                                        loadingColor: .init(
                                            borderColor: .clear,
                                            backgroundColor: .clear,
                                            textColor: .ud.primaryContentDefault
                                        ),
                                        loadingIconColor: .ud.primaryContentDefault,
                                        type: .custom(
                                            type: (
                                                        size: .init(
                                                            width: imageIconWidth,
                                                            height: imageIconWidth),
                                                        inset: 0,
                                                        font: .systemFont(ofSize: 14),
                                                        iconSize: .init(
                                                            width: imageIconWidth,
                                                            height: imageIconWidth
                                                        )
                                            )
                                        )))
        progressView.layer.masksToBounds = false
        progressView.backgroundColor = .red
        return progressView
    }()
    
    /// 图标
    private lazy var icon: ThemeImageView = {
        let icon = ThemeImageView()
        icon.contentMode = .scaleAspectFit
        return icon
    }()
    
    /// 标题
    private lazy var label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        contentView.clipsToBounds = false
        contentView.addSubview(icon)
        contentView.addSubview(label)
        contentView.addSubview(progressView)
        
        contentView.layer.cornerRadius = cornerRadius
        contentView.layer.borderWidth = 0
        
        setHighlight(highlight: false)
        
        icon.snp.makeConstraints { make in
            make.width.height.equalTo(imageIconWidth)
            make.left.equalToSuperview().offset(cellPadding)
            make.centerY.equalToSuperview()
        }

        label.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-cellPadding)
            make.left.equalToSuperview().offset(cellPadding)
            make.height.equalToSuperview()
        }
        
        progressView.snp.makeConstraints { make in
            make.width.height.equalTo(imageIconWidth)
            make.left.equalToSuperview().offset(cellPadding)
            make.centerY.equalToSuperview()
        }
        
        progressView.setTitle(nil, for: .normal)
        progressView.showLoading()
    }

    func setContent(with model: BannerCellViewModel) {
        label.text = model.getText()
        if model.loading {
            // 有 loading
            icon.isHidden = true
            progressView.isHidden = false
            progressView.showLoading()
            
            label.snp.updateConstraints { make in
                make.left.equalToSuperview().offset(cellPadding+imageIconWidth+imageTitleMarging)
            }
            
            contentView.backgroundColor = .ud.N00.withAlphaComponent(0.5)
            contentView.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
            label.textColor = .ud.udtokenComponentTextDisabledLoading
            
        } else if model.hasImage() {
            // 有图标
            icon.themedImageKey = model.bannerResource.resourceView.image_url_themed ?? model.bannerResource.resourceView.image_key_themed
            
            icon.isHidden = false
            progressView.isHidden = true
            progressView.hideLoading()
            
            label.snp.updateConstraints { make in
                make.left.equalToSuperview().offset(cellPadding+imageIconWidth+imageTitleMarging)
            }
            
            setHighlight(highlight: false)
        } else {
            // 无图标，无 Loading
            icon.isHidden = true
            progressView.isHidden = true
            progressView.hideLoading()
            
            label.snp.updateConstraints { make in
                make.left.equalToSuperview().offset(cellPadding)
            }
            
            setHighlight(highlight: false)
        }
    }
    
    /// 设置高亮状态
    func setHighlight(highlight: Bool) {
        if highlight {
            contentView.backgroundColor = .ud.N00.withAlphaComponent(0.8)
            contentView.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
            label.textColor = .ud.N900
        } else {
            contentView.backgroundColor = .ud.bgBody
            contentView.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
            label.textColor = .ud.N900
        }
    }

    /// cell 尺寸（根据icon和lable宽度计算）
    static func cellSize(for model: BannerCellViewModel) -> CGSize {
        let text = model.getText()
        var size = text.size(withAttributes: [.font: UIFont.systemFont(ofSize: 14)])
        size.height = max(cellHeight, size.height)
        size.width += cellPadding * 2
        if model.loading || model.hasImage() {
            size.width += imageIconWidth + imageTitleMarging
        }
        size.width = CGFloat(ceil(Double(size.width)))
        return size
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                
            }
        }
    }
}
