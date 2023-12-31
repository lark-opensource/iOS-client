//
//  VCPersonasSytleViewController.swift
//  ByteView
//
//  Created by wpr on 2023/12/17.
//

import Foundation
import SnapKit
import UIKit
import UniverseDesignColor
import UniverseDesignIcon
import ByteViewUI
import ByteViewCommon
import UniverseDesignToast

class VCPersonasSytleViewController: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    private lazy var titleLable: UILabel = {
        let label = UILabel()
        label.text = "第二步 选择风格"
        label.font = .systemFont(ofSize: 22, weight: .medium)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private lazy var styleLable: UILabel = {
        let label = UILabel()
        label.text = "风格选择:"
        label.font = .systemFont(ofSize: 15)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private lazy var selectLable: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = .systemFont(ofSize: 15)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private let sdImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()

    private lazy var confirmButton: UIButton = {
        let button = UIButton()
        button.setTitle("提交", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17)
        button.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        button.backgroundColor = .ud.primaryContentDefault
        button.layer.cornerRadius = 6
        button.addTarget(self, action: #selector(confirmAction), for: .touchUpInside)
        return button
    }()

    lazy var collectionView: UICollectionView = {
        UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    }()

    var selectStyle: SDCheckpoint?

    let styleData: [SDCheckpoint] = {
        var items = [
            SDCheckpoint(name: "dreamshaper_8"),
            SDCheckpoint(name: "kakarot28DCozy_cozy"),
            SDCheckpoint(name: "majicmixFantasy_v30"),
            SDCheckpoint(name: "majicmixRealistic_v7"),
            SDCheckpoint(name: "sd_xl_base_1.0_0.9vae")]
        return items
    }()

    let base64String: String?
    let isMale: Bool

    var isText2Img: Bool {
        return base64String.isEmpty
    }

    init(base64String: String?, isMale: Bool) {
        self.base64String = base64String
        self.isMale = isMale
        Logger.ui.info("sdai base64 \(base64String.isEmpty), isMale: \(isMale)")

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        layoutViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    func setupViews() {
        self.title = "数字人生成"
        view.backgroundColor = .ud.bgBody

        collectionView.register(VCPersonasCheckpointCell.self, forCellWithReuseIdentifier: "Cell")
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .ud.N200
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
        }

        view.addSubview(titleLable)
        view.addSubview(styleLable)
        view.addSubview(selectLable)
        view.addSubview(collectionView)
        view.addSubview(sdImageView)
        view.addSubview(confirmButton)
    }

    func layoutViews() {
        titleLable.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(20)
            make.top.equalToSuperview().offset(15)
        }

        styleLable.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalTo(titleLable.snp.bottom).offset(20)
            make.height.equalTo(20)
        }

        selectLable.snp.makeConstraints { make in
            make.centerY.equalTo(styleLable)
            make.left.equalTo(styleLable.snp.right).offset(10)
            make.right.equalToSuperview()
            make.height.equalTo(20)
        }

        collectionView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(20)
            make.top.equalTo(styleLable.snp.bottom).offset(20)
            make.height.greaterThanOrEqualTo(225)
        }

        sdImageView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(50)
            make.top.equalTo(collectionView.snp.bottom).offset(20)
            make.height.equalTo(sdImageView.snp.width)
        }

        confirmButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-10)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(50)
        }
    }

    deinit {
        Logger.ui.info("sdai VCPersonasSytleViewController deinit")
    }

    @objc private func confirmAction() {
        if let checkpoint = selectStyle {
            requestImageSystem(checkpoint: checkpoint)
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return styleData.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell",
                                                         for: indexPath) as? VCPersonasCheckpointCell {
            let model = self.styleData[indexPath.row]
            cell.setCheckpoint(name: model.name)
            return cell
        }
        return UICollectionViewCell(frame: .zero)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 150, height: 225)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)

        selectStyle = self.styleData[indexPath.row]
        selectLable.text = "已选择" + selectStyle!.name + "风格"
    }
}

extension VCPersonasSytleViewController {
    func requestImageSystem(checkpoint: SDCheckpoint) {

        var urlString = ""
        if isText2Img {
            urlString = "http://10.87.29.237:7860/sdapi/v1/txt2img"
        } else {
            urlString = "http://10.87.29.237:7860/sdapi/v1/img2img"
        }

        let checkpointInfo = ["sd_model_checkpoint": checkpoint.name]
        let prompt = "1 " + (isMale ? "boy" : "girl")

        var params: [String: Any] = [:]
        if isText2Img {
            params = ["prompt": prompt,
                      "steps": "15",
                      "override_settings": checkpointInfo,
                      "width": "512",
                      "height": "512"]
        } else {
            params = ["prompt": prompt,
                      "override_settings": checkpointInfo,
                      "denoising_strength": "0.5",
                      "init_images": [base64String],
                      "width": "512",
                      "height": "512"]
        }

        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            Logger.ui.info("sdai request \(checkpoint.name), url: \(urlString)")
            request.httpBody = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
        } catch let error {
            Logger.ui.info("sdai request error: \(error.localizedDescription)")
        }

        let toast = UDToast.showTips(with: "图片生成中，请耐心等待", on: self.view, delay: 1000)
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            toast.remove()
            guard let self = self else { return }
            if let error = error {
                UDToast.showTips(with: error.localizedDescription, on: self.view, delay: 3.0)
                Logger.ui.info("sdai task error: \(error)")
            } else if let data = data {
                Logger.ui.info("sdai success size: \(data)")
                let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
                if let responseJSON = responseJSON as? [String: Any] {
                    if let imageArray = responseJSON["images"] as? [String], imageArray.count > 0, let string = imageArray[0] as? String {
                        Logger.ui.info("sdai success info: \(responseJSON["info"])")
                        self.addImage(base64String: string)
                    }
                }
            }
        }
        task.resume()
    }

    func addImage(base64String: String) {
        guard let data = Data(base64Encoded: base64String, options: .ignoreUnknownCharacters), let image = UIImage(data: data) else {
            Logger.ui.info("sdai base64 error")
            return
        }
        DispatchQueue.main.async {
            self.sdImageView.image = image
        }
    }
}
