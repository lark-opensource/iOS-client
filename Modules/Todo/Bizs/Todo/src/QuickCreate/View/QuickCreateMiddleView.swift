//
//  QuickCreateMiddleView.swift
//  Todo
//
//  Created by wangwanxin on 2021/3/16.
//

import CTFoundation
import RxSwift
import RxCocoa

/// Middle Container : Assignee + ( DueTimePicker || DueTimeContent )
class QuickCreateMiddleView: UIView {

    lazy var ownerContentView = QuickCreateOwnerView()
    lazy var timeContentView = QuickCreateTimeContentView()
    lazy var dueTimePickView = QuickCreateDueTimePickView()

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 16
        stackView.alignment = .center
        return stackView
    }()
    private lazy var rightGradient: CAGradientLayer = {
        let right = CAGradientLayer()
        right.startPoint = CGPoint(x: 0, y: 0.5)
        right.endPoint = CGPoint(x: 1.0, y: 0.5)
        right.isHidden = false
        return right
    }()
    private lazy var separateLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()
    private let disposeBag = DisposeBag()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupSubviews()
        addViewObserver()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let top = (scrollView.frame.height - 36) * 0.5
        rightGradient.frame = CGRect(x: scrollView.frame.width - 87, y: top, width: 87, height: 36)
    }

    private func setupSubviews() {
        addSubview(scrollView)
        scrollView.addSubview(stackView)
        layer.addSublayer(rightGradient)
        rightGradient.ud.setColors(
            [UIColor.ud.bgBody.withAlphaComponent(0.0),
             UIColor.ud.bgBody.withAlphaComponent(1.0)]
        )
        stackView.addArrangedSubview(ownerContentView)
        stackView.addArrangedSubview(separateLine)
        stackView.addArrangedSubview(dueTimePickView)
        stackView.addArrangedSubview(timeContentView)

        scrollView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        stackView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
            make.height.equalToSuperview()
        }
        separateLine.snp.makeConstraints { (make) in
            make.width.equalTo(1)
            make.height.equalTo(20)
        }
    }

    private func addViewObserver() {
        /// 当执行者或负责人有内容且选择截止时间都有的时候，分割线才有
        Observable.combineLatest(
            ownerContentView.rx.observe(Bool.self, #keyPath(UIView.isHidden)),
            dueTimePickView.rx.observe(Bool.self, #keyPath(UIView.isHidden))
        )
        .map { (ownerHidden, dueTimePickHidden) -> Bool in
            guard let dueTimePickHidden = dueTimePickHidden,
                  let ownerHidden = ownerHidden
            else {
                return true
            }
            return ownerHidden || dueTimePickHidden
        }
        .subscribe(onNext: { [weak self] (value) in
            self?.separateLine.isHidden = value
        })
        .disposed(by: disposeBag)

        /// 当执行者内容，选择截止时间，截止时间内容任意一个有，自己才显示
        Observable.combineLatest(
            ownerContentView.rx.observe(Bool.self, #keyPath(UIView.isHidden)),
            dueTimePickView.rx.observe(Bool.self, #keyPath(UIView.isHidden)),
            timeContentView.rx.observe(Bool.self, #keyPath(UIView.isHidden))
        )
        .map { (ownerHidden, dueTimePickHidden, dueTimeHidden) -> Bool in
            guard let dueTimePickHidden = dueTimePickHidden,
                  let dueTimeHidden = dueTimeHidden,
                  let ownerHidden = ownerHidden
            else {
                return true
            }
            return ownerHidden && dueTimePickHidden && dueTimeHidden
        }
        .subscribe(onNext: { [weak self] (value) in
            self?.isHidden = value
            self?.rightGradient.isHidden = !value
        })
        .disposed(by: disposeBag)

        /// 观察scroll view offset
        scrollView.rx.contentOffset
            .subscribe(onNext: { [weak self] (contentOffset) in
                guard let self = self else { return }
                self.handleGradientHidden(
                    contentSize: self.scrollView.contentSize,
                    contentoffset: contentOffset,
                    viewSize: self.scrollView.frame.size
                )
            })
            .disposed(by: disposeBag)

        /// 观察scoll view content size
        scrollView.rx.observe(CGSize.self, #keyPath(UIScrollView.contentSize)).asObservable()
            .subscribe(onNext: { [weak self] (contentSize) in
                guard let self = self, let contentSize = contentSize else { return }
                self.handleGradientHidden(
                    contentSize: contentSize,
                    contentoffset: self.scrollView.contentOffset,
                    viewSize: self.scrollView.frame.size
                )
            })
            .disposed(by: disposeBag)
    }

    private func handleGradientHidden(
        contentSize: CGSize,
        contentoffset: CGPoint,
        viewSize: CGSize) {
        let contentWidth = contentSize.width
        let contentOffsetX = contentoffset.x
        let viewWidth = viewSize.width

        if contentWidth <= viewWidth {
            rightGradient.isHidden = true
        } else {
            rightGradient.isHidden = false
        }

        if contentOffsetX + viewWidth < contentWidth {
            rightGradient.isHidden = false
        } else {
            rightGradient.isHidden = true
        }
    }

}
