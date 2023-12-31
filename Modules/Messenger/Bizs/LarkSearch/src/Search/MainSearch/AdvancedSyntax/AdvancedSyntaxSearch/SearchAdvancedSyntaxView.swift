//
//  SearchAdvancedSyntaxView.swift
//  LarkSearch
//
//  Created by ByteDance on 2023/12/8.
//

import Foundation
import LarkUIKit
import RxSwift
import SnapKit
import LarkContainer
import LKCommonsLogging
import LarkCore
import LarkSearchCore
import LarkAccountInterface
import UniverseDesignShadow
import LarkMessengerInterface

class SearchAdvancedSyntaxView: UIView, UserResolverWrapper {
    // 设计要求，高级语法视图，最佳高度为296，在小屏设备上，底部与键盘最小间隔为32
    static let optimalHeight: CGFloat = 296
    static let minimumInterval: CGFloat = 32
    static let inset: CGFloat = 8
    static let logger = Logger.log(SearchAdvancedSyntaxView.self, category: "Module.IM.Search")
    let userResolver: UserResolver
    let viewModel: SearchAdvancedSyntaxViewModel
    var keyBoardHeight: CGFloat = 300
    private let disposeBag = DisposeBag()

    private let shadowView: UIView = {
        let shadowView = UIView()
        shadowView.layer.shadowColor = UDShadowColorTheme.s2DownColor.cgColor
        shadowView.layer.shadowOpacity = 0.02
        shadowView.layer.shadowOffset = CGSize(width: 0, height: 2)
        shadowView.layer.shadowRadius = 4
        shadowView.layer.masksToBounds = false
        return shadowView
    }()

    private lazy var resultTableView: UITableView = {
        let resultTableView = UITableView()
        resultTableView.backgroundColor = UIColor.ud.bgBody
        resultTableView.bounces = false
        resultTableView.layer.borderColor = UIColor.ud.lineBorderCard.cgColor
        resultTableView.layer.borderWidth = 1
        resultTableView.layer.cornerRadius = 8
        resultTableView.contentInset = UIEdgeInsets(top: Self.inset, left: 0, bottom: Self.inset, right: 0)
        resultTableView.scrollIndicatorInsets = UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0)
        resultTableView.dataSource = self
        resultTableView.delegate = self
        resultTableView.delaysContentTouches = false
        resultTableView.translatesAutoresizingMaskIntoConstraints = false
        resultTableView.register(SearchAdvancedSyntaxCell.self, forCellReuseIdentifier: "SearchAdvancedSyntaxCell")
        return resultTableView
    }()

    init(userResolver: UserResolver, viewModel: SearchAdvancedSyntaxViewModel) {
        self.userResolver = userResolver
        self.viewModel = viewModel
        super.init(frame: .zero)
        setupViews()
        setupSubscriptions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        backgroundColor = UIColor.clear
        isHidden = true
        addSubview(shadowView)
        shadowView.addSubview(resultTableView)
        resultTableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        let tapGes = UITapGestureRecognizer(target: self, action: #selector(dismissSelf))
        tapGes.delegate = self
        addGestureRecognizer(tapGes)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        resultTableView.separatorStyle = .none
        updateInterval()
    }

    private func updateInterval() {
        let height = self.tableViewHeight
        resultTableView.showsVerticalScrollIndicator = (resultTableView.contentSize.height + 2 * Self.inset > height)

        if let service = try? userResolver.resolve(assert: SearchOuterService.self),
           service.enableUseNewSearchEntranceOnPad(),
           !service.isCompactStatus() {
            shadowView.snp.remakeConstraints { make in
                make.leading.trailing.top.equalToSuperview()
                make.height.equalTo(height)
            }
        } else {
            shadowView.snp.remakeConstraints { make in
                make.top.equalToSuperview()
                make.leading.equalToSuperview().offset(8)
                make.trailing.equalToSuperview().offset(-8)
                make.height.equalTo(height)
            }
        }
    }

    var tableViewHeight: CGFloat {
        var maxHeight: CGFloat = self.frame.height - self.keyBoardHeight - Self.minimumInterval
        if maxHeight < 0 || Self.optimalHeight <= maxHeight {
            maxHeight = Self.optimalHeight
        }
        let contentHeight = resultTableView.contentSize.height + 2 * Self.inset
        return min(maxHeight, contentHeight)
    }

    private func setupSubscriptions() {
        viewModel.shouldReloadData
            .drive(onNext: { [weak self] shouldReload in
                guard let self = self, shouldReload else { return }
                self.resultTableView.reloadData()
            })
            .disposed(by: disposeBag)

        viewModel.shouldShow
            .drive(onNext: { [weak self] shouldShow in
                guard let self = self else { return }
                self.shouldShow(shouldShow)
            })
            .disposed(by: disposeBag)

        // 根据键盘高度调整视图最大高度
        NotificationCenter.default.rx.notification(UIResponder.keyboardDidShowNotification)
            .bind { [weak self] (notification) in
                guard let self = self else { return }
                self.keyboardDidShowOrChange(notification)
            }
            .disposed(by: disposeBag)

        NotificationCenter.default.rx.notification(UIResponder.keyboardDidChangeFrameNotification)
            .bind { [weak self] (notification) in
                guard let self = self else { return }
                self.keyboardDidShowOrChange(notification)
            }
            .disposed(by: disposeBag)

        resultTableView.rx.observe(CGSize.self, "contentSize")
            .distinctUntilChanged()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.updateInterval()
            })
            .disposed(by: disposeBag)
    }

    private func keyboardDidShowOrChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo, let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            assertionFailure()
            return
        }
        keyBoardHeight = keyboardFrame.height
        updateInterval()
    }

    private func shouldShow(_ shouldShow: Bool) {
        if !shouldShow {
            isHidden = !shouldShow
        } else {
            resultTableView.reloadData()
            layoutIfNeeded()
            resultTableView.alpha = 0
            isHidden = !shouldShow
            resultTableView.transform = CGAffineTransform(translationX: 0, y: -8)
            UIView.animate(withDuration: 0.15) {
                self.resultTableView.alpha = 1
                self.resultTableView.transform = .identity
            } completion: { _ in
                self.resultTableView.alpha = 1
                self.resultTableView.transform = .identity
            }
        }
    }

    @objc
    private func dismissSelf() {
        shouldShow(false)
    }
}

extension SearchAdvancedSyntaxView: UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate {
    // MARK: - UITableViewDataSource & UITableViewDelegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.resultCellViewModels.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return SearchAdvancedSyntaxCell.cellHeight
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchAdvancedSyntaxCell", for: indexPath)
        if let _cell = cell as? SearchAdvancedSyntaxCell, let cellViewModel = viewModel.resultCellViewModels[safe: indexPath.row] {
            _cell.set(viewModel: cellViewModel)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        viewModel.didSelect(at: indexPath)
        dismissSelf()
    }

    // MARK: - UIGestureRecognizerDelegate
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return !resultTableView.convert(resultTableView.bounds, to: self).contains(touch.location(in: self))
    }
}
