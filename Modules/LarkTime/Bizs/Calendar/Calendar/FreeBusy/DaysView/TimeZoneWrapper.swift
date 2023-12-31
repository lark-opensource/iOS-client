//
//  TimeZoneWrapper.swift
//  Calendar
//
//  Created by zhuheng on 2021/4/20.
//

import UIKit
import Foundation

final class TimeZoneWrapper: UIView {

    let uiWrapper = UIView()
    let timeZoneLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.cd.dinBoldFont(ofSize: 11)
        label.textColor = UIColor.ud.textPlaceholder
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    let timeZoneImage: UIImageView = {
        let view = UIImageView()
        view.image = UIImage.cd.image(named: "time_zone_icon").withRenderingMode(.alwaysOriginal)
        return view
    }()

    var timeZoneClicked: (() -> Void)?

    init() {
        super.init(frame: .zero)
        self.backgroundColor = UIColor.ud.bgBody
        self.addSubview(uiWrapper)
        uiWrapper.snp.makeConstraints({make in
            make.centerX.top.bottom.equalToSuperview()
        })

        uiWrapper.addSubview(timeZoneImage)
        timeZoneImage.snp.makeConstraints({make in
            make.right.centerY.equalToSuperview()
            make.width.equalTo(6)
        })

        uiWrapper.addSubview(timeZoneLabel)
        timeZoneLabel.snp.makeConstraints({make in
            make.left.top.bottom.equalToSuperview()
            make.right.equalTo(timeZoneImage.snp.left).offset(-1)
        })

        addTapGesture()
        self.isHidden = true
    }

    func setTimeZoneStr(timeZoneStr: String) {
        var timeZoneStr = timeZoneStr
        if timeZoneStr.count > 6, let index = timeZoneStr.firstIndex(of: "T") {
            timeZoneStr.insert("\n", at: timeZoneStr.index(after: index))
        }
        timeZoneLabel.text = timeZoneStr
        self.isHidden = false
    }

    private func addTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(timeZoneWrapperClick))
        tapGesture.numberOfTapsRequired = 1
        self.addGestureRecognizer(tapGesture)
    }

    @objc
    private func timeZoneWrapperClick() {
        timeZoneClicked?()
    }

    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let rect = self.bounds.insetBy(dx: 0, dy: -8)
        return rect.contains(point) ? self : nil
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
