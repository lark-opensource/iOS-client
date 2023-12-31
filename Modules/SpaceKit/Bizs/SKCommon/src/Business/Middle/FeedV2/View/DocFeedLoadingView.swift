//
//  DocFeedLoadingView.swift
//  SKCommon
//
//  Created by huayufan on 2021/10/11.
//  


import UIKit

class DocFeedLoadingView: UIView {

    var indicator: UIActivityIndicatorView!

    init() {
        super.init(frame: .zero)
        setupSubviews()
        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        indicator = UIActivityIndicatorView(style: .gray).construct({
            $0.color = .gray
            $0.backgroundColor = .clear
        })

        addSubview(indicator)
    }

    private func setupLayout() {
        indicator.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(40)
        }
    }

    func startLoading() {
        indicator.startAnimating()
        alpha = 1
    }

    func stopLoading() {
        indicator.stopAnimating()
        alpha = 0
    }
}
