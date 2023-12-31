//
//  ButtonImageSetter.swift
//  ByteWebImage
//
//  Created by Nickyo on 2022/11/8.
//

import UIKit

class ButtonImageSetter {

    private var requestMap: [String: ImageRequest] = [:]

    private var lock = pthread_mutex_t()

    init() {
        pthread_mutex_init(&lock, nil)
    }

    deinit {
        pthread_mutex_unlock(&lock)
    }

    func imageRequest(for state: UIControl.State) -> ImageRequest? {
        var request: ImageRequest?

        pthread_mutex_trylock(&lock)
        request = requestMap[key(for: state)]
        pthread_mutex_unlock(&lock)

        return request
    }

    func setImageRequest(_ request: ImageRequest?, for state: UIControl.State) {
        pthread_mutex_trylock(&lock)
        requestMap[key(for: state)] = request
        pthread_mutex_unlock(&lock)
    }

    func backgroundImageRequest(for state: UIControl.State) -> ImageRequest? {
        var request: ImageRequest?

        pthread_mutex_trylock(&lock)
        request = requestMap[backgroundKey(for: state)]
        pthread_mutex_unlock(&lock)

        return request
    }

    func setBackgroundImageRequest(_ request: ImageRequest?, for state: UIControl.State) {
        pthread_mutex_trylock(&lock)
        requestMap[backgroundKey(for: state)] = request
        pthread_mutex_unlock(&lock)
    }

    // `F` means `foreground`
    private func key(for state: UIControl.State) -> String {
        "F\(state.rawValue)"
    }

    // `B` means `background`
    private func backgroundKey(for state: UIControl.State) -> String {
        "B\(state.rawValue)"
    }
}
