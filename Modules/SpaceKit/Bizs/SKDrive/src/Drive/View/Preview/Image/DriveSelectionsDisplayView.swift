//
//  DriveSelectionsDisplayView.swift
//  SpaceKit
//
//  Created by bupozhuang on 2019/6/3.
//

import UIKit
import SKCommon
import SKFoundation

protocol DriveSelectionsDisplayDelegate: AnyObject {
    func selectionsDisplayView(_ view: DriveSelectionsDisplayView, didSelectedAt area: DriveAreaComment)
}

class DriveSelectionsDisplayView: UIView {
    private let frameBorderWidth: CGFloat = 2.0
    private var curScale: CGFloat = 1.0
    weak var delegate: DriveSelectionsDisplayDelegate?
    private var areas: [DriveAreaComment] = []
    private var areaViews: [DriveSelectionView] = []
    private var observation: NSKeyValueObservation?
    private lazy var globalAreaView: DriveSelectionView = {
        let view = DriveSelectionView()
        view.isHidden = true
        view.isEditable = false
        return view
    }()
    private var selectedIndex: Int = -1

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    func invalideObserver() {
        // ref: https://stackoverflow.com/questions/50058609/ios-10-nskeyvalueobservation-crash-on-deinit
        observation = nil
    }

    override func layoutSubviews() {
        guard areas.count == areaViews.count else {
            DocsLogger.warning("areas.count != areaViews.count")
            return
        }
        globalAreaView.selectionFrame = bounds
        for (index, value) in areas.enumerated() {
            let view = areaViews[index]
            if let region = value.region {
                view.selectionFrame = region.areaFrame(in: self)
            } else {
                view.isHidden = true
            }
            if selectedIndex == index {
                highlight(index: index)
            }
        }
    }

    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)

        invalideObserver()
        curScale = 1.0
        if let view = newSuperview {
            observation = view.observe(\.transform, options: [.new, .old]) {[weak self] (_, change) in
                self?.handleTransfromChanged(change)
            }
        }
    }

    private func commonInit() {
        backgroundColor = .clear
        self.addSubview(globalAreaView)
    }
    func isSelected() -> Bool {
        return selectedIndex > -1
    }
    func touchArea(with point: CGPoint) -> DriveAreaComment? {
        guard !isHidden else { return nil }
        let sortedArea = areas.sorted { (commentA, commentB) -> Bool in
            return commentA.createTimeStamp > commentB.createTimeStamp
        }
        for area in sortedArea {
            if let areaFrame = area.region?.areaFrame(in: self),
                areaFrame.contains(point),
                let index = indexOfArea(area) {
                selectArea(at: index)
                return area
            }
        }
        return nil
    }

    func selectArea(at commentId: String) {
        guard areas.map({ $0.commentID }).contains(commentId) else { return }
        var index = 0
        for (i, area) in areas.enumerated() where area.commentID == commentId {
            index = i
            break
        }
        selectArea(at: index)
    }

    func selectArea(at index: Int) {
        guard index >= 0,
            index < areas.count else {
            deSelectArea()
            return
        }
        selectedIndex = index
        highlight(index: index)
    }
    func deSelectArea() {
        selectedIndex = -1
        unHighlightedArea()
    }
    func setAreas(_ areas: [DriveAreaComment]) {
        if needUpdate(with: areas) {
            areaViews.forEach { $0.removeFromSuperview() }
            areaViews.removeAll()
            for area in areas {
                let view = DriveSelectionView()
                areaViews.append(view)
                if let r = area.region {
                    view.selectionFrame = r.areaFrame(in: self)
                } else {
                    view.isHidden = true
                }
                view.isEditable = false
                self.addSubview(view)
            }
            highlightCurrentIndexIfNeed(with: areas)
            self.areas = areas
        }
    }

//    func clearAreas() {
//        deSelectArea()
//        for view in areaViews {
//            view.removeFromSuperview()
//        }
//        areaViews.removeAll()
//        areas.removeAll()
//    }
    /// 避免ImagePreviewView的手势和DriveSelectionView的pan手势冲突
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return nil
    }
    private func highlight(index: Int) {
        guard index >= 0, index < areaViews.count, areaViews.count == areas.count else {
            DocsLogger.warning("index out of range: \(index)")
            unHighlightedArea()
            return
        }
        let view = areaViews[index]
        let area = areas[index]
        if area.type == DriveAreaComment.AreaType.rect {
            globalAreaView.isHidden = true
            backgroundColor = UIColor.ud.N1000.withAlphaComponent(0.7)
            if view.selectionFrame.size.width > 2 * frameBorderWidth && view.selectionFrame.size.height > 2 * frameBorderWidth {
                mask(rect: view.selectionFrame.insetBy(dx: frameBorderWidth / curScale, dy: frameBorderWidth / curScale))
            } else {
                mask(rect: view.selectionFrame)
            }
        } else {
            highlightGlobal()
        }
    }
    private func highlightGlobal() {
        unHighlightedArea()
        globalAreaView.isHidden = false
    }
    private func unHighlightedArea() {
        globalAreaView.isHidden = true
        clearMask()
        backgroundColor = .clear
    }
    private func indexOfArea(_ area: DriveAreaComment) -> Int? {
        for (index, value) in areas.enumerated() where value.commentID == area.commentID {
            return index
        }
        return nil
    }

    /// 是否需要取消选择状态
    private func needUpdate(with updateAreas: [DriveAreaComment]) -> Bool {
        guard areas.count == updateAreas.count else {
            return true
        }
        var needUpdate = false
        for (index, value) in areas.enumerated() where value.commentID != updateAreas[index].commentID {
            needUpdate = true
            break
        }
        return needUpdate
    }
    /// 是否需要取消选择状态
    private func highlightCurrentIndexIfNeed(with updateAreas: [DriveAreaComment]) {
        guard selectedIndex > -1,
            areas.count == updateAreas.count,
            selectedIndex < areas.count else {
            return
        }
        if areas[selectedIndex].commentID == updateAreas[selectedIndex].commentID {
            highlight(index: selectedIndex)
        }
    }

    func handleTransfromChanged(_ change: NSKeyValueObservedChange<CGAffineTransform>) {
        if let newvalue = change.newValue, let oldvalue = change.oldValue {
            let newScale = newvalue.a
            let oldScale = oldvalue.a
            let needAnimate = (oldScale > newScale * 2 || newScale > oldScale * 2)
            let timeInterval = needAnimate ? 0.25 : 0
            self.updateBorderWidth(newScale, animateTimeIntervale: CGFloat(timeInterval))
        }
    }

    func updateBorderWidth(_ scale: CGFloat, animateTimeIntervale: CGFloat) {
        if scale > 0 {
            curScale = scale
            globalAreaView.updateBorderWidth( frameBorderWidth / scale, animateTimeIntervale: animateTimeIntervale )
            for view in areaViews {
                view.updateBorderWidth( frameBorderWidth / scale, animateTimeIntervale: animateTimeIntervale)
            }
            updateMaskIfNeed()
        }
    }

    func updateMaskIfNeed() {
        guard selectedIndex > -1,
            selectedIndex < areaViews.count else {
                return
        }
        highlight(index: selectedIndex)
    }
}
