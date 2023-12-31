//
//  BTSelectedUserCollectionView.swift
//  SKBrowser
//
//  Created by Gill on 2020/3/27.
//

import SnapKit
import SKUIKit
import RxCocoa
import RxSwift
import RxRelay
import SKResource
import SKFoundation
import UIKit
import UniverseDesignIcon
import UniverseDesignColor
import SKCommon
import ByteWebImage

public final class BTSelectedChatterCollectionView: UICollectionView {
    public weak var btDelegate: BTSelectedChatterCollectionViewDelegate?
    private(set) var hostFileName: String?
    public private(set) var didClose: PublishRelay<Int> = PublishRelay<Int>()
    private(set) var myInfos: [BTCapsuleModel] = []
    private let disposeBag = DisposeBag()
    public init(_ hostFileName: String?) {
        self.hostFileName = hostFileName
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 6
        layout.sectionInset = UIEdgeInsets(top: 10, left: 16, bottom: 0, right: 16)
        layout.scrollDirection = .horizontal
        layout.estimatedItemSize = CGSize(width: 100, height: 28)
        super.init(frame: .zero, collectionViewLayout: layout)
        register(BTAvatarClosableCell.self,
                 forCellWithReuseIdentifier: BTAvatarClosableCell.reuseIdentifier)
        dataSource = self
        delegate = self
        backgroundColor = UDColor.bgBody
        showsHorizontalScrollIndicator = false
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapCell(gesture:)))
        addGestureRecognizer(tapGesture)
    }
    
    public var clickCallback: () -> () = {}

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func didTapCell(gesture: UITapGestureRecognizer) {
        guard let indexPath = indexPathForItem(at: gesture.location(in: self)),
              let tappedCell = cellForItem(at: indexPath) as? BTAvatarClosableCell else { return }

        if tappedCell.closeBtn.frame.contains(gesture.location(in: tappedCell.capsule)) {
            didClose.accept(indexPath.row)
        } else {
            clickCallback()
            btDelegate?.didClickItem(with: myInfos[indexPath.row], fileName: hostFileName)
        }
    }
    
    /// shouldReload 在chatter类型的场景会刷新数据，更新带有token的Model，但是ui上是不需要更新的
    /// 这时候 shouldReload 传false
    public func updateData(_ infos: [BTCapsuleModel], shouldReload: Bool = true) {
        var shouldScrollToLast = false
        if infos.count > self.myInfos.count {
            // 有新增的，滚动到最后一个
            shouldScrollToLast = true
        }
        self.myInfos = infos
        if shouldReload {
            reloadData()
        }
        guard self.myInfos.count > 1 else {
            return
        }
        if shouldScrollToLast {
            let lastIndex = IndexPath(row: myInfos.count - 1, section: 0)
            scrollToItem(at: lastIndex, at: .centeredHorizontally, animated: false)
        }
    }
    
    public func getModels() -> [BTCapsuleModel] {
        return self.myInfos
    }
}

extension BTSelectedChatterCollectionView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return myInfos.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: BTAvatarClosableCell.reuseIdentifier,
            for: indexPath
        )
        guard myInfos.count > indexPath.row else { return cell }
        if let cell = cell as? BTAvatarClosableCell {
            cell.setupCell(myInfos[indexPath.row], cellEdgeInsets: .zero)
        }
        return cell
    }
}

public protocol BTSelectedChatterCollectionViewDelegate: AnyObject {
    // 后续统一通过这个跳转
    func didClickItem(with model: BTCapsuleModel, fileName: String?)
}

public extension BTSelectedChatterCollectionViewDelegate {
    // 后续统一通过这个跳转
    func didClickItem(with model: BTCapsuleModel, fileName: String?) {
        
    }
}


public final class BTAvatarClosableCell: UICollectionViewCell {

    private(set) var info: BTCapsuleModel?

    let capsule: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.fillTag
        return view
    }()

    let avatarView: UIImageView = {
        let avatarView = SKAvatar(configuration: .init(style: .circle, contentMode: .scaleAspectFit))
        return avatarView
    }()

    let avatarInset: CGFloat = 4

    let label: UILabel = {
        let label = UILabel()
        label.textColor = UDColor.textTitle
        label.textAlignment = .center
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    let closeBtn: UIButton = {
        let btn = UIButton()
        btn.setImage(UDIcon.closeOutlined.ud.withTintColor(UDColor.iconN3),
                     for: [.normal, .selected])
        btn.isUserInteractionEnabled = false
        btn.backgroundColor = .clear
        return btn
    }()

    public override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                capsule.backgroundColor = UDColor.udtokenTagNeutralBgNormalPressed
                closeBtn.setImage(UDIcon.closeOutlined.ud.withTintColor(UDColor.iconN1),
                             for: [.normal, .selected])
            } else {
                capsule.backgroundColor = UDColor.fillTag
                closeBtn.setImage(UDIcon.closeOutlined.ud.withTintColor(UDColor.iconN3),
                             for: [.normal, .selected])
            }
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(capsule)
        capsule.addSubview(label)
        capsule.addSubview(avatarView)
        capsule.addSubview(closeBtn)


        capsule.layer.cornerRadius = 14
        capsule.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(28)
        }

        let avatarLength: CGFloat = 20
        avatarView.layer.cornerRadius = avatarLength / 2
        avatarView.clipsToBounds = true
        avatarView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(avatarInset)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(avatarLength)
        }

        label.backgroundColor = .clear
        label.textColor = UDColor.textTitle
        label.font = .systemFont(ofSize: 14)
        label.snp.makeConstraints { make in
            make.left.equalTo(avatarView.snp.right).offset(4)
            make.centerY.equalToSuperview()
        }

        closeBtn.snp.makeConstraints { make in
            make.left.equalTo(label.snp.right).offset(4)
            make.right.equalToSuperview().offset(-8)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setupCell(_ selectModel: BTCapsuleModel, cellEdgeInsets insets: UIEdgeInsets) {
        self.info = selectModel
        if UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel, let key = selectModel.avatarKey, !key.isEmpty {
            avatarView
                .bt
                .setLarkImage(
                    .avatar(
                        key: key,
                        entityID: ""
                    ),
                    placeholder: BundleResources.SKResource.Common.Collaborator.avatar_placeholder
                ) { result in
                    switch result {
                    case .success:
                        DocsLogger.info("success request avatar by setLarkImage with key: \(key)")
                    case .failure(let error):
                        DocsLogger.error("fail request avatar by setLarkImage with key: \(key) code: \(error.code) userinfo: \(error.userInfo) localizedDescription: \(error.localizedDescription)", error: error)
                    }
                }
        } else {
        avatarView.kf.setImage(with: URL(string: selectModel.avatarUrl),
                               placeholder: BundleResources.SKResource.Common.Collaborator.avatar_placeholder)
        }
        switch DocsSDK.currentLanguage {
        case .en_US :
             // 没有英文名用显示文本进行兜底
            label.text = selectModel.enName.isEmpty ? selectModel.text : selectModel.enName
        default:
            label.text = selectModel.text
        }
    }
}
