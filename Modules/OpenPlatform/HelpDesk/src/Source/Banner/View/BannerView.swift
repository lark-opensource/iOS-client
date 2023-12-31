//
//  BannerView.swift
//  LarkHelpdesk
//
//  Created by yinyuan on 2021/8/25.
//
import Foundation
import Kingfisher
import UniverseDesignColor
import ECOProbe
import LKCommonsLogging

protocol BannerViewProtocol: AnyObject {
    
    func didSelectItem(bannerView: BannerView, bannerResponse: BannerResponse, bannerResource: BannerResource)
    
    func refreshView()
}

class BannerView: UIView {
    
    private static let cellID = "BannerCell"
    private static let cellItemSpacing: CGFloat = 8
    private static let bannerHeight: CGFloat = 30
    
    private let initDate = Date()
        
    weak var delegate: BannerViewProtocol?
    
    var showBannerView: Bool = false
    
    func updateContainerData(bannerContainer: BannerContainer, bannerResponse: BannerResponse) {
        openBannerLogger.info("updateContainerData. bannerResponse:\(bannerResponse)")
        executeOnMainQueueAsync { [weak self] in
            guard let self = self else {
                openBannerLogger.info("BannerView released")
                return
            }
            
            // 数据转换
            let oldData = self.data
            var data: [BannerCellViewModel] = []
            
            let newData = bannerContainer.resourceList.compactMap({ (resource) -> BannerCellViewModel? in
                guard resource.resourceView.isValidView() else {
                    // 不合法的 resource，直接不渲染
                    openBannerLogger.info("invalid resource view. resource:\(resource)")
                    return nil
                }
                // 需要保留已有的 loading 状态 (如果有)
                let oldBannerCellModel = oldData.first { mode in
                    mode.bannerResource.resourceID == resource.resourceID
                }
                return BannerCellViewModel(
                    bannerResponse: bannerResponse,
                    bannerResource: resource,
                    loading: oldBannerCellModel?.loading ?? false)
            })
            data = newData
            
            self.data = data
            self.bannerCollectionView.reloadData()
            var resourcesType: String = ""
            var resourcesID: String = ""
            var resourceTypeArray: Array<String> = []
            var resourceIDArray: Array<String> = []
            for datum in data {
                resourceTypeArray.append(datum.bannerResource.resourceType)
                resourceIDArray.append(datum.bannerResource.resourceID)
            }
            resourcesType = resourceTypeArray.joined(separator: ",")
            resourcesID = resourceIDArray.joined(separator: ",")
            OPMonitor("lark_hpd_floating_window_view")
                .addCategoryValue("resource_type", resourcesType)
                .addCategoryValue("resource_id", resourcesID)
                .addCategoryValue("user_type", bannerResponse.contextDic?["user_type"])
                .addCategoryValue("helpdesk_id", bannerResponse.contextDic?["helpdesk_id"])
                .addCategoryValue("language", bannerResponse.contextDic?["language"])
                .addCategoryValue("version", bannerResponse.resourceVersion)
                .setPlatform(.tea)
                .timing()
                .flush()
            
            if newData.isEmpty {
                self.hide(animation: false)
            } else {
                self.show(animation: false)
            }
        }
    }
    
    func setItemLoading(resource: BannerResource, loading: Bool) {
        executeOnMainQueueAsync {  [weak self] in
            guard let self = self else {
                openBannerLogger.info("BannerView released")
                return
            }
            guard var model = self.data.first(where: { model in
                model.bannerResource.resourceID == resource.resourceID
            }) else {
                // 没有找到对应的数据
                return
            }
            model.loading = loading
            self.bannerCollectionView.reloadData()
        }
    }
    
    private func show(animation: Bool, completion: ((Bool) -> Void)? = nil) {
        if showBannerView {
            return
        }
        showBannerView = true
        
        delegate?.refreshView()
    }

    private func hide(animation: Bool, completion: ((Bool) -> Void)? = nil) {
        if !showBannerView {
            return
        }
        showBannerView = false
        
        delegate?.refreshView()
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        if self.superview != nil {
            openBannerLogger.info("contentView.superview is not nil")
                        
            let bannerHeight = BannerView.bannerHeight
            self.setNeedsUpdateConstraints()
            self.layoutIfNeeded()
            
            let noAnimationTime: TimeInterval = 5 // 进会话后5秒内不展示该动画
            if self.showBannerView, Date().timeIntervalSince(initDate) > noAnimationTime {
                self.layer.masksToBounds = true
                let animation0 = CABasicAnimation(keyPath: "position.y")
                animation0.fromValue = bannerCollectionView.layer.position.y + 15
                animation0.toValue = bannerCollectionView.layer.position.y
                
                let animation1 = CABasicAnimation(keyPath: "opacity")
                animation1.fromValue = 0
                animation1.toValue = 1
                
                let animation = CAAnimationGroup()
                animation.animations = [animation0, animation1]
                animation.duration = 0.3
                animation.fillMode = .removed
                animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                
                bannerCollectionView.layer.add(animation, forKey: nil)
            }
        } else {
            openBannerLogger.info("contentView.superview is nil")
        }
    }
    
    private var data: [BannerCellViewModel] = []

    /// 横向滑动列表
    private lazy var bannerCollectionView: UICollectionView = {
        
        let layout = UICollectionViewFlowLayout()
        
        // 横向滚动
        layout.scrollDirection = .horizontal
        
        // 设置 cell 之间间距
        layout.minimumInteritemSpacing = BannerView.cellItemSpacing
        
        // 设置section 左右间距
        layout.sectionInset = UIEdgeInsets(top: 0, left: BannerView.cellItemSpacing, bottom: 0, right: BannerView.cellItemSpacing)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
        // 注册 cell
        collectionView.register(BannerCell.self, forCellWithReuseIdentifier: BannerView.cellID)
        
        // 不显示滚动条
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.clipsToBounds = false
        
        // 必须指定透明，不然就变成黑色了
        collectionView.backgroundColor = .clear
        
        return collectionView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        openBannerLogger.info("BannerView.init")
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        openBannerLogger.info("BannerView.deinit")
    }

    private func setupViews() {
        addSubview(bannerCollectionView)
        
        bannerCollectionView.delegate = self
        bannerCollectionView.dataSource = self

        bannerCollectionView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
            make.height.equalTo(BannerView.bannerHeight)
        }
    }
}

extension BannerView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        openBannerLogger.info("collectionView.didSelectItemAt indexPath.row:\(indexPath.row), indexPath.count:\(indexPath.count)")
        guard indexPath.item < data.count else {
            return
        }
        let model = data[indexPath.item]
        if model.loading {
            // 正在 Loading 中，不允许点击选中
            openBannerLogger.info("loading item clicked")
            return
        }
        OPMonitor("lark_hpd_chat_floating_window_click")
            .addCategoryValue("click", "button")
            .addCategoryValue("resource_type", model.bannerResource.resourceType)
            .addCategoryValue("resource_id", model.bannerResource.resourceID)
            .addCategoryValue("user_type", model.bannerResponse.contextDic?["user_type"])
            .addCategoryValue("helpdesk_id", model.bannerResponse.contextDic?["helpdesk_id"])
            .addCategoryValue("language", model.bannerResponse.contextDic?["language"])
            .addCategoryValue("version", model.bannerResponse.resourceVersion)
            .addCategoryValue("target", "none")
            .setPlatform(.tea)
            .timing()
            .flush()
        if let delegate = delegate {
            delegate.didSelectItem(
                bannerView: self,
                bannerResponse: model.bannerResponse,
                bannerResource: model.bannerResource
            )
        } else {
            openBannerLogger.warn("delegate is nil")
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        guard indexPath.item < data.count else {
            return false
        }
        let model = data[indexPath.item]
        if model.loading {
            // 正在 Loading 中，不允许 Highlight
            return false
        }
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as? BannerCell
        cell?.setHighlight(highlight: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as? BannerCell
        cell?.setHighlight(highlight: false)
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard indexPath.item < data.count else {
            return false
        }
        let model = data[indexPath.item]
        if model.loading {
            // 正在 Loading 中，不允许点击选中
            return false
        }
        return true
    }
}

extension BannerView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let deFaultCell = collectionView.dequeueReusableCell(withReuseIdentifier: BannerView.cellID, for: indexPath)
        guard let cell = deFaultCell as? BannerCell,
              indexPath.item < data.count else {
            return deFaultCell
        }
        let model = data[indexPath.item]
        cell.setContent(with: model)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard indexPath.item < data.count else {
            return .zero
        }
        let model = data[indexPath.item]
        return BannerCell.cellSize(for: model)
    }
}

