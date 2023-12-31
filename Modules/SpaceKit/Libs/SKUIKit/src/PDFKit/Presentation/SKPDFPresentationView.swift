//
//  SKPDFPresentationView.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2020/4/23.
//

import LarkUIKit
import SKFoundation
import SKResource
import RxSwift
import RxCocoa
import SnapKit
import UniverseDesignColor

public final class SKPDFPresentationBar: UIView {

    private lazy var closeImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = BundleResources.SKResource.Common.Global.icon_global_close_nor.ud.withTintColor(UDColor.iconN1)
        return imageView
    }()

    private lazy var closeLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.SKResource.Drive_Drive_PresentationEnd
        label.font = UIFont.systemFont(ofSize: 17)
        label.textColor = UIColor.ud.N900
        return label
    }()

    private lazy var closeControl: UIControl = {
        let control = UIControl()
        return control
    }()

    private lazy var pageLabel: UILabel = {
        let label = UILabel()
        label.text = "- / -"
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.N900
        return label
    }()

    public var closeAction: Driver<Void> {
        return closeControl.rx.controlEvent(.touchUpInside).asDriver()
    }

    var estimateHeight: CGFloat {
        return 44 + safeAreaInsets.top
    }

    public let titleRelay = BehaviorRelay<String>(value: "")
    public let closeTitleRelay = BehaviorRelay<String>(value: BundleI18n.SKResource.Drive_Drive_PresentationEnd)
    private let bag = DisposeBag()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()

        titleRelay.bind(to: pageLabel.rx.text).disposed(by: bag)
        closeTitleRelay.bind(to: closeLabel.rx.text).disposed(by: bag)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = UIColor.ud.N00

        addSubview(closeControl)
        closeControl.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.left.equalTo(safeAreaLayoutGuide.snp.left)
            make.height.equalTo(44)
        }

        closeControl.addSubview(closeImageView)
        closeImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }

        closeControl.addSubview(closeLabel)
        closeLabel.snp.makeConstraints { make in
            make.left.equalTo(closeImageView.snp.right).offset(8)
            make.right.equalToSuperview().offset(-8)
            make.centerY.equalTo(closeImageView.snp.centerY)
        }

        addSubview(pageLabel)
        pageLabel.snp.makeConstraints { make in
            make.right.equalTo(safeAreaLayoutGuide.snp.right).offset(-20)
            make.centerY.equalTo(closeControl.snp.centerY)
        }
    }
}

public final class SKPDFPresentationView: UIView {

    private let bag = DisposeBag()

    public var titleRelay: BehaviorRelay<String> {
        return presentationBar.titleRelay
    }

    public var closeTitleRelay: BehaviorRelay<String> {
        return presentationBar.closeTitleRelay
    }
    
    public var closeAction: Driver<Void> {
        return presentationBar.closeAction
    }

    private var isBarShown = false
    private lazy var presentationBar: SKPDFPresentationBar = {
        let bar = SKPDFPresentationBar()
        return bar
    }()

    private lazy var immersionTask: SKImmersionTask = {
        return SKImmersionTask(taskInterval: 3) { [weak self] in
            DispatchQueue.main.async {
                self?.hidePresentationBarIfNeed()
            }
        }
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear

        setupUI()

        self.immersionTask.resume()
        self.addSingleTap { [weak self] in
            DispatchQueue.main.async {
                self?.togglePresentationBar()
                self?.immersionTask.resume()
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        // 默认隐藏演示工具栏
        addSubview(presentationBar)
        presentationBar.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(-presentationBar.estimateHeight)
            make.height.equalTo(presentationBar.estimateHeight)
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let topOffset: CGFloat
        if isBarShown {
            topOffset = 0
        } else {
            topOffset = -presentationBar.estimateHeight
        }
        presentationBar.snp.updateConstraints { make in
            make.top.equalToSuperview().offset(topOffset)
            make.height.equalTo(presentationBar.estimateHeight)
        }
    }

    public func addSwipe(_ diretion: UISwipeGestureRecognizer.Direction,
                  action: @escaping () -> Void) {
        let swipe = UISwipeGestureRecognizer()
        swipe.direction = diretion
        self.addGestureRecognizer(swipe)
        swipe.delegate = self
        swipe.rx.event
            .subscribe(onNext: { [weak self] _ in
                action()
                DispatchQueue.main.async {
                    self?.hidePresentationBarIfNeed()
                }
            }).disposed(by: bag)
    }

    func addSingleTap(action: @escaping () -> Void) {
        let tap = UITapGestureRecognizer()
        self.addGestureRecognizer(tap)
        tap.delegate = self
        tap.rx.event
            .subscribe(onNext: { _ in
                action()
            }).disposed(by: bag)
    }

    private func hidePresentationBarIfNeed() {
        // 已经隐藏，不重复处理
        if !isBarShown { return }
        isBarShown = false
        presentationBar.snp.updateConstraints { make in
            make.top.equalToSuperview().offset(-presentationBar.estimateHeight)
        }
        UIView.animate(withDuration: 0.2) {
            self.layoutIfNeeded()
        }
    }

    private func showPresentationBarIfNeed() {
        // 已经展示，不重复处理
        if isBarShown { return }
        isBarShown = true
        presentationBar.snp.updateConstraints { make in
            make.top.equalToSuperview().offset(0)
        }
        UIView.animate(withDuration: 0.2) {
            self.layoutIfNeeded()
        }
    }

    private func togglePresentationBar() {
        if isBarShown {
            hidePresentationBarIfNeed()
        } else {
            showPresentationBarIfNeed()
        }
    }
}

extension SKPDFPresentationView: UIGestureRecognizerDelegate {

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let point = touch.location(in: presentationBar)
        // 不识别 bar 内的手势
        return !presentationBar.bounds.contains(point)
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if otherGestureRecognizer.view == self {
            // 不能和自己view上的其他手势同时识别
            return false
        }
        // 允许和其他手势同时识别，避免和 VC 的手势冲突导致收不到事件
        return true
    }
}
