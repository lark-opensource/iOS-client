//
//  StreamDefinitionView.swift
//  ByteView
//
//  Created by kiri on 2023/5/25.
//

import Foundation
import ByteViewRtcBridge

final class StreamDefinitionView: UIView, StreamRenderViewListener {
    let imageView = UIImageView()
    private var currentImageType: DefinitionImageType = .none
    private var imageCache: [DefinitionImageType: UIImage] = [:]

    fileprivate override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = false
        self.backgroundColor = .clear
        self.isHidden = true
        self.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        Display.pad ? CGSize(width: 40, height: 35) : CGSize(width: 27, height: 24)
    }

    fileprivate func bindToRenderView(_ renderView: StreamRenderView) {
        self.streamKey = renderView.streamKey
        self.isRendering = renderView.isRendering
        self.videoFrameSize = renderView.videoFrameSize
        self.updateImageType()
        renderView.addListener(self)
    }

    func streamRenderViewDidChangeRendering(_ renderView: StreamRenderView, isRendering: Bool) {
        self.isRendering = isRendering
        self.streamKey = renderView.streamKey
        self.updateImageType()
    }

    func streamRenderViewDidChangeVideoFrameSize(_ renderView: StreamRenderView, size: CGSize?) {
        if let size = size {
            self.videoFrameSize = size
            self.updateImageType()
        }
    }

    private var isRendering = false
    private var videoFrameSize: CGSize?
    private var streamKey: RtcStreamKey?
    private func updateImageType() {
        guard let frameSize = self.videoFrameSize, let streamKey = self.streamKey else { return }
        self.isHidden = streamKey.isLocal || !isRendering || frameSize.width < 1 || frameSize.height < 1
        guard !self.isHidden, self.superview != nil else { return }
        let pixelCount: CGFloat = frameSize.width * frameSize.height
        let isScreen = streamKey.isScreen
        // 根据不同的分辨率展示不同的标签, 分辨率判断根据像素点数量来判断，不管长短边具体多少, 如4k = 8294400
        // disable-lint: magic number
        let imageType: DefinitionImageType
        switch (pixelCount, isScreen) {
        case (8294400..., true):
            imageType = Display.pad ? .pad_4k : .mobile_4k
        case (3686400..., true):
            imageType = Display.pad ? .pad_2k : .mobile_2k
        case (2073600..., false):
            imageType = Display.pad ? .pad_1080 : .mobile_1080
        default:
            imageType = .none
        }
        // enable-lint: magic number
        guard self.currentImageType != imageType else { return }
        self.currentImageType = imageType
        if imageType == .none {
            self.imageView.image = nil
        } else if let image = self.imageCache[imageType] {
            self.imageView.image = image
        } else if let image = getResourceImage(imageType) {
            self.imageCache[imageType] = image
            self.imageView.image = image
        }
    }

    private func getResourceImage(_ type: DefinitionImageType) -> UIImage? {
        switch type {
        case .pad_1080:
            return BundleResources.ByteView.Definition.pic_1080p_pad
        case .pad_2k:
            return BundleResources.ByteView.Definition.pic_2k_pad
        case .pad_4k:
            return BundleResources.ByteView.Definition.pic_4k_pad
        case .mobile_1080:
            return BundleResources.ByteView.Definition.pic_1080p_mobile
        case .mobile_2k:
            return BundleResources.ByteView.Definition.pic_2K_mobile
        case .mobile_4k:
            return BundleResources.ByteView.Definition.pic_4K_mobile
        case .none:
            return nil
        }
    }

    private enum DefinitionImageType: String {
        case pad_1080
        case pad_2k
        case pad_4k
        case mobile_1080
        case mobile_2k
        case mobile_4k
        case none
    }
}

extension StreamRenderView {
    private var definitionView: StreamDefinitionView? {
        for case let v as StreamDefinitionView in self.subviews {
            return v
        }
        return nil
    }

    @discardableResult
    func addDefinitionViewIfNeeded() -> StreamDefinitionView {
        if let view = self.definitionView { return view }
        let definitionView = StreamDefinitionView()
        self.addSubview(definitionView)
        definitionView.snp.makeConstraints { make in
            let padding: CGFloat = Display.pad ? 8 : 6
            make.right.equalTo(videoContentLayoutGuide).inset(padding)
            make.bottom.equalTo(videoContentLayoutGuide).inset(padding)
        }
        definitionView.bindToRenderView(self)
        return definitionView
    }
}
