//
//  ViewRequestStrategy.swift
//  ByteWebImage
//
//  Created by Nickyo on 2022/11/28.
//

import Foundation

private enum AssociativeKey {

    static let animation = "AssociativeKey.Animation"
}

private func canSetNewImageRequest(_ request: ImageRequest?) -> (Bool, ImageRequest?) {
    if let request, request.isFinished() {
        return (false, nil)
    }
    return (true, request)
}

extension ImageWrapper where Base: UIButton {

    func setInvalidURL(for state: UIControl.State, placeholder: UIImage?, callbacks: ImageRequestCallbacks) {
        cancelImageRequest(for: state)
        base.setImage(placeholder, for: state)

        let error = ImageError(.badImageURL, description: "Invalid empty URL")
        callbacks.completion?(.failure(error))
    }

    func setExistImageURL(for state: UIControl.State, request requestBlock: @autoclosure () -> ImageRequest, callbacks: ImageRequestCallbacks) {
        guard let completion = callbacks.completion else {
            return
        }
        let request = requestBlock()
        request.performanceRecorder.enableRecord = false

        let image = base.image(for: state)
        let result = ImageResult(request: request, image: image, data: nil, from: .none, savePath: nil)
        completion(.success(result))
    }

    func setNewImageRequest(_ request: ImageRequest?, for state: UIControl.State) {
        let (need, req) = canSetNewImageRequest(request)
        guard need else { return }
        if req != nil, imageSetter == nil {
            base.bt.imageSetter = ButtonImageSetter()
        }
        imageSetter?.setImageRequest(req, for: state)
    }

    func resetBeforeNewRequest(for state: UIControl.State, params: ImageRequestParams, placeholder: UIImage?) {
        if !params.setPlaceholderUntilFailure {
            base.setImage(placeholder, for: state)
        }
        base.layer.removeAnimation(forKey: AssociativeKey.animation)
    }

    /// 取消当前正在进行的图片请求，需要在主线程上调用
    public func cancelImageRequest(for state: UIControl.State) {
        guard let imageSetter, let request = imageSetter.imageRequest(for: state) else {
            return
        }
        request.cancel()
        imageSetter.setImageRequest(nil, for: state)
    }

    func addAnimation(_ type: ImageRequest.AnimationType) {
        guard type == .fade else { return }

        let transition = CATransition()
        // disable-lint: magic number
        transition.duration = 0.2
        // enable-lint: magic number
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        transition.type = .fade

        base.layer.add(transition, forKey: AssociativeKey.animation)
    }

    private func setResultImage(_ image: UIImage?, for state: UIControl.State, request: ImageRequest, loading: Bool) {
        image?.bt.webURL = request.currentRequestURL.absoluteURL
        image?.bt.loading = loading
        base.setImage(image, for: state)
    }

    func setUnfinishedImage(_ result: ImageResult, for state: UIControl.State) {
        setResultImage(result.image, for: state, request: result.request, loading: true)
    }

    func setFinishedImage(_ result: ImageResult, for state: UIControl.State) {
        guard let image = result.image, !result.request.params.disableAutoSetImage else {
            return
        }
        if result.from == .downloading {
            addAnimation(result.request.params.animation)
        }
        let realImage: UIImage?
        if let transformer = result.request.transformer {
            realImage = transformer.transformImageBeforeStore(with: image)
        } else {
            realImage = image
        }
        setResultImage(realImage, for: state, request: result.request, loading: false)
    }
}

extension ImageWrapper where Base: UIImageView {

    func setInvalidURL(placeholder: UIImage?, callbacks: ImageRequestCallbacks) {
        cancelImageRequest()
        base.image = placeholder

        let error = ImageError(.badImageURL, description: "Invalid empty URL")
        callbacks.completion?(.failure(error))
    }

    func setExistImageURL(request requestBlock: @autoclosure () -> ImageRequest, callbacks: ImageRequestCallbacks) {
        guard let completion = callbacks.completion else {
            return
        }
        let request = requestBlock()
        request.performanceRecorder.enableRecord = false

        let image = base.image
        let result = ImageResult(request: request, image: image, data: nil, from: .none, savePath: nil)
        completion(.success(result))
    }

    func setNewImageRequest(_ request: ImageRequest?) {
        let (need, req) = canSetNewImageRequest(request)
        guard need else { return }
        base.bt.imageRequest = req
    }

    func resetBeforeNewRequest(params: ImageRequestParams, placeholder: UIImage?) {
        if !params.setPlaceholderUntilFailure {
            base.image = placeholder
        }
        base.layer.removeAnimation(forKey: AssociativeKey.animation)
    }

    /// 取消当前正在进行的图片请求，需要在主线程上调用
    public func cancelImageRequest() {
        guard let request = imageRequest else {
            return
        }
        request.cancel()
        base.bt.imageRequest = nil
    }

    func addAnimation(_ type: ImageRequest.AnimationType) {
        guard type == .fade else { return }

        let transition = CATransition()
        // disable-lint: magic number
        transition.duration = 0.2
        // enable-lint: magic number
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        transition.type = .fade

        base.layer.add(transition, forKey: AssociativeKey.animation)
    }

    private func setResultImage(_ image: UIImage?, request: ImageRequest, loading: Bool) {
        image?.bt.webURL = request.currentRequestURL.absoluteURL
        image?.bt.loading = loading
        base.image = image
    }

    func setUnfinishedImage(_ result: ImageResult) {
        setResultImage(result.image, request: result.request, loading: true)
    }

    func setFinishedImage(_ result: ImageResult) {
        guard let image = result.image, !result.request.params.disableAutoSetImage else {
            return
        }
        if result.from == .downloading {
            addAnimation(result.request.params.animation)
        }
        let realImage: UIImage?
        if let transformer = result.request.transformer {
            realImage = transformer.transformImageBeforeStore(with: image)
        } else {
            realImage = image
        }
        setResultImage(realImage, request: result.request, loading: false)
    }
}

extension ImageRequestParams {

    func adjustDownsampleSizeIfNeeded(_ view: UIView) -> CGSize? {
        if !notDownsample || ImageManager.default.enableAllImageDownsample {
            if downsampleSize != .zero {
                return nil
            } else if view.bounds.size != .zero {
                return view.bounds.size
            } else {
                return UIScreen.main.bounds.size
            }
        } else {
            return .notDownsample
        }
    }
}
