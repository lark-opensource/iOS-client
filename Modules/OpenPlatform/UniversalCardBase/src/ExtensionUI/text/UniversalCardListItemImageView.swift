//
//  UniversalCardListItemImageView.swift
//  UniversalCardBase
//
//  Created by zhujingcheng on 11/2/23.
//

import Foundation
import RustPB
import ByteWebImage
import LKCommonsLogging

public final class UniversalCardListItemImageView: UIImageView {
    static let logger = Logger.oplog(UniversalCardListItemImageView.self, category: "UniversalCardListItemImageView")
    private let longImageText = BundleI18n.UniversalCardBase.Lark_Legacy_MsgCard_LongImgTag
    private let property: Basic_V1_RichTextElement.ImageProperty
    private let heightWidthRatioLimit: CGFloat
    
    lazy private var longImageLabel: UILabel = {
        let longImageLabel = UILabel()
        longImageLabel.text = longImageText
        longImageLabel.font = UIFont.systemFont(ofSize: 10.0, weight: .medium)
        longImageLabel.textColor = UIColor.ud.primaryOnPrimaryFill
        longImageLabel.textAlignment = .center
        longImageLabel.backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.5)
        return longImageLabel
    }()
    
    public init(property: Basic_V1_RichTextElement.ImageProperty, ratioLimit: CGFloat) {
        self.property = property
        self.heightWidthRatioLimit = ratioLimit
        super.init(frame: .zero)
        setupView()
    }
            
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        contentMode = .scaleAspectFit
        let imageToken = ImageItemSet.transform(imageProperty: property).generatePostMessageKey(forceOrigin: false)
        bt.setLarkImage(.default(key: imageToken), completion: { [weak self] imageResult in
            switch imageResult {
            case .success(_):
                self?.cropImageIfNeeded()
            case .failure(let error):
                Self.logger.error("setImage error \(error.localizedDescription)")
            }
        })
        
        if UniversalCardImageUtils.isLongImage(imageProperty: property, heightWidthRatioLimit: heightWidthRatioLimit) {
            addLongImageLabel()
        }
    }
    
    private func addLongImageLabel() {
        addSubview(longImageLabel)
        let height = longImageText.getHeight(font: UIFont.systemFont(ofSize: 10.0, weight: .medium)) + 4
        longImageLabel.snp.makeConstraints { make in
            make.left.bottom.right.equalToSuperview()
            make.height.equalTo(height)
        }
    }
    
    private func cropImageIfNeeded() {
        let originRatio = CGFloat(property.originHeight) / CGFloat(property.originWidth)
        guard let image = image, image.size.width > 0, originRatio > heightWidthRatioLimit else {
            return
        }
        let imageCropHeight = image.size.width * heightWidthRatioLimit
        self.image = UniversalCardImageUtils.cropImage(image: image, imageCropHeight: imageCropHeight)
    }
}

