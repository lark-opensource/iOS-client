//
//  VideoFileTagView.swift
//  LarkFile
//
//  Created by liluobin on 2021/10/21.
//

import Foundation
import UIKit
import FigmaKit

final class VideoFileTagView: UIView {
    enum IconType: Int {
        case small
        case middle
    }
    private lazy var colorView: LinearGradientView = {
        let view = LinearGradientView()
        view.colors = [UIColor.ud.staticBlack.withAlphaComponent(0.6), UIColor.clear]
        view.direction = .bottomToTop
        return view
    }()
    private lazy var icon: UIImageView = {
        let view = UIImageView()
        view.image = Resources.video_icon
        return view
    }()
    let type: VideoFileTagView.IconType
    init(type: VideoFileTagView.IconType) {
        self.type = type
        super.init(frame: .zero)
        setupView()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private func setupView() {
        addSubview(colorView)
        addSubview(icon)
        colorView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        var space = 0
        var size = CGSize(width: 10, height: 10)
        switch type {
        case .small:
            space = 4
        case .middle:
            space = 5
            size = CGSize(width: 12, height: 12)
        }
        icon.snp.makeConstraints { make in
            make.right.bottom.equalToSuperview().offset(-space)
            make.size.equalTo(size)
        }
    }
}
