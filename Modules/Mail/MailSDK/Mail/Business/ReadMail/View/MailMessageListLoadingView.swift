//
//  MailLoadingView.swift
//  MailSDK
//
//  Created by zhaoxiongbin on 2021/2/9.
//

import LarkUIKit
import UniverseDesignTheme

class MailMessageListLoadingView: UIView {
    private let loadingView = MailBaseLoadingView()
    private var loadingTimer: Timer?

    override var isHidden: Bool {
        didSet {
            if isHidden {
                hideLoadingView()
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(loadingView)
        let centerYoffset = -(Display.realNavBarHeight() + Display.bottomSafeAreaHeight) / 2
        loadingView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview().offset(centerYoffset)
            make.left.right.equalToSuperview()
        }
        loadingView.isHidden = true
        loadingView.backgroundColor = UIColor.ud.bgBase
        backgroundColor = UIColor.ud.bgBase
    }

    func showLoading(delay: TimeInterval = 0) {
        loadingTimer?.invalidate()
        isHidden = false
        if delay <= 0 {
            loadingView.play()
        } else if loadingView.isHidden == true {
            // 若页面已经在显示loading，不需要进行loading操作
            hideLoadingView()
            loadingTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false, block: { [weak self] (_) in
                self?.loadingView.play()
            })
        }
    }

    private func hideLoadingView() {
        loadingTimer?.invalidate()
        loadingView.stop()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
