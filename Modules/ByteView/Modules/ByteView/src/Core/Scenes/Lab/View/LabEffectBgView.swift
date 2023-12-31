//
//  LabEffectBgView.swift
//  ByteView
//
//  Created by wangpeiran on 2021/3/2.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignIcon
import ByteViewCommon
import ByteViewUI

protocol LabEfffectBgViewDelegate: AnyObject {
    func didTapEffect(effectModel: ByteViewEffectModel)
    func hiddenEffectSlider()
}

class LabEffectBgView: UIView, EffectBgDataDelegate {
    private struct Layout {
        static func cellWidth() -> CGFloat {
            LabEffectBgCell.Layout.cellImageWidth() + 2 * LabEffectBgCell.Layout.cellBorderTotalWidth()
        }

        static func cellHeight(isHasTitle: Bool, isHasDot: Bool) -> CGFloat {
            if isHasTitle {
                return LabEffectBgCell.Layout.cellImageWidth() + LabEffectBgCell.Layout.cellBorderTotalWidth() + LabEffectBgCell.Layout.titleTopMargin() + LabEffectBgCell.Layout.titleHeight() + (isHasDot ? LabEffectBgCell.Layout.dotHeight() + LabEffectBgCell.Layout.dotTopMargin : 0)
            } else {
                return Layout.cellWidth()
            }
        }
        static let landscapeModeCellSpacing: CGFloat = 16  // 横屏模式视觉间隔为16

        static func viewWidth(isLandscapeMode: Bool) -> CGFloat {
            if isLandscapeMode {
                let lineCount: CGFloat = max(VCScene.bounds.height, VCScene.bounds.width) > 720 ? 5 : 4
                return LabEffectBgCell.Layout.cellImageWidth() * lineCount + landscapeModeCellSpacing * (lineCount + 1)
            }
            return Display.pad ? VCScene.bounds.width : min(VCScene.bounds.height, VCScene.bounds.width)  // 横竖屏的时候 VCScene.bounds宽高会变化
        }

        static func collectionRightMarin(labType: EffectType, isLandScapeMode: Bool) -> CGFloat {
            if Layout.isRegular() {
                return 28 - LabEffectBgCell.Layout.cellBorderTotalWidth()
            } else {
                return Layout.cellHorizonSpacing(labType: labType, isLandScapeMode: isLandScapeMode)
            }
        }

        static func cellVerticalSpacing(labType: EffectType) -> CGFloat {
            var lineSpace: CGFloat = 0
            if labType == .animoji {
                lineSpace = (Layout.isRegular() ? 20 : 16) - LabEffectBgCell.Layout.cellBorderTotalWidth() * 2
            } else if labType == .retuschieren {
                lineSpace = (Layout.isRegular() ? 16 : 9) - LabEffectBgCell.Layout.cellBorderTotalWidth()
            } else if labType == .filter {
                lineSpace = (Layout.isRegular() ? 16 : 9) - LabEffectBgCell.Layout.cellBorderTotalWidth()
            }
            return lineSpace
        }

        static func cellHorizonSpacing(labType: EffectType, isLandScapeMode: Bool) -> CGFloat {
            if Layout.isRegular() {
                return 20 - 2 * LabEffectBgCell.Layout.cellBorderTotalWidth()
            } else {
                if labType == .retuschieren {  // 美颜不一样，不能均分，算出宽度系统自己均分
                    return 0
                } else if isLandScapeMode {
                    return landscapeModeCellSpacing - 2 * LabEffectBgCell.Layout.cellBorderTotalWidth()
                } else {
                    return floor((Layout.viewWidth(isLandscapeMode: isLandScapeMode) - LabEffectBgCell.Layout.cellImageWidth() * 5) / 6) - 2 * LabEffectBgCell.Layout.cellBorderTotalWidth()
                }
            }
        }

        static func collectionTopMargin() -> CGFloat {
            return (Layout.isRegular() ? 20 : 16) - LabEffectBgCell.Layout.cellBorderTotalWidth()
        }

        static func isRegular() -> Bool { VCScene.rootTraitCollection?.isRegular ?? false }

        static func createBeautyBackView() -> UIView {
            let view = UIView(frame: .zero)
            view.clipsToBounds = false
            let imgView = UIImageView(image: UDIcon.getIconByKey(.leftOutlined, iconColor: .ud.iconN2, size: Layout.isRegular() ? CGSize(width: 32, height: 32) : CGSize(width: 24, height: 24)))
            view.addSubview(imgView)
            imgView.snp.makeConstraints { (make) in
                make.size.equalTo(CGSize(width: Layout.isRegular() ? 32 : 20, height: Layout.isRegular() ? 32 : 20))
                make.left.equalToSuperview().offset(Layout.isRegular() ? 28 : 22)
                make.right.equalToSuperview()
                make.top.equalToSuperview().offset(Layout.isRegular() ? 43 : 30)
            }
            let label = UILabel()
            label.text = I18n.View_G_Back
            label.textColor = UIColor.ud.textCaption
            label.font = UIFont.systemFont(ofSize: Layout.isRegular() ? 14 : 10, weight: .medium)
            label.textAlignment = .center
            view.addSubview(label)
            label.snp.makeConstraints { maker in
                maker.centerX.equalTo(imgView)
                maker.top.equalTo(imgView.snp.bottom).offset(Layout.isRegular() ? 31 : 20)
                maker.height.equalTo(LabEffectBgCell.Layout.titleHeight())
            }
            return view
        }
    }

    private let viewModel: InMeetingLabViewModel
    private lazy var itemLayout = UICollectionViewFlowLayout.init()
    private lazy var bgCollectionView: UICollectionView = {
        UICollectionView.init(frame: .zero, collectionViewLayout: itemLayout)
    }()

    lazy var beautyBackView: UIView = {
        return Layout.createBeautyBackView()
    }()

    lazy var landscapeBeautyBackBtn: UIButton = {
        let button = UIButton()
        button.setImage(UDIcon.getIconByKey(.leftOutlined, iconColor: .ud.iconN2, size: CGSize(width: 12, height: 12)), for: .normal)
        button.setTitle(I18n.View_G_Back, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        button.setTitleColor(UIColor.ud.textCaption, for: .normal)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -2, bottom: 0, right: 2)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 3, bottom: 0, right: -3)
        button.addTarget(self, action: #selector(backAction), for: .touchUpInside)
        button.isHidden = true
        return button
    }()

    lazy var loadingView: LabLoadingView = {
        let view = LabLoadingView()
        view.status = .loading
        return view
    }()

    private var viewWidth: CGFloat = 0

    private let labType: EffectType

    private var effectModels: [ByteViewEffectModel] = []  // 滤镜和animoji是真实model、美颜可能是setting或者真实model

    weak var delegate: LabEfffectBgViewDelegate?

    private var isDownLoading: Bool = false

    var isLandscapeMode: Bool { return viewModel.fromSource == .inMeet && isPhoneLandscape } // preview进入特效不横屏

    init(frame: CGRect, vm: InMeetingLabViewModel, labType: EffectType) {
        self.viewModel = vm
        self.labType = labType
        super.init(frame: frame)

        self.reloadEffectData()
        setupViews()
        bindLoadingStatus()

        switch labType {
        case .animoji:
            checkPretendStatus(status: viewModel.pretendService.animojiLoadingStatus)
        case .filter:
            checkPretendStatus(status: viewModel.pretendService.filterLoadingStatus)
        case .retuschieren:
            checkPretendStatus(status: viewModel.pretendService.beautyLoadingStatus)
        case .virtualbg:
            break
        }
        viewModel.pretendService.addListener(self)
        if labType == .animoji {
            viewModel.pretendService.addCalendarListener(self, fireImmediately: true)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        Logger.lab.info("lab: LabEfffectBgView deinit")
    }

    func dataSetChanged() {
        self.reloadEffectData()
        bgCollectionView.reloadData()
    }

    func reloadEffectData() {
        switch labType {
        case .animoji:
            self.effectModels = viewModel.anmojiModels
            self.viewModel.anmojiBgDataDelegate = self
        case .filter:
            self.effectModels = viewModel.filterModels
            self.viewModel.filterBgDataDelegate = self
        case .retuschieren:
            self.effectModels = viewModel.retuschierenModels
            self.viewModel.retuschierenBgDataDelegate = self
        default:
            break
        }
    }

    func viewDidLayoutSubviews(width: CGFloat) {
        updateCollectionView(width: width)
    }

    private func setupCollectionView() {
        itemLayout.scrollDirection = .vertical
        resetItemLayout()

        bgCollectionView.delegate = self
        bgCollectionView.dataSource = self
        bgCollectionView.showsVerticalScrollIndicator = false
        bgCollectionView.backgroundColor = .clear
        bgCollectionView.bounces = true
        bgCollectionView.register(LabEffectBgCell.self, forCellWithReuseIdentifier: "labEffectBgCell")
        bgCollectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "Header")
        bgCollectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "Footer")
        addSubview(bgCollectionView)
    }

    private func setupViews() {
        setupCollectionView()
        addSubview(beautyBackView)
        addSubview(landscapeBeautyBackBtn)
        addSubview(loadingView)
        loadingView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
    }

    private func isBeautyBackLandscapeL() -> Bool {
        return isLandscapeMode && max(VCScene.bounds.height, VCScene.bounds.width) > 720 && labType == .retuschieren && !viewModel.isBeautySetting
    }

    private func isBeautyBackLandscapeS() -> Bool {
        return isLandscapeMode && max(VCScene.bounds.height, VCScene.bounds.width) <= 720 && labType == .retuschieren && !viewModel.isBeautySetting
    }

    func layoutForTraitCollection() {
        // c视图和r视图区别太大，重新生成collectionview beautyBackView
        beautyBackView.removeFromSuperview()
        beautyBackView = Layout.createBeautyBackView()
        addSubview(beautyBackView)
        let tap = UITapGestureRecognizer(target: self, action: #selector(backAction))
        beautyBackView.addGestureRecognizer(tap)

        bgCollectionView.removeFromSuperview()
        bgCollectionView = UICollectionView.init(frame: .zero, collectionViewLayout: itemLayout)
        bgCollectionView.isHidden = !(loadingView.status == .none)
        setupCollectionView()
        updateCollectionView(width: Layout.viewWidth(isLandscapeMode: isLandscapeMode))
        bgCollectionView.reloadData()
    }

    @objc private func backAction() {
        viewModel.isBeautySetting = true
        viewModel.unSelectedBeautyEffect()
        delegate?.hiddenEffectSlider()
        updateCollectionView(width: Layout.viewWidth(isLandscapeMode: isLandscapeMode))
        dataSetChanged()
    }

    private func resetItemLayout() {
        itemLayout.itemSize = CGSize(width: Layout.cellWidth(), height: Layout.cellHeight(isHasTitle: isHasTitle(), isHasDot: labType == .retuschieren))  // cell大小
        itemLayout.minimumLineSpacing = Layout.cellVerticalSpacing(labType: labType) // 滚动方向相同
        itemLayout.minimumInteritemSpacing = Layout.cellHorizonSpacing(labType: labType, isLandScapeMode: isLandscapeMode) // 滚动方向垂直
        itemLayout.headerReferenceSize = CGSize(width: Layout.viewWidth(isLandscapeMode: isLandscapeMode), height: Layout.collectionTopMargin())
        itemLayout.footerReferenceSize = CGSize(width: Layout.viewWidth(isLandscapeMode: isLandscapeMode), height: ((Layout.isRegular() ? 35 : 23) - LabVirtualBgCell.Layout.cellBorderTotalWidth()))
    }

    private func updateCollectionView(width: CGFloat) {
        viewWidth = width
        var space: CGFloat = 22.5  // iphone
        if isLandscapeMode {
            space = 16
        } else if Display.pad && Layout.isRegular() {    // ipad r视图
            space = 22
        } else if Display.pad && !Layout.isRegular() {    // ipad c视图
            space = 22.5
        }
        let itemCount: CGFloat = viewModel.isBeautySetting ? 3 : 4
        let collectionLeft = collectionLeftSpacing()
        var collectionRight: CGFloat = 0
        if isLandscapeMode {
            collectionRight = Layout.landscapeModeCellSpacing - LabEffectBgCell.Layout.cellBorderTotalWidth()
        } else if Layout.isRegular() {
            collectionRight = Layout.collectionRightMarin(labType: labType, isLandScapeMode: isLandscapeMode)
        } else {
            collectionRight = Layout.collectionRightMarin(labType: labType, isLandScapeMode: isLandscapeMode) + LabVirtualBgCell.Layout.cellBorderTotalWidth()
        }
        let collectionWidth = 2 * LabEffectBgCell.Layout.cellBorderTotalWidth() + (LabEffectBgCell.Layout.cellImageWidth() * itemCount) + space * (itemCount - 1)  // 美颜的时候用的


        if isBeautyBackLandscapeS() {
            bgCollectionView.snp.remakeConstraints { maker in
                maker.top.equalToSuperview().offset(42 - LabEffectBgCell.Layout.cellBorderTotalWidth())
                maker.bottom.equalToSuperview()
                maker.left.equalToSuperview().offset(16 - LabEffectBgCell.Layout.cellBorderTotalWidth())
                maker.width.equalTo(collectionWidth)
            }
        } else {
            bgCollectionView.snp.remakeConstraints { maker in
                maker.top.equalToSuperview()
                maker.bottom.equalToSuperview()
                maker.left.equalTo(beautyBackView.snp.right).offset(collectionLeft)
                if labType == .retuschieren {
                    maker.width.equalTo(collectionWidth)
                } else {
                    maker.right.equalToSuperview().offset(-collectionRight)
                }
            }
        }

        if !viewModel.isBeautySetting, labType == .retuschieren { //美颜设置
            if isBeautyBackLandscapeS() { // 横屏小于720，横屏大于720，竖屏
                landscapeBeautyBackBtn.snp.remakeConstraints { maker in
                    maker.size.equalTo(CGSize(width: 48, height: 22))
                    maker.top.equalToSuperview().offset(16)
                    maker.left.equalToSuperview().offset(12)
                }
                landscapeBeautyBackBtn.isHidden = false
                beautyBackView.isHidden = true
            } else {
                beautyBackView.snp.remakeConstraints { maker in
                    maker.height.equalTo(Layout.cellHeight(isHasTitle: true, isHasDot: false))
                    maker.top.equalTo(bgCollectionView)
                    maker.left.equalToSuperview().offset(isBeautyBackLandscapeL() ? -5 : 0)
                }
                landscapeBeautyBackBtn.isHidden = true
                beautyBackView.isHidden = false
            }
        } else { // 非自定义 隐藏的情况
            beautyBackView.snp.remakeConstraints { maker in
                maker.size.equalTo(CGSize(width: 0, height: Layout.cellHeight(isHasTitle: true, isHasDot: false)))
                maker.top.equalTo(bgCollectionView)
                maker.left.right.equalTo(self.snp.left)
            }
            landscapeBeautyBackBtn.isHidden = true
            beautyBackView.isHidden = true
        }
    }

    private func collectionLeftSpacing() -> CGFloat {
        var collectionLeft: CGFloat = 0
        if isLandscapeMode {
            collectionLeft = Layout.landscapeModeCellSpacing - LabEffectBgCell.Layout.cellBorderTotalWidth()
        } else if Layout.isRegular() {
            if !viewModel.isBeautySetting, labType == .retuschieren {
                collectionLeft = 22 - LabEffectBgCell.Layout.cellBorderTotalWidth()
            } else {
                collectionLeft = Layout.collectionRightMarin(labType: labType, isLandScapeMode: isLandscapeMode)
            }
        } else {
            let cellSpacing = (Layout.viewWidth(isLandscapeMode: isLandscapeMode) - LabEffectBgCell.Layout.cellImageWidth() * 5) / 6
            collectionLeft = cellSpacing - LabEffectBgCell.Layout.cellBorderTotalWidth()
        }
        return collectionLeft
    }

    private func isHasTitle() -> Bool {
        switch self.labType {
        case .animoji:
            return false
        default:
            return true
        }
    }

    private func bindLoadingStatus() {
        loadingView.reloadHandler = { [weak self] in
            guard let self = self else { return }
            switch self.labType {
            case .animoji:
                self.viewModel.reloadAnimoji()
            case .filter:
                self.viewModel.reloadFilter()
            case .retuschieren:
                self.viewModel.reloadRetuschieren()
            default:
                break
            }
        }
    }

    private func checkPretendStatus(status: EffectLoadingStatus) {
        if labType == .animoji, !viewModel.pretendService.isAllowAnimoji {
            self.loadingView.status = .notAllowAnimoji
            self.bgCollectionView.isHidden = true
        } else {
            switch status {
            case .loading, .unStart:
                self.loadingView.status = .loading
                self.bgCollectionView.isHidden = true
            case .failed:
                self.loadingView.status = .failed
                self.bgCollectionView.isHidden = true
            case .done:
                self.loadingView.status = .none
                self.bgCollectionView.isHidden = false
            }
        }
        Logger.effectPretend.info("effect loading status: \(status), type: \(self.labType)")
    }
}

extension LabEffectBgView: EffectPretendDataListener, EffectPretendCalendarListener {
    func didChangeAnimojAllow(isAllow: Bool) {
        Util.runInMainThread {
            self.checkPretendStatus(status: self.viewModel.pretendService.animojiLoadingStatus)
            Logger.effectPretend.info("allowAnimojiObservable allow status: \(isAllow), type: Animoji")
        }
    }

    func didChangePretendloadingStatus(type: EffectType, status: EffectLoadingStatus) {
        Util.runInMainThread {
            if type == self.labType {
                self.checkPretendStatus(status: status)
            }
        }
    }
}

/// 实现 UICollection 的协议
extension LabEffectBgView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return effectModels.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "labEffectBgCell",
                                                         for: indexPath) as? LabEffectBgCell {
            cell.bindData(model: effectModels[indexPath.row], account: viewModel.service.accountInfo)
            return cell
        }
        return UICollectionViewCell(frame: .zero)
    }
}

extension LabEffectBgView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard !isDownLoading else { // 下载时不能点击
            return
        }

        viewModel.selectEffect(index: indexPath.row)

        bgCollectionView.reloadData()
        bgCollectionView.layoutIfNeeded()

        if let cell = collectionView.cellForItem(at: indexPath) as? LabEffectBgCell,
           let model = cell.model {

            switch model.bgType {
            case .none:
                viewModel.cancelEffect(model: model)
                self.delegate?.didTapEffect(effectModel: model)
            case .auto:
                viewModel.autoEffect(model: model)
            case .customize:
                viewModel.isBeautySetting = false
                viewModel.unSelectedBeautyEffect()
                updateCollectionView(width: Layout.viewWidth(isLandscapeMode: isLandscapeMode))
                dataSetChanged()
                viewModel.customizeEffect(model: model)
            case .set:
                if model.effectModel.downloaded {
                    viewModel.applyEffect(model: model)
                    self.delegate?.didTapEffect(effectModel: model)  // labview的ui操作
                } else {
                    viewModel.downLoadEffect(model: model, willDownload: {
                        cell.playLoading()
                        self.isDownLoading = true
                    }, didDownload: { (error, path) in
                        self.isDownLoading = false
                        cell.stopLoading()
                        if error == nil,
                           let path = path,
                           !path.isEmpty {
                            self.viewModel.applyEffect(model: model)
                            self.delegate?.didTapEffect(effectModel: model)
                        } else {
                            Toast.show(I18n.View_VM_UnstableConnectionTryAgain)
                        }
                    })
                }
            }
        }
    }
}
