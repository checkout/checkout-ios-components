//  Copyright © 2024 Checkout.com. All rights reserved.

#if canImport(CheckoutComponents)
import CheckoutComponents
#elseif canImport(CheckoutComponentsSDK)
import CheckoutComponentsSDK
#endif

import SwiftUI

struct MainView: View {
  @StateObject private var viewModel = MainViewModel()

  var body: some View {
    Group {
      if let componentsView = viewModel.checkoutComponentsView {
        componentsView

        if !viewModel.showPayButton {
          Button {
            viewModel.merchantTokenizationTapped()
          } label: {
            Text("Merchant Tokenization")
          }
        }
      } else {
        initialView()
      }
    }
    .padding()
    .sheet(isPresented: $viewModel.showPaymentResult) {
      PaymentResultView(
        isSuccess: viewModel.paymentSucceeded,
        paymentID: viewModel.paymentResultText
      )
    }
  }
}

// MARK: Create an initial view to trigger the component creation

extension MainView {

  @ViewBuilder
  func initialView() -> some View {
    VStack {
      Button(action: {
        Task {
          await viewModel.makeComponent()
        }
      }) {
        Text("Show Flow")
          .padding()
          .background(Color.blue)
          .foregroundColor(.white)
          .cornerRadius(4)
      }

      Toggle("Show default appearance", isOn: $viewModel.isDefaultAppearance)
        .padding([.top, .trailing])
    }
  }
}

#Preview {
  MainView()
}
