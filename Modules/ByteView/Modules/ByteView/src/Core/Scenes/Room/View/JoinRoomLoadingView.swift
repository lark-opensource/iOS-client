//
//  JoinRoomLoadingView.swift
//  ByteView
//
//  Created by kiri on 2022/5/23.
//

import Foundation
import UIKit

final class JoinRoomLoadingView: JoinRoomChildView {
    let loadingIndicator = LoadingView(style: .blue)
    let loadingLabel = UILabel()
    let loadingContainerView = UIView()
    let hintLabel = UILabel()

    override func setupViews() {
        super.setupViews()
        self.backgroundColor = .clear
        loadingLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        addSubview(loadingContainerView)
        addSubview(hintLabel)
        loadingContainerView.addSubview(loadingIndicator)
        loadingContainerView.addSubview(loadingLabel)
        loadingContainerView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(40)
        }
        hintLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(loadingContainerView.snp.bottom).offset(8)
            make.bottom.equalToSuperview().offset(-40)
        }
        loadingLabel.attributedText = NSAttributedString(string: I18n.View_G_ScanLoading, config: .body, textColor: .ud.textCaption)
        loadingIndicator.snp.remakeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.width.height.equalTo(24)
        }
        loadingLabel.snp.remakeConstraints { make in
            make.right.equalToSuperview()
            make.centerY.equalTo(loadingIndicator)
            make.left.equalTo(loadingIndicator.snp.right).offset(8)
        }
        hintLabel.numberOfLines = 0
        hintLabel.attributedText = NSAttributedString(string: I18n.View_G_ScanRoomNote, config: .body, alignment: .center, textColor: .ud.textCaption)
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        if newWindow == nil {
            loadingIndicator.stop()
        } else {
            loadingIndicator.play()
        }
    }

    override func fitContentHeight(maxWidth: CGFloat) -> CGFloat {
        let width = maxWidth - 40
        hintLabel.preferredMaxLayoutWidth = width
        let hintHeight = hintLabel.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
        return 80 + 24 + 8 + hintHeight
    }
}
