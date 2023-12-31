//
//  CTAContentView.swift
//  CTADialog
//
//  Created by aslan on 2023/10/12.
//

import Foundation
import SnapKit
import ByteWebImage
import LarkIllustrationResource

protocol DialogContentClickDelegate: AnyObject {
    /// 点击文本内容链接
    func clickLink(url: URL)
}

final class CTAContentView: UIView {

    weak var clickDelegate: DialogContentClickDelegate?

    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.textColor = UIColor.ud.textCaption
        textView.font = UIFont.systemFont(ofSize: 14)
        textView.isScrollEnabled = false
        textView.linkTextAttributes = [
            .foregroundColor: UIColor.ud.textLinkNormal
        ]
        textView.backgroundColor = .clear
        textView.isEditable = false
        return textView
    }()

    private lazy var placeHolderImageView: UIImageView = {
       let imageView = UIImageView()
        imageView.layer.cornerRadius = Layout.imageRadius
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.image = Resources.specializedCtaBannerMobile
       return imageView
    }()

    private lazy var netImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.isHidden = true
        return imageView
    }()

    init() {
        super.init(frame: .zero)
        addSubview(self.placeHolderImageView)
        addSubview(self.netImageView)
        addSubview(self.textView)
        self.textView.delegate = self

        self.placeHolderImageView.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(self.placeHolderImageView.snp.width).multipliedBy(Layout.ratio)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
        }

        self.netImageView.snp.makeConstraints { make in
            make.edges.equalTo(self.placeHolderImageView.snp.edges)
        }

        self.textView.snp.makeConstraints { make in
            make.left.equalTo(self.placeHolderImageView.snp.left)
            make.right.equalTo(self.placeHolderImageView.snp.right)
            make.top.equalTo(self.placeHolderImageView.snp.bottom).offset(Layout.padding)
            make.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setContent(content: String) {
        self.netImageView.isHidden = true
        self.placeHolderImageView.isHidden = false
        self.textView.text = content
    }

    func setContent(content: NSAttributedString, imgUrl: String? = nil) {
        self.netImageView.isHidden = true
        self.placeHolderImageView.isHidden = false
        if let imageUrl = imgUrl,
           !imageUrl.isEmpty,
        let imgeURL = URL(string: imageUrl) {
            self.netImageView.bt.setImage(imgeURL, completionHandler:  { [weak self] result in
                guard let `self` = self else { return }
                switch result {
                case .failure:
                    break
                case .success(let imageResult):
                    self.netImageView.image = imageResult.image
                    self.netImageView.isHidden = false
                    self.placeHolderImageView.isHidden = true
                }
            })
        }
        self.textView.attributedText = content
    }

    enum Layout {
        static let padding: Int = 8
        static let bottomPadding: Int = 40
        static let ratio: Float = 114 / 210
        static let imageRadius: CGFloat = 6
    }
}

extension CTAContentView: UITextViewDelegate {
    public func textView(_ textView: UITextView,
                         shouldInteractWith URL: URL,
                         in characterRange: NSRange,
                         interaction: UITextItemInteraction) -> Bool {
        self.clickDelegate?.clickLink(url: URL)
        return false
    }
}
