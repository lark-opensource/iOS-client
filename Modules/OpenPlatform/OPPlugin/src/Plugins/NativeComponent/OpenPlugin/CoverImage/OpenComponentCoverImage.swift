//
//  OpenComponentCoverImage.swift
//  OPPlugin
//
//  Created by lixiaorui on 2021/5/6.
//

import Foundation
import TTMicroApp
import OPPluginManagerAdapter
import OPFoundation

final class OpenComponentCoverImage: UIView, BDPComponentViewProtocol {

    public var componentID: Int

    private var model: OpenAPICoverImageParams {
        didSet {
            self.frame = model.frame
            isHidden = model.hidden
            loadImage()
        }
    }

    private let uniqueID: OPAppUniqueID

    private let trace: OPTrace

    private let imageTapAction: () -> Void

    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapImage)))
        view.isUserInteractionEnabled = true
        return view
    }()

    init(with uniqueID: OPAppUniqueID,
         model: OpenAPICoverImageParams,
         componentID: Int,
         trace: OPTrace,
         tapAction: @escaping () -> Void) {
        self.componentID = componentID
        self.model = model
        self.trace = trace
        self.uniqueID = uniqueID
        self.imageTapAction = tapAction
        super.init(frame: model.frame)

        addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func tapImage() {
        imageTapAction()
    }

    private func loadImage() {
        standardLoadImage()
    }

    private func standardLoadImage() {
        guard !model.src.isEmpty else {
            trace.error("can not load image with empty src")
            return
        }

        if model.src.hasPrefix("http") || model.src.hasPrefix("https"), let url = URL(string: model.src) {
            trace.info("load web image src")
            BDPNetworking.setImageView(imageView, url: url, placeholder: nil)
        } else {
            DispatchQueue.global().async { [weak self] in
                guard let `self` = self else { return }
                self.trace.info("start read file data")
                do {
                    let file = try FileObject(rawValue: self.model.src)
                    let fsContext = FileSystem.Context(uniqueId: self.uniqueID, trace: self.trace, tag: "updateConverImage", isAuxiliary: true)
                    let data = try FileSystem.readFile(file, context: fsContext)
                    DispatchQueue.main.async { [weak self] in
                        self?.trace.info("did read file data")
                        self?.imageView.image = UIImage(data: data)
                    }
                } catch let error as FileSystemError {
                    self.trace.error("read file failed", error: error)
                } catch {
                    self.trace.error("read file unknown failed", error: error)
                }
            }
        }
    }

    public func update(model: OpenAPICoverImageParams) {
        self.model = model
    }

}

fileprivate extension String {
    var isHttp: Bool {
        return hasPrefix("http://") || hasPrefix("https://")
    }
}
