//
//  TimePickerView.swift
//  LarkDatePickerView
//
//  Created by 李论 on 2019/9/24.
//

import Foundation
import UIKit

public protocol TimePickerDataProtocol: AnyObject {
    var hour: Int { get }
    var minute: Int { get }
    var seconds: Int { get }
}

public final class TimePickerData: TimePickerDataProtocol, NSCopying {
    public func copy(with zone: NSZone? = nil) -> Any {
        return TimePickerData(h: hour, m: minute, s: seconds)
    }

    public var hour: Int = 0

    public var minute: Int = 0

    public var seconds: Int = 0

    required init(h: Int, m: Int, s: Int = 0) {
        seconds = s % 60
        minute = (m + s / 60) % 60
        hour = (h + (m + s / 60) / 60) % 24
    }
}

public protocol TimePickerViewDelegate: AnyObject {
    func timePickerSelect(_ picker: TimePickerView, didSelectDateTime time: TimePickerDataProtocol)
}

public final class TimePickerView: PickerView {

    private var initTime: TimePickerData
    private var scrollTime: TimePickerData
    public weak var delegate: TimePickerViewDelegate?

    public init(frame: CGRect, selectedHour: Int, selectedMinute: Int) {
        initTime = TimePickerData(h: selectedHour, m: selectedMinute)
        scrollTime = TimePickerData(h: selectedHour, m: selectedMinute)
        super.init(frame: frame)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func scrollViewFrame(index: Int) -> CGRect {
        let hourWheelWidth: CGFloat = (375.0 * 0.5) / 375.0 * self.bounds.width
        let minuteWheelWidth: CGFloat = (375.0 * 0.5) / 375.0 * self.bounds.width
//        let dayRightWheelWidth: CGFloat = self.bounds.width - dayLeftWheelWidth - dayMiddleWheelWidth
        switch index {
        case 1:
            return CGRect(x: 0, y: 0, width: hourWheelWidth, height: self.bounds.height)
        case 2:
            return CGRect(x: hourWheelWidth, y: 0, width: minuteWheelWidth, height: self.bounds.height)
        case 3:
            return CGRect(x: self.bounds.width, y: 0, width: 0, height: self.bounds.height)
        default:
            return .zero
        }
    }

    override public func infiniteScrollView(scrollView: InfiniteScrollView, willDisplay view: UIView, at index: Int) {
        guard let cell = view as? DatePickerCell else {
            return
        }
        switch scrollView {
        case firstScrollView:
            scrollTime.hour = self.hour(initial: initTime.hour, offSet: index)
            let hourStr = String(format: "%02d", scrollTime.hour)
            cell.label.text = hourStr
        case secondScrollView:
            // minute
            scrollTime.minute = self.minute(initial: initTime.minute, offSet: index)
            let minuteStr = String(format: "%02d", scrollTime.minute)
            cell.label.text = minuteStr
        default:
            break
        }
    }

    public override func scrollEndScroll(scrollView: InfiniteScrollView) {
        super.scrollEndScroll(scrollView: scrollView)
        self.delegate?.timePickerSelect(self, didSelectDateTime: scrollTime)
    }

    private func hour(initial hour: Int, offSet: Int) -> Int {
        let offsetHour = ( hour + offSet ) % 24
        return offsetHour < 0 ? ( offsetHour + 24) : offsetHour
    }

    private func minute(initial minute: Int, offSet: Int) -> Int {
        let offsetMinute = ( minute + offSet ) % 60
        return offsetMinute < 0 ? (offsetMinute + 60) : offsetMinute
    }

    lazy private var disableMask: UIView = {
        let view = UIView()
        self.addSubview(view)
        view.isUserInteractionEnabled = false
//        view.backgroundColor = UIColor.ud.bgBody.withAlphaComponent(0.7)
        view.ud.setValue(forKeyPath: \.backgroundColor,
                         light: UIColor.ud.bgBody.alwaysLight.withAlphaComponent(0.7),
                         dark: UIColor.ud.bgBody.alwaysDark.withAlphaComponent(0.7))
        view.snp.makeConstraints({ (make) in
            make.edges.equalToSuperview()
        })
        return view
    }()

    func showDisableMask(isShow: Bool) {
        self.topGradientView.isHidden = isShow
        self.bottomGradientView.isHidden = isShow
        if isShow {
            self.bringSubviewToFront(disableMask)
            disableMask.isHidden = false
        } else {
            disableMask.isHidden = true
        }
    }

    private func currentHour() -> Int {
        guard let hourCell = self.centerCell(of: firstScrollView) else {
            return initTime.hour
        }
        return self.hour(initial: initTime.hour, offSet: hourCell.tag)
    }

    private func currentMinute() -> Int {
        guard let minuteCell = self.centerCell(of: secondScrollView) else {
            return initTime.minute
        }
        return self.minute(initial: initTime.minute, offSet: minuteCell.tag)
    }

    public func currentSelectedTime() -> TimePickerData {
        return TimePickerData(h: currentHour(), m: currentMinute())
    }
}
