//
//  ToastContainer.swift
//  ByteViewDebug
//
//  Created by liujianlong on 2023/7/14.
//

import SwiftUI

@available(iOS 14.0, *)
class ToastState: ObservableObject {
    @Published
    fileprivate var content: String?

    private var dismissAction: DispatchWorkItem?

    func showToast(_ content: String, duration: DispatchTimeInterval = .milliseconds(500)) {
        self.content = content
        self.dismissAction?.cancel()
        let item = DispatchWorkItem(block: { [weak self] in
            self?.content = nil
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: item)
        self.dismissAction = item
    }
}

@available(iOS 14.0, *)
struct ToastContainer<Content: View>: View {
    var content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    @StateObject
    var toastState = ToastState()


    var body: some View {
        ZStack {
            content
            if let toast = toastState.content {
                VStack {
                    Spacer()
                    Text(toast)
                        .font(.footnote)
                        .padding(10)
                        .frame(minWidth: 100, minHeight: 40)
                        .background(Color.black.opacity(0.5))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .offset(y: -20.0)
                }
            }
        }
        .environmentObject(toastState)
    }
}
