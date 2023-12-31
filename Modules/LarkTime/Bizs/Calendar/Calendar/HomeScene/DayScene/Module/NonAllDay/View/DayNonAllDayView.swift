//
//  DayNonAllDayView.swift
//  Calendar
//
//  Created by 张威 on 2020/8/17.
//

import UIKit

/// DayScene - NonAllDay - InstanceView
/// 
/// 每一天对应一个 DayNonAllDayViewDataType

// MARK: - ViewData

protocol DayNonAllDayItemDataType {
    var frame: CGRect { get }
    var viewData: DayNonAllDayInstanceViewDataType { get }
    mutating func updateWithViewSetting(_ viewSetting: EventViewSetting)
    mutating func updateMaskOpacity(with viewSetting: EventViewSetting)
}

protocol DayNonAllDayViewDataType {
    var julianDay: JulianDay { get }
    var backgroundColor: UIColor { get }
    var items: [DayNonAllDayItemDataType] { get }
}

// MARK: - Delegate

protocol DayNonAllDayViewDelegate: AnyObject {
    func dayView(_ dayView: DayNonAllDayView, didTap instanceView: DayNonAllDayInstanceView, with uniqueId: String)
    func dayView(_ dayView: DayNonAllDayView, tapIconDidTap instanceView: DayNonAllDayInstanceView, with uniqueId: String, isSelected: Bool)
    func dayView(_ dayView: DayNonAllDayView, instanceViewFor uniqueId: String) -> DayNonAllDayInstanceView
    func dayView(_ dayView: DayNonAllDayView, didUnload instanceView: DayNonAllDayInstanceView)
}

// MARK: - View

final class DayNonAllDayView: UIView, ViewDataConvertible {

    static let padding = UIEdgeInsets(
        top: DayScene.UIStyle.Layout.timeScaleCanvas.vPadding.top,
        left: 0,
        bottom: DayScene.UIStyle.Layout.timeScaleCanvas.vPadding.bottom,
        right: 8
    )

    typealias ItemView = DayNonAllDayInstanceView

    var viewData: DayNonAllDayViewDataType? {
        didSet {
            backgroundColor = viewData?.backgroundColor
            updateItemViews()
        }
    }

    let edgeInsets: UIEdgeInsets

    weak var delegate: DayNonAllDayViewDelegate?

    private var lineLayers = [CAShapeLayer]()
    private typealias UniqueId = String
    private var loadedViews = [UniqueId: DayNonAllDayInstanceView]()
    private var backgroundLayer: CALayer?

    private let lineSpacing: CGFloat

    init(frame: CGRect = .zero,
         lineSpacing: CGFloat = DayScene.UIStyle.Layout.timeScaleCanvas.heightPerHour,
         lineColor: UIColor = UIColor.ud.lineBorderCard,
         edgeInsets: UIEdgeInsets = DayNonAllDayView.padding) {
        self.lineSpacing = lineSpacing
        self.edgeInsets = edgeInsets
        super.init(frame: frame)
        updateLayerTask {
            lineLayers = (0...24).map { _ in
                let layer = CAShapeLayer()
                layer.ud.setStrokeColor(lineColor, bindTo: self)
                layer.lineWidth = 0.5
                return layer
            }
            lineLayers.forEach(layer.addSublayer(_:))
            layoutLineLayers()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        unloadAllItems()
    }

    // MARK: Layout

    override var frame: CGRect {
        didSet {
            guard frame.size != oldValue.size else { return }
            updateLayerTask {
                layoutLineLayers()
            }
        }
    }

    override var bounds: CGRect {
        didSet {
            guard bounds.size != oldValue.size else { return }
            updateLayerTask {
                layoutLineLayers()
            }
        }
    }

    func unloadAllItems() {
        let keys = loadedViews.keys
        for key in keys {
            guard let itemView = loadedViews.removeValue(forKey: key) else {
                continue
            }
            assert(itemView.superview == self)
            if itemView.superview != self { continue }
            itemView.removeFromSuperview()
            itemView.isHidden = false
            delegate?.dayView(self, didUnload: itemView)
        }
    }

    private func layoutLineLayers() {
        let rect = bounds.inset(by: edgeInsets)
        for i in 0..<lineLayers.count {
            lineLayers[i].path = makeLinePath(at: i, in: rect).cgPath
        }
    }

    @inline(__always)
    private func makeLinePath(at index: Int, in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        let startPoint = CGPoint(
            x: rect.left,
            y: CGFloat(index) * lineSpacing + rect.top
        )
        path.move(to: startPoint)
        let endPoint = CGPoint(x: rect.right, y: startPoint.y)
        path.addLine(to: endPoint)
        return path
    }

    // MARK: Manage ItemViews

    private func updateItemViews() {
        loadedViews.forEach {
            $0.value.removeFromSuperview()
            $0.value.isHidden = true
        }

        // reload item views
        for item in viewData?.items ?? [] {
            let (frame, viewData) = (item.frame, item.viewData)
            let instanceView: DayNonAllDayInstanceView
            if let view = loadedViews[viewData.uniqueId] {
                instanceView = view
            } else {
                instanceView = delegate?.dayView(self, instanceViewFor: viewData.uniqueId) ?? DayNonAllDayInstanceView()
                DayScene.assert(instanceView.superview == nil)
                loadedViews[viewData.uniqueId] = instanceView
            }
            instanceView.isHidden = false
            addSubview(instanceView)
            instanceView.delegate = self
            instanceView.frame = frame
            instanceView.viewData = viewData
        }

        // unload hidden itemViews
        var needRemovedKeys = [UniqueId]()
        loadedViews.forEach { keyValue in
            if keyValue.value.isHidden {
                needRemovedKeys.append(keyValue.key)
            }
        }
        for key in needRemovedKeys {
            if let itemView = loadedViews.removeValue(forKey: key) {
                itemView.isHidden = false
                delegate?.dayView(self, didUnload: itemView)
            }
        }
    }

}

extension DayNonAllDayView: DayNonAllDayInstanceViewDelegate {

    func respondsToTap(from sender: DayNonAllDayInstanceView) {
        guard let uniqueId = sender.viewData?.uniqueId else {
            DayScene.assertionFailure("DayNonAllDayInstanceView#viewData.uniqueId should not be empty")
            return
        }
        delegate?.dayView(self, didTap: sender, with: uniqueId)
    }
    
    
    func tapIconRespondsToTap(from sender: DayNonAllDayInstanceView, isSelected: Bool) {
        guard let uniqueId = sender.viewData?.uniqueId else {
            DayScene.assertionFailure("DayNonAllDayInstanceView#viewData.uniqueId should not be empty")
            return
        }
        delegate?.dayView(self, tapIconDidTap: sender, with: uniqueId, isSelected: isSelected)
    }

}

extension DayNonAllDayView: TimeScaleViewType {  }
