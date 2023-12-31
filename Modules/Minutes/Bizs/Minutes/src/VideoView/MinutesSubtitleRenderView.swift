//
//  MinutesSubtitleRenderView.swift
//  Minutes
//
//  Created by lvdaqian on 2021/2/1.
//

import Foundation
import SnapKit
import MinutesFoundation
import LarkUIKit
import UniverseDesignFont

struct SubtitleRenderModel {
    let firstLine: String?
    let secondLine: String?
}

class MinutesSubtitleRenderView: UIView {

    let firstLineContainer = UIView()
    let secondLineContainer = UIView()
    let firstLine: UILabel = UILabel()
    let secondLine: UILabel = UILabel()
    var subtitleFontSize: Int = Display.pad ? 16 : 12
    var subtitleBottomInset: Int = Display.pad ? 20 : 12
    var subtitleBorderInset: Int = 24
    private var landscapeStyle: Bool = false {
        didSet {
            if landscapeStyle {
                subtitleFontSize = 16
                subtitleBottomInset = 20
                subtitleBorderInset = 110
            } else {
                subtitleFontSize = Display.pad ? 16 : 12
                subtitleBottomInset = Display.pad ? 20 : 12
                subtitleBorderInset = 24
            }
        }
    }

    func updateLandscapeStyle() {
        landscapeStyle = !landscapeStyle
    }

    func getCurrentLandscape() {
        landscapeStyle = ((self.superview?.bounds.width ?? 0) > 500)
    }

    func append(to view: UIView?) {
        self.removeFromSuperview()
        self.snp.removeConstraints()

        guard let view = view else { return }

        view.addSubview(self)
        getCurrentLandscape()

        self.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        self.isUserInteractionEnabled = false

        firstLineContainer.backgroundColor = UIColor.ud.N1000.withAlphaComponent(0.65).nonDynamic
        firstLineContainer.isHidden = true
        firstLineContainer.layer.cornerRadius = 6.0
        firstLineContainer.layer.masksToBounds = true

        addSubview(firstLineContainer)
        firstLineContainer.snp.makeConstraints { maker in
            maker.width.lessThanOrEqualToSuperview().inset(subtitleBorderInset)
            maker.centerX.equalToSuperview()
            maker.bottom.equalToSuperview().inset(subtitleBottomInset)
        }

        firstLine.textColor = UIColor.ud.N00.nonDynamic
        firstLine.font = UIFont.ud.caption1
        firstLine.numberOfLines = 0
        firstLine.textAlignment = .center
        firstLineContainer.addSubview(firstLine)
        firstLine.snp.makeConstraints { maker in
            maker.edges.equalToSuperview().inset(4)
        }

        secondLineContainer.backgroundColor = UIColor.ud.N1000.withAlphaComponent(0.65).nonDynamic
        secondLineContainer.isHidden = true
        secondLineContainer.layer.cornerRadius = 6.0
        secondLineContainer.layer.masksToBounds = true

        addSubview(secondLineContainer)
        secondLineContainer.snp.makeConstraints { maker in
            maker.width.lessThanOrEqualToSuperview().inset(subtitleBorderInset)
            maker.centerX.equalToSuperview()
            maker.bottom.equalTo(firstLineContainer.snp.top).offset(-4)
        }

        secondLine.textColor = UIColor.ud.N00.nonDynamic
        secondLine.font = UIFont.ud.caption1
        secondLine.numberOfLines = 0
        secondLine.textAlignment = .center
        secondLineContainer.addSubview(secondLine)
        secondLine.snp.makeConstraints { maker in
            maker.edges.equalToSuperview().inset(4)
        }
        updateSubtitleStyle()
    }

    func updateSubtitleStyle() {
        firstLineContainer.snp.remakeConstraints { maker in
            maker.width.lessThanOrEqualToSuperview().inset(subtitleBorderInset)
            maker.centerX.equalToSuperview()
            maker.bottom.equalToSuperview().inset(subtitleBottomInset)
        }
        firstLine.font = UIFont.systemFont(ofSize: CGFloat(subtitleFontSize), weight: .regular)

        secondLineContainer.snp.remakeConstraints { maker in
            maker.width.lessThanOrEqualToSuperview().inset(subtitleBorderInset)
            maker.centerX.equalToSuperview()
            maker.bottom.equalTo(firstLineContainer.snp.top).offset(-4)
        }
        secondLine.font = UIFont.systemFont(ofSize: CGFloat(subtitleFontSize), weight: .regular)
    }

    func update(_ model: SubtitleRenderModel) {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 5
        style.alignment = .center
        if let value = model.firstLine {
            if value.isEmpty {
                firstLineContainer.isHidden = true
            } else {
                firstLine.attributedText = NSAttributedString(string: value, attributes: [.kern: -0.32, .paragraphStyle: style])
                firstLineContainer.isHidden = false
            }
        }

        if let value = model.secondLine {
            if value.isEmpty {
                secondLineContainer.isHidden = true
            } else {
                secondLine.attributedText = NSAttributedString(string: value, attributes: [.kern: -0.32, .paragraphStyle: style])
                secondLineContainer.isHidden = false
            }
        }
    }
}
