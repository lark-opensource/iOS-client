//
//  SeizeMeetingroomActionSheet.swift
//  Calendar
//
//  Created by harry zou on 2019/4/17.
//

import UIKit
import RxSwift
import RxCocoa
import CalendarFoundation
import LarkUIKit
final class SeizeMeetingroomActionSheet: UIViewController {
    private let headerView = SeizeHeaderView()
    private let footerView = SeizeFooterView()
    private let selectionView: DurationSelectionView
    private var model: DurationSelectionModel
    private(set) var isShowing: Bool = false
    var timeConfirmed: ((Int, Int) -> Void)?

    lazy var mask: UIButton = { [weak self] in
        var btn = UIButton(type: .custom)
        btn.backgroundColor = UIColor.clear
        btn.addTarget(self, action: #selector(disappear), for: .touchUpInside)
        self?.view.insertSubview(btn, at: 0)
        btn.snp.makeConstraints({ (make) in
            make.edges.equalToSuperview()
        })
        return btn
    }()

    private var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgMask
        view.isUserInteractionEnabled = false
        return view
    }()

    private let actionWrapper: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        let topView = UIView()
        topView.backgroundColor = UIColor.ud.bgBody
        topView.layer.cornerRadius = 8
        topView.layer.masksToBounds = true
        view.addSubview(topView)
        topView.snp.makeConstraints({ (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(30)
        })
        let bottomView = UIView()
        bottomView.backgroundColor = UIColor.ud.bgBody
        view.addSubview(bottomView)
        bottomView.snp.makeConstraints({ (make) in
            make.bottom.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(15)
        })
        return view
    }()

    init(model: DurationSelectionModel, defaultDuration: Int, is12HourStyle: BehaviorRelay<Bool>) {
        self.model = model
        selectionView = DurationSelectionView(model: model, defaultDurition: defaultDuration, is12HourStyle: is12HourStyle)
        super.init(nibName: nil, bundle: nil)
        footerView.seizeButtonPressed = { [unowned self] in
            let endTime = self.selectionView.selectedTime
            if let startTime = Date(timeIntervalSince1970: TimeInterval(self.model.startTime)).truncated([.second, .nanosecond])?.timeIntervalSince1970 {
                self.timeConfirmed?(Int(startTime), endTime)
            } else {
                assertionFailureLog("cannot get right startTime, originalStartTime: \(self.model.startTime)")
            }
        }
    }

    func update(model: DurationSelectionModel) {
        self.model = model
        selectionView.update(model: model)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.mask.isUserInteractionEnabled = true
        layout(actionWrapper: actionWrapper)
    }

    private func layout(actionWrapper: UIView) {
        self.view.addSubview(actionWrapper)
        actionWrapper.backgroundColor = UIColor.clear
        actionWrapper.snp.makeConstraints { (make) in
            make.bottom.left.right.equalToSuperview()
            let maxHeight = 504 / 667 * UIScreen.main.bounds.height
            make.height.lessThanOrEqualTo(maxHeight)
        }
        layout(headerView: headerView, in: actionWrapper)
        layout(footerView: footerView, in: actionWrapper)
        layout(duritionView: selectionView,
               in: actionWrapper,
               below: headerView,
               above: footerView)
    }

    private func layout(headerView: UIView, in superview: UIView) {
        superview.addSubview(headerView)
        headerView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(68)
        }
    }

    private func layout(footerView: UIView, in superview: UIView) {
        superview.addSubview(footerView)
        footerView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(72)
        }
    }

    private func layout(duritionView: DurationSelectionView,
                        in superView: UIView,
                        below header: UIView,
                        above footer: UIView) {
        superView.addSubview(duritionView)
        duritionView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(header.snp.bottom)
            make.bottom.equalTo(footer.snp.top)
        }
    }

    func show(in controller: UIViewController) {
        self.isShowing = true
        controller.addChild(self)
        controller.view.addSubview(backgroundView)

        backgroundView.snp.makeConstraints { (make) in
            make.bottom.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(-200)
        }
        controller.view.addSubview(self.view)
        self.view.snp.remakeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(controller.view.snp.bottom)
        }
        controller.view.layoutIfNeeded()
        self.view.snp.remakeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        self.view.layoutIfNeeded()
        UIView.animate(withDuration: 0.25, animations: {
            controller.view.layoutIfNeeded()
        })
    }

    @objc
    func disappear() {
        self.isShowing = false
        if self.parent == nil {
            return
        }
        guard let superView = self.view.superview else {
            self.removeFromParent()
            backgroundView.removeFromSuperview()
            return
        }
        self.view.snp.remakeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(superView.snp.bottom)
        }
        UIView.animate(withDuration: 0.25,
                       animations: {
                        let height = UIScreen.main.bounds.height
                        self.view.transform = CGAffineTransform(translationX: 0, y: height)
        }) { [weak self] (_) in
            guard let `self` = self else { return }
            self.footerView.stopLoading()
            self.view.removeFromSuperview()
            self.view.transform = CGAffineTransform(translationX: 0, y: 0)
            self.removeFromParent()
            self.backgroundView.removeFromSuperview()
        }

    }
}
