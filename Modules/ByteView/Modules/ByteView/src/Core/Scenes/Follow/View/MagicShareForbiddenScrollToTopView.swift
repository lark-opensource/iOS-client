//
//  MagicShareForbiddenScrollToTopView.swift
//  ByteView
//
//  Created by fakegourmet on 2022/1/28.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import UIKit

class MagicShareForbiddenScrollToTopView: UIView, UIScrollViewDelegate {

    lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.backgroundColor = .clear
        view.delegate = self
        view.scrollsToTop = true
        view.showsVerticalScrollIndicator = false
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        addSubview(scrollView)
        scrollView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.contentSize.height = frame.size.height + 1
        resetContentOffset()
    }

    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        resetContentOffset()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        resetContentOffset()
    }

    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        scrollView === self.scrollView
    }

    @inline(__always)
    private func resetContentOffset() {
        scrollView.setContentOffset(CGPoint(x: 0, y: frame.size.height), animated: false)
    }
}
