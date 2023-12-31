//
//  MeetingRoomDayInstancesView.swift
//  Calendar
//
//  Created by 王仕杰 on 2021/4/22.
//

import UIKit
import SnapKit

final class MeetingRoomDayInstancesView: UIView {

    struct SimpleInstance {
        init?(startTime: Double, endTime: Double, editable: Bool) {
            assert(startTime >= 0)
            assert(endTime <= 24)
            assert(startTime <= endTime)

            if startTime > endTime { return nil }

            self.startTime = startTime
            self.endTime = endTime
            self.editable = editable
        }

        let startTime: Double
        let endTime: Double
        let editable: Bool
    }

    var instances: [SimpleInstance] {
        get { instanceView.instances }
        set { instanceView.instances = newValue }
    }

    var currentTime: Date? {
        get { instanceView.currentTime }
        set { instanceView.currentTime = newValue }
    }

    private lazy var instanceView = InstanceView()
    override init(frame: CGRect) {
        super.init(frame: frame)

        clipsToBounds = false

        let timeIndicatorView = TimeListView()
        addSubview(timeIndicatorView)

        instanceView.contentMode = .redraw
        addSubview(instanceView)
        instanceView.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
            make.height.equalTo(24)
        }

        timeIndicatorView.snp.makeConstraints { make in
            make.top.equalTo(instanceView.snp.bottom).offset(1)
            make.bottom.equalToSuperview()
        }

        timeIndicatorView.firstLabel.snp.makeConstraints { make in
            make.centerX.equalTo(instanceView.snp.leading)
        }
        timeIndicatorView.lastLabel.snp.makeConstraints { make in
            make.centerX.equalTo(instanceView.snp.trailing)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension MeetingRoomDayInstancesView {

    fileprivate final class InstanceView: UIView {

        var instances = [SimpleInstance]() {
            didSet {
                setNeedsDisplay()
            }
        }

        var currentTime: Date? {
            didSet {
                setNeedsDisplay()
            }
        }

        override func draw(_ rect: CGRect) {
            for instance in instances {
                let startPercentage = max(0, (instance.startTime - 8) / 16)
                let endPercentage = (instance.endTime - 8) / 16
                guard endPercentage > 0 else { continue }
                let path = UIBezierPath(rect: CGRect(x: CGFloat(startPercentage) * rect.width,
                                                     y: 0,
                                                     width: CGFloat(endPercentage - startPercentage) * rect.width,
                                                     height: rect.height))
                let color = instance.editable ? UIColor.ud.B200 : UIColor.ud.N400
                color.setFill()
                path.fill()
            }

            for time in stride(from: 2, through: 14, by: 2) {
                let path = UIBezierPath()
                let percentage = CGFloat(time) / 16
                path.move(to: CGPoint(x: percentage * rect.width, y: 0))
                path.addLine(to: CGPoint(x: percentage * rect.width, y: rect.height))
                path.lineWidth = 1
                UIColor.ud.bgBody.setStroke()
                path.stroke()
            }

            guard let currentTime = currentTime else { return }
            let interval = currentTime.timeIntervalSince(currentTime.dayStart()) - 8 * 3600
            guard interval >= 0 else { return }

            let percentage = CGFloat(interval) / 16 / 3600
            let currentTimePath = UIBezierPath()
            currentTimePath.move(to: CGPoint(x: percentage * rect.width, y: 0))
            currentTimePath.addLine(to: CGPoint(x: percentage * rect.width, y: rect.height))
            let dash: [CGFloat] = [4, 2]
            currentTimePath.setLineDash(dash, count: 2, phase: 2)
            currentTimePath.lineWidth = 1
            UIColor.ud.functionDangerContentDefault.setStroke()
            currentTimePath.stroke()
        }

        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = UIColor.ud.N100
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

extension MeetingRoomDayInstancesView {
    fileprivate final class TimeListView: UIView {
        fileprivate var firstLabel: UIView { stackView.arrangedSubviews.first! }

        fileprivate var lastLabel: UIView { stackView.arrangedSubviews.last! }

        private let times = Array(stride(from: 8, through: 24, by: 2))

        private lazy var stackView: UIStackView = {
            let timeViews = times.map { time -> UILabel in
                let label = UILabel()
                label.text = String(describing: time)
                label.sizeToFit()
                label.font = UIFont.ud.caption1
                label.textColor = UIColor.ud.textPlaceholder
                return label
            }
            let stackView = UIStackView(arrangedSubviews: timeViews)
            stackView.distribution = .equalCentering
            return stackView
        }()

        override init(frame: CGRect) {
            super.init(frame: frame)

            backgroundColor = UIColor.clear

            addSubview(stackView)
            stackView.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }

            firstLabel.alpha = 0
            lastLabel.alpha = 0
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
