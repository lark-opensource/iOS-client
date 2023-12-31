//
//  DatePickerForBoardcastViewController.swift
//  Moment
//
//  Created by zc09v on 2021/3/10.
//

import UIKit
import Foundation
import LarkUIKit
import UniverseDesignDatePicker
import LarkTraitCollection
import RxSwift

protocol DatePickerForBoardcastViewControllerDelegate: AnyObject {
    func selected(date: Date)
}

final class DatePickerForBoardcastViewControllerFactory {
    static func create(delegate: DatePickerForBoardcastViewControllerDelegate, defaultDate: Date) -> UIViewController {
        if Display.pad {
            let vc = DatePickerForBoardcastViewControllerForPad(defaultDate: defaultDate)
            vc.delegate = delegate
            vc.datePanel.layoutIfNeeded()
            vc.preferredContentSize = vc.datePanel.bounds.size
            return vc
        } else {
            let vc = DatePickerForBoardcastViewControllerForPhone(defaultDate: defaultDate)
            vc.delegate = delegate
            return vc
        }
    }
}

class DatePickerForBoardcastViewController: BaseUIViewController, DatePanelDelegate {
    weak var delegate: DatePickerForBoardcastViewControllerDelegate?
    fileprivate let datePanel: DatePanel
    init(defaultDate: Date) {
        datePanel = DatePanel(defaultDate: defaultDate)
        super.init(nibName: nil, bundle: nil)
        datePanel.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func cancel() {
        self.dismiss(animated: false, completion: nil)
    }

    func selected(date: Date) {
        self.delegate?.selected(date: date)
        self.dismiss(animated: false, completion: nil)
    }
}
final class DatePickerForBoardcastViewControllerForPad: DatePickerForBoardcastViewController {
    private let disposeBag = DisposeBag()
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(datePanel)
        updateUIForTraitCollectionChanged(isRegular: presentingViewController?.view.window?.traitCollection.horizontalSizeClass == .regular)
        view.backgroundColor = .ud.bgBody
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        RootTraitCollection.observer
            .observeRootTraitCollectionDidChange(for: self.view)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] traitChange in
                self?.updateUIForTraitCollectionChanged(isRegular: traitChange.new.horizontalSizeClass == .regular)
            }).disposed(by: self.disposeBag)
        updateUIForTraitCollectionChanged(isRegular: view.window?.traitCollection.horizontalSizeClass == .regular)
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        datePanel.snp.updateConstraints { make in
            make.left.equalToSuperview().offset(view.safeAreaInsets.left)
            make.top.equalToSuperview().offset(view.safeAreaInsets.top)
        }
    }

    private func updateUIForTraitCollectionChanged(isRegular: Bool) {
        if isRegular {
            datePanel.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(view.safeAreaInsets.top)
                make.left.equalToSuperview().offset(view.safeAreaInsets.left)
                make.width.greaterThanOrEqualTo(375)
            }
        } else {
            datePanel.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(view.safeAreaInsets.top)
                make.left.equalToSuperview().offset(view.safeAreaInsets.left)
                make.right.equalToSuperview()
            }
        }
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if preferredContentSize.width != datePanel.bounds.width
            || preferredContentSize.height != datePanel.bounds.height {
            preferredContentSize = datePanel.bounds.size
            view.layoutIfNeeded()
        }
    }
}

final class DatePickerForBoardcastViewControllerForPhone: DatePickerForBoardcastViewController {
    private let backGroud = UIView()

    override init(defaultDate: Date) {
        super.init(defaultDate: defaultDate)
        self.modalPresentationStyle = .overCurrentContext
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.clear
        backGroud.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapHandle)))
        self.view.addSubview(backGroud)
        backGroud.snp.makeConstraints { (make) in
            make.left.top.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        self.view.addSubview(datePanel)
        datePanel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(self.view.bounds.height)
        }
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        UIView.animate(withDuration: 0.3, animations: {
            self.backGroud.backgroundColor = UIColor.ud.N900.withAlphaComponent(0.3)
            self.datePanel.snp.remakeConstraints { make in
                make.left.right.bottom.equalToSuperview()
            }
            self.view.layoutIfNeeded()
        }) { (_) in
        }
    }

    @objc
    private func tapHandle() {
        self.dismiss(animated: false, completion: nil)
    }
}

protocol DatePanelDelegate: DatePickerForBoardcastViewControllerDelegate {
    func cancel()
}

final class DatePanel: UIView {
    weak var delegate: DatePanelDelegate?
    private let defaultDate: Date
    private var date: Date

    private lazy var datePicker: UDDateWheelPickerView = {
        let picker = UDDateWheelPickerView(date: defaultDate,
                                           wheelConfig: .init(mode: .yearMonthDayHour))
        picker.backgroundColor = .ud.bgBody
        return picker
    }()

    init(defaultDate: Date) {
        self.defaultDate = defaultDate
        self.date = defaultDate
        super.init(frame: .zero)
        self.backgroundColor = UIColor.ud.bgBody
        let cancelBut = UIButton(type: .system)
        let confirmBut = UIButton(type: .system)
        self.addSubview(cancelBut)
        self.addSubview(confirmBut)
        self.addSubview(datePicker)

        cancelBut.setTitle(BundleI18n.Moment.Lark_Community_Cancel, for: .normal)
        cancelBut.addTarget(self, action: #selector(cancelClick), for: .touchUpInside)
        cancelBut.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(10)
            make.left.equalToSuperview().offset(20)
            make.bottom.equalTo(datePicker.snp.top).offset(-10)
        }

        confirmBut.setTitle(BundleI18n.Moment.Lark_Community_Confirm, for: .normal)
        confirmBut.addTarget(self, action: #selector(confirmClick), for: .touchUpInside)
        confirmBut.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalTo(datePicker.snp.topMargin).offset(-10)
        }
        datePicker.select(date: defaultDate)
        datePicker.snp.makeConstraints { (make) in
            make.right.equalToSuperview()
            make.left.equalToSuperview()
            make.bottom.equalTo(self.safeAreaLayoutGuide.snp.bottom)
        }
        datePicker.dateChanged = { [weak self] date in
            self?.date = date
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func cancelClick() {
        self.delegate?.cancel()
    }

    @objc
    private func confirmClick() {
        self.delegate?.selected(date: self.date)
    }
}
