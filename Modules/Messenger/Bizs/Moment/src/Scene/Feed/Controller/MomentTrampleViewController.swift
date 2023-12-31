//
//  MomentTrampleViewController.swift
//  Moment
//
//  Created by ByteDance on 2022/6/27.
//

import Foundation
import LarkUIKit
import UIKit
import FigmaKit
import UniverseDesignToast
import RxSwift
import SnapKit
import UniverseDesignButton
import UniverseDesignPopover
import LKCommonsLogging
import LarkContainer
import LarkTraitCollection

/// 点踩的实体
final class TrampleModel {
    var id: String //ID
    var content: String // content
    var height: CGFloat // cellHeight
    var selected: Bool // 是否选中当前选项
    init(id: String, content: String, height: CGFloat, selected: Bool) {
        self.id = id
        self.content = content
        self.height = height
        self.selected = selected
    }
}

final class MomentTrampleViewController: BaseUIViewController, UITableViewDataSource, UITableViewDelegate, UserResolverWrapper {
    let userResolver: UserResolver
    static let logger = Logger.log(MomentTrampleViewController.self, category: "Module.Moments.MomentTrampleViewController")
    /// load效果
    private var hudView: UDToast?
    /// 当前实体ID
    private var entityID: String = ""
    /// 当前实体的类型（动态/评论）
    private  var entityType: RawData.DislikeEntityType = .post
    /// 点踩原因数据
    private var dislikeReason: [RawData.DislikeReason] = []
    /// 回调函数用来处理提交完请求之后的动作状态
    var finishCallBack: (() -> Void)?
    @ScopedInjectedLazy private var dislikeService: DislikeApiService?

    /// 负责统一回收RX相关的订阅
    public let disposeBag = DisposeBag()

    /// 处理后的自定义踩数据
    private lazy var trampleInfo: [TrampleModel] = {
        var trampleInfo = [TrampleModel]()
        for data in dislikeReason {
            /// 计算每一组数据的cell的高度，非pad下，64为label文本与屏幕的两端间距之和；pad下，popOver总宽度固定353，label宽度固定297； 24为label与cell上下之间的总差值
            let heightForData = (!Display.pad ?
                                 MomentsDataConverter.heightForString(data.description_p, onWidth: self.view.frame.width - 64, font: .systemFont(ofSize: 16)) :
                                    MomentsDataConverter.heightForString(data.description_p, onWidth: 297, font: .systemFont(ofSize: 16))) + 24
            trampleInfo.append(TrampleModel(id: data.id, content: data.description_p, height: heightForData, selected: false))
        }
        return trampleInfo
    }()
    /// 文本内容（导航原因）
    let titleText = BundleI18n.Moment.Moments_DislikeAPostWhy_Title
    /// 文本高度（导航原因高度）
    private lazy var titleHeight: CGFloat = {
        /// 非pad下，距离两端距离left：16，right：56，总间距72；pad下，距离两端都为25，总宽度353
        let titleHeight = !Display.pad ? MomentsDataConverter.heightForString(titleText,
                                                                              onWidth: self.view.frame.width - 72,
                                                                              font: .systemFont(ofSize: 17, weight: .medium)) :
                                                                            MomentsDataConverter.heightForString(titleText,
                                                                                                                 onWidth: 303,
                                                                                                                 font: .systemFont(ofSize: 17, weight: .medium))
        return titleHeight
    }()
    /// 文本label（导航原因label）
    private lazy var titleLabel: UILabel = {
        let causeLabel = UILabel()
        causeLabel.text = titleText
        causeLabel.font = .systemFont(ofSize: 17, weight: .medium)
        causeLabel.textColor = UIColor.ud.textTitle
        causeLabel.numberOfLines = 0
        return causeLabel
    }()
    /// 子文本内容（细节详情）
    let subTitleText = BundleI18n.Moment.Moments_DislikeAPostWhy_Desc
    /// 子文本高度（细节详情高度）
    private lazy var subTitleHeight: CGFloat = {
        /// 非pad下，距离两端距离left：16，right：56，总间距72；pad下，距离两端都为25，总宽度353
        let titleDetailHeight = !Display.pad ? MomentsDataConverter.heightForString(subTitleText, onWidth: self.view.frame.width - 72, font: .systemFont(ofSize: 14))
        : MomentsDataConverter.heightForString(subTitleText, onWidth: 303, font: .systemFont(ofSize: 14))
        return titleDetailHeight
    }()
    /// 子文本label（细节详情label）
    private lazy var subTitleLabel: UILabel = {
        let causeDetailLabel = UILabel()
        causeDetailLabel.text = subTitleText
        causeDetailLabel.font = .systemFont(ofSize: 14)
        causeDetailLabel.textColor = UIColor.ud.textPlaceholder
        causeDetailLabel.numberOfLines = 0
        return causeDetailLabel
    }()
    /// 弹出的整体页面
    private lazy var trampleView: UIView = {
        let trampleView = UIView()
        trampleView.backgroundColor = UIColor.ud.bgFloatBase
        trampleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        trampleView.layer.cornerRadius = 16
        trampleView.clipsToBounds = true
        return trampleView
    }()
    /// 非pad下弹出页面的动画效果
    private var normalTransition = SharePanelTransition()
    /// 判断是否转过屏标志
    private var didAppear: Bool = false
    /// 列表上的分割线label
    private lazy var crossLineLabel: UILabel = {
        let crossLineLabel = UILabel()
        crossLineLabel.backgroundColor = UIColor.ud.lineDividerDefault
        return crossLineLabel
    }()

    /// 选项内容-列表展示
    private lazy var trampleTableView: UITableView = {
        let trampleTableView = UITableView(frame: .zero)
        trampleTableView.delegate = self
        trampleTableView.dataSource = self
        trampleTableView.showsVerticalScrollIndicator = false
        trampleTableView.backgroundColor = UIColor.clear
        registerTableViewCells(trampleTableView)
        trampleTableView.contentInsetAdjustmentBehavior = .never
        return trampleTableView
    }()

    /// tableview的高度
    private lazy var heightForTableView: CGFloat = {
        var heightForTableView: CGFloat = 0.0
        /// 非pad与pad下，footer下的宽度分别为8和4
        for option in trampleInfo {
            heightForTableView += !Display.pad ? option.height + 8 : option.height + 4
        }
        heightForTableView -= !Display.pad ? 8 : 4
        return heightForTableView
    }()
    /// 返回按钮
    private lazy var trampleCloseBtn: UIButton = {
        let trampleCloseBtn = UIButton()
        trampleCloseBtn.setImage(Resources.momentsTrampleClose, for: .normal)
        trampleCloseBtn.addTarget(self, action: #selector(close), for: .touchUpInside)
        return trampleCloseBtn
    }()
    /// 提交按钮
    private lazy var trampleSubmitBtn: UDButton = {
        let trampleSubmitBtn = UDButton(UDButtonUIConifg.primaryBlue)
        trampleSubmitBtn.setTitle(BundleI18n.Moment.Lark_Community_Submit, for: .normal)
        trampleSubmitBtn.titleLabel?.font = .systemFont(ofSize: 17)
        trampleSubmitBtn.isEnabled = false
        trampleSubmitBtn.addTarget(self, action: #selector(submit), for: .touchUpInside)
        trampleSubmitBtn.showLoading()
        return trampleSubmitBtn
    }()
    /// 计算弹出页面的高度
    private lazy var heightForView: CGFloat = {
        /// 非pad下14（顶部距离title） + 4（title与subTitle间距） + 14（subTitle与分隔线间距） + 16（分割线与tableView间距） + 32（tableView与submitBtn） + 56（submitBtn与底部距离）+  各组件高度；
        /// pad下14 （顶部距离title） + 4 （title与subTitle间距）+ 14（subTitle与分隔线间距） + 16（分割线与tableView间距）+ 32（tableView与submitBtn） + 16 （submitBtn与底部距离）+ 各组件高度 ；
        /// 0.5为分割线高度
        let heightForView: CGFloat = !Display.pad ? 136 + titleHeight + subTitleHeight + 0.5 + heightForTableView + 48 :
        96 + titleHeight + subTitleHeight + 0.5 + heightForTableView + 48
        return heightForView
    }()

    init(userResolver: UserResolver, entityID: String, entityType: RawData.DislikeEntityType, dislikeReason: [RawData.DislikeReason]) {
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
        self.dislikeReason = dislikeReason
        self.entityID = entityID
        self.entityType = entityType
        if !Display.pad {
            self.transitioningDelegate = normalTransition
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        /// 弹出的选项页面vc的背景色
        self.view.backgroundColor = UIColor.clear
        /// 添加弹出的点踩页面
        self.view.addSubview(trampleView)
        trampleView.snp.makeConstraints { (make) in
            make.width.equalToSuperview()
            if !Display.pad {
                make.height.equalTo(heightForView)
                make.top.greaterThanOrEqualTo(self.view.safeAreaLayoutGuide.snp.top).priority(.required)
                make.bottom.equalToSuperview()
            } else {
                make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
                make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
            }
        }
        /// C视图下添加关闭按钮
        trampleView.addSubview(trampleCloseBtn)
        trampleCloseBtn.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(14)
            make.right.equalToSuperview().offset(-16)
            make.size.equalTo(CGSize(width: 24, height: 24))
        }
        /// 添加文本label（导航原因label）
        trampleView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(14)
            make.left.equalToSuperview().offset(!Display.pad ? 16 : 25)
            make.right.equalTo(!Display.pad ? trampleCloseBtn.snp.left : trampleView.snp.right).offset(!Display.pad ? -16 : -25)
            make.height.equalTo(titleHeight)
        }
        /// 添加子文本label（细节详情label）
        trampleView.addSubview(subTitleLabel)
        subTitleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.left.equalToSuperview().offset(!Display.pad ? 16 : 25)
            make.right.equalTo(!Display.pad ? trampleCloseBtn.snp.left : trampleView.snp.right).offset(!Display.pad ? -16 : -25)
            make.height.equalTo(subTitleHeight)
        }
        /// 添加分割线
        trampleView.addSubview(crossLineLabel)
        crossLineLabel.snp.makeConstraints { (make) in
            make.top.equalTo(subTitleLabel.snp.bottom).offset(14)
            make.width.equalToSuperview()
            make.height.equalTo(0.5)
        }
        /// 添加点踩的选项内容，tableview，tableview底部由submitBtn确定
        /// 添加提交按钮
        trampleView.addSubview(trampleTableView)
        trampleView.addSubview(trampleSubmitBtn)
        trampleTableView.snp.makeConstraints { (make) in
            make.top.equalTo(crossLineLabel.snp.bottom).offset(16)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalTo(trampleSubmitBtn.snp.top).offset(-32)
        }
        trampleSubmitBtn.snp.makeConstraints { (make) in
            make.top.equalTo(trampleTableView.snp.bottom).offset(32)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(!Display.pad ? -56 : -16)
            make.height.equalTo(48)
        }
        trampleCloseBtn.isHidden = presentingViewController?.view.window?.traitCollection.horizontalSizeClass == .regular
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if didAppear {
            self.dismiss(animated: true)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !Display.pad {
            trampleTableView.bounces = heightForView <= self.view.frame.height - self.view.safeAreaInsets.top ? false : true
        } else {
            self.preferredContentSize = CGSize(width: 353, height: heightForView)
            trampleTableView.bounces = heightForView <= self.view.frame.height ? false : true
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        didAppear = true
        if Display.pad {
            self.trampleCloseBtn.isHidden = view.window?.traitCollection.horizontalSizeClass == .regular
            RootTraitCollection.observer
                .observeRootTraitCollectionDidChange(for: self.view)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] traitChange in
                    self?.trampleCloseBtn.isHidden = traitChange.new.horizontalSizeClass == .regular
                }).disposed(by: self.disposeBag)
        }
    }

    private func registerTableViewCells(_ tableView: UITableView) {
        tableView.register(MomentTrampleViewCell.self, forCellReuseIdentifier: MomentTrampleViewCell.lu.reuseIdentifier)
    }

    private func updateSubmitBtn() {
        for option in trampleInfo where option.selected {
            trampleSubmitBtn.isEnabled = true
            return
        }
        trampleSubmitBtn.isEnabled = false
    }

    @objc
    private func close() {
        self.dismiss(animated: true)
    }

    @objc
    private func submit() {
        var listDislikeID = [String]()
        for option in trampleInfo where option.selected {
            listDislikeID.append(option.id)
        }
        dislikeService?.createDislike(entityID: entityID, entityType: entityType, reasonIds: listDislikeID)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.dismiss(animated: true,
                              completion: { [weak self] in
                    self?.finishCallBack?()
                })
            }, onError: { [weak self] error in
                Self.logger.error("createTrample error", error: error)
                guard let window = self?.view.window else { return }
                UDToast.showFailure(with: BundleI18n.Moment.Lark_Community_UnableToMakeChangesToast, on: window)
                }).disposed(by: self.disposeBag)
    }
    // MARK: - UITableViewDataSource, UITableViewDelegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return trampleInfo.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return trampleInfo[indexPath.section].height
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let momentTrampleViewCell = trampleTableView.dequeueReusableCell(withIdentifier: MomentTrampleViewCell.lu.reuseIdentifier, for: indexPath) as? MomentTrampleViewCell
        momentTrampleViewCell?.feedbackInfo = trampleInfo[indexPath.section]
        momentTrampleViewCell?.onTapCallBack = { [weak self] in
            self?.updateSubmitBtn()
        }
        return momentTrampleViewCell ?? MomentTrampleViewCell()
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section != trampleInfo.count - 1 {
            return !Display.pad ? 8 : 4
        }
        return 0.01
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.01
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
}
