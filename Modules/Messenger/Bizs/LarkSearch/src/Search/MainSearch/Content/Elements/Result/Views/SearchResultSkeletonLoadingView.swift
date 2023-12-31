//
//  SearchResultSkeletonLoadingView.swift
//  LarkSearch
//
//  Created by ByteDance on 2023/7/26.
//

import Foundation
import LarkUIKit
import SnapKit
import UniverseDesignColor
import UniverseDesignLoading
import SkeletonView
import LarkContainer
import LarkMessengerInterface

class SearchResultSkeletonLoadingCell: UITableViewCell {
    private var gradient: SkeletonGradient = SkeletonGradient(baseColor: UIColor.ud.N200.withAlphaComponent(0.5),
                                                              secondaryColor: UIColor.ud.N200)
    private let avatar: UIView = {
        let avatar = UIView()
        avatar.backgroundColor = UIColor.ud.N900
        avatar.layer.cornerRadius = 24
        avatar.alpha = 0.08
        avatar.isSkeletonable = true
        return avatar
    }()

    private let titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.backgroundColor = UIColor.ud.N900
        titleLabel.alpha = 0.08
        titleLabel.layer.cornerRadius = 6
        titleLabel.layer.masksToBounds = true
        titleLabel.isSkeletonable = true
        return titleLabel
    }()

    private let descriptionLabel: UILabel = {
        let descriptionLabel = UILabel()
        descriptionLabel.backgroundColor = UIColor.ud.N900
        descriptionLabel.alpha = 0.08
        descriptionLabel.layer.cornerRadius = 6
        descriptionLabel.layer.masksToBounds = true
        descriptionLabel.isSkeletonable = true
        return descriptionLabel
    }()

    private let bgView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        view.backgroundColor = UIColor.ud.bgBody
        return view
    }()

    private let divider: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBase
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    private func setupViews() {
        backgroundColor = UIColor.clear
        isSkeletonable = true

        contentView.addSubview(bgView)
        contentView.addSubview(divider)
        bgView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        divider.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(bgView.snp.bottom)
            make.height.equalTo(12)
        }

        bgView.addSubview(avatar)
        bgView.addSubview(titleLabel)
        bgView.addSubview(descriptionLabel)

        avatar.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 48, height: 48))
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().offset(-10)
        }

        titleLabel.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 120, height: 14))
            make.leading.equalTo(avatar.snp.trailing).offset(12)
            make.top.equalTo(avatar.snp.top)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.height.equalTo(14)
            make.leading.equalTo(avatar.snp.trailing).offset(12)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalTo(avatar.snp.bottom)
        }
    }

    func cellWillDisplay(supportPadStyle: Bool) {
        if supportPadStyle {
            updateToPadStyle()
        } else {
            updateToMobileStyle()
        }
        hideSkeleton()
        gradient = SkeletonGradient(baseColor: UIColor.ud.N200.withAlphaComponent(0.5),
                                    secondaryColor: UIColor.ud.N200)
        layoutIfNeeded()
        showAnimatedGradientSkeleton(usingGradient: gradient)
    }

    private func updateToPadStyle() {
        backgroundColor = UIColor.ud.bgBase
        bgView.layer.cornerRadius = 8
        divider.isHidden = false
    }

    private func updateToMobileStyle() {
        backgroundColor = UIColor.clear
        bgView.layer.cornerRadius = 0
        divider.isHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SearchResultSkeletonLoadingView: UIView, UITableViewDelegate, UITableViewDataSource {
    private let loadingCellCount: Int = 20
    let userResolver: UserResolver
    var isFullScreenStatus: Bool = false
    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = UIColor.clear
        tableView.isUserInteractionEnabled = false
        tableView.isScrollEnabled = false
        tableView.register(SearchResultSkeletonLoadingCell.self, forCellReuseIdentifier: "SearchResultSkeletonLoadingCell")
        tableView.separatorStyle = .none
        tableView.isSkeletonable = true
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        return tableView
    }()

    init(frame: CGRect, userResolver: UserResolver) {
        self.userResolver = userResolver
        super.init(frame: frame)
        backgroundColor = UIColor.ud.bgBody
        isFullScreenStatus = currentIsFullScreenStatus()
        isSkeletonable = true
        tableView.delegate = self
        tableView.dataSource = self
        addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        updateStyle()
    }

    func setHidden(isHidden: Bool, animated: Bool = false) {
        guard isHidden != self.isHidden else { return }
        if animated {
            if isHidden {
                UIView.animate(withDuration: 0.15, animations: { [weak self] in
                    self?.alpha = 0
                }, completion: { [weak self] _ in
                    self?.setHidden(isHidden: isHidden, animated: false)
                })
            } else {
                self.alpha = 0
                self.isHidden = false
                UIView.animate(withDuration: 0.15, animations: { [weak self] in
                    self?.alpha = 1
                }, completion: { [weak self] _ in
                    self?.setHidden(isHidden: isHidden, animated: false)
                })
            }
        } else {
            self.isHidden = isHidden
            self.alpha = 1
            if isHidden {
                stopSkeletonAnimation()
            } else {
                startSkeletonAnimation()
            }
        }
    }

    // loading skeleton使用的是CGColor，无法根据明暗模式自动变色，需要刷新
    func updateDarkLightMode() {
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultSkeletonLoadingCell", for: indexPath)
        return cell
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let _cell = cell as? SearchResultSkeletonLoadingCell {
            _cell.cellWillDisplay(supportPadStyle: isFullScreenStatus)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return loadingCellCount
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if currentIsFullScreenStatus() != isFullScreenStatus {
            isFullScreenStatus = currentIsFullScreenStatus()
            updateStyle()
            tableView.reloadData()
        }
    }

    private func updateStyle() {
        if isFullScreenStatus {
            backgroundColor = UIColor.ud.bgBase
            tableView.snp.updateConstraints { make in
                make.top.equalToSuperview().offset(16)
            }
        } else {
            backgroundColor = UIColor.ud.bgBody
            tableView.snp.updateConstraints { make in
                make.top.equalToSuperview()
            }
        }
    }

    private func currentIsFullScreenStatus() -> Bool {
        var supportPadStyle = false
        if let service = try? userResolver.resolve(assert: SearchOuterService.self), service.enableUseNewSearchEntranceOnPad() {
            supportPadStyle = !service.isCompactStatus() && UIDevice.btd_isPadDevice()
        }
        return supportPadStyle
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
