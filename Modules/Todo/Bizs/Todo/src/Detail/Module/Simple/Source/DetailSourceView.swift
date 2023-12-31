//
//  DetailSourceView.swift
//  Todo
//
//  Created by 白言韬 on 2021/4/11.
//

import Foundation
import RichLabel
import CTFoundation

protocol DetailSourceViewDataType {
    var attributedText: AttrText { get }
    var url: URL? { get }
}

final class DetailSourceView: UIView, ViewDataConvertible {

    var viewData: DetailSourceViewDataType? {
        didSet {
            guard let viewData = viewData else {
                isHidden = true
                return
            }

            isHidden = false
            label.attributedText = viewData.attributedText
        }
    }

    var onLinkTap: ((URL) -> Void)?

    private let container = UIView()
    private let label = LKLabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        isHidden = true
        addSubview(container)
        container.snp.makeConstraints {
            $0.left.equalToSuperview().offset(16)
            $0.right.lessThanOrEqualToSuperview().offset(-16)
            $0.top.bottom.equalToSuperview()
        }
        container.layer.cornerRadius = 10
        container.layer.masksToBounds = true
        container.backgroundColor = UIColor.ud.sourceBg
        container.addSubview(label)
        label.backgroundColor = .clear
        label.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(12)
            make.right.equalToSuperview().offset(-8)
            make.top.equalToSuperview().offset(3)
            make.bottom.equalToSuperview().offset(-3)
        }
        label.numberOfLines = 1
        let textColor = UIColor.ud.textLinkNormal
        label.linkAttributes = [.foregroundColor: textColor]
        label.outOfRangeText = AttrText(string: "...", attributes: [.foregroundColor: textColor])
        label.activeLinkAttributes = [:]
        label.autoDetectLinks = false

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        container.addGestureRecognizer(tapGesture)
    }

    @objc
    private func handleTap() {
        guard let url = viewData?.url else {
            return
        }
        onLinkTap?(url)
    }
}
