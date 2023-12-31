//
//  DocsUDLoadingImageView.swift
//  SKCommon
//
//  Created by zoujie on 2021/7/20.
//  


import Foundation
import SKUIKit
import UniverseDesignColor
import UniverseDesignLoading

open class DocsUDLoadingImageView: UIView {

    public let label = UILabel()
    public var textFontSize: CGFloat = 16.0 {
        didSet {
            label.font = UIFont.systemFont(ofSize: textFontSize)
            setNeedsLayout()
        }
    }
    public override var isHidden: Bool {
        didSet{
            self.loadingView.isHidden = isHidden
        }
    }
    public var textTopMargin: CGFloat = 11.0 {
        didSet {
            guard oldValue != textTopMargin else {
                return
            }
            label.snp.updateConstraints { make in
                make.top.equalTo(loadingView.snp.bottom).offset(textTopMargin)
            }
        }
    }
    public var loadingSize: CGSize? = nil {
        didSet {
            guard oldValue != loadingSize else { return }
            if let size = loadingSize {
                loadingView.snp.remakeConstraints { make in
                    make.top.equalTo(topSpaceView.snp.bottom)
                    make.centerX.equalToSuperview()
                    make.width.equalTo(size.width)
                    make.height.equalTo(size.height)
                }
            } else {
                loadingView.snp.remakeConstraints { make in
                    make.top.equalTo(topSpaceView.snp.bottom)
                    make.centerX.equalToSuperview()
                }
            }
        }

    }
    private let loadingView: UIView
    private let topSpaceView: UIView
    public init(lottieResource: String? = nil) {
        loadingView = UDLoading.loadingImageView(lottieResource: lottieResource)
        topSpaceView = UIView()
        super.init(frame: .zero)

        addSubview(loadingView)
        addSubview(topSpaceView)

        topSpaceView.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalToSuperview().dividedBy(3)
        }

        loadingView.snp.makeConstraints { (make) in
            if let size = loadingSize {
                make.width.equalTo(size.width)
                make.height.equalTo(size.height)
            }
            make.top.equalTo(topSpaceView.snp.bottom)
            make.centerX.equalToSuperview()
        }

        // 文案
        label.font = UIFont.systemFont(ofSize: textFontSize)
        label.textColor = UIColor.ud.textCaption
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        addSubview(label)
        label.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(loadingView.snp.bottom).offset(textTopMargin)
            if SKDisplay.pad {
                make.width.lessThanOrEqualTo(343)
                make.width.equalToSuperview().offset(-32).priority(.high)
            } else {
                make.width.equalToSuperview().offset(-32)
            }
        }
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
