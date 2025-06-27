//  Copyright © 2024 Checkout.com. All rights reserved.

#if canImport(CheckoutComponents)
import CheckoutComponents
#elseif canImport(CheckoutComponentsSDK)
import CheckoutComponentsSDK
#endif

import SwiftUI

enum MainViewState {
  case initial
  case component
  case settings
}

struct MainView: View {
  @StateObject var viewModel = MainViewModel()
  @State private var viewState: MainViewState = .initial

  var body: some View {
    Group {
      initialView()
      
      switch viewState {
      case .initial:
        EmptyView()
      case .component:
        makeComponentView()
      case .settings:
        settingView
      }
    }
    .padding()
    .sheet(isPresented: $viewModel.showPaymentResult) {
      PaymentResultView(
        isSuccess: viewModel.paymentSucceeded,
        paymentID: viewModel.paymentResultText,
        token: viewModel.generatedToken
      )
    }
  }
}

// MARK: Create an initial view to trigger the component creation

extension MainView {
  @ViewBuilder
  func makeComponentView() -> some View {
    if let componentsView = viewModel.checkoutComponentsView {
      componentsView

      if !viewModel.showPayButton {
        Button {
          viewModel.merchantTokenizationTapped()
        } label: {
          Text("Merchant Tokenization")
        }
      }
    }
  }

  @ViewBuilder
  func initialView() -> some View {
    HStack(spacing: 15) {
      Button(action: {
        Task {
          if viewState == .component { viewModel.resetToDefaultConfiguration() }
          await viewModel.makeComponent()
          viewState = .component
        }
      }) {
        Text("Show Flow")
          .accessibilityIdentifier(AccessibilityIdentifier.MainView.renderFlowComponent.rawValue)
          .padding()
          .background(Color.blue)
          .foregroundColor(.white)
          .cornerRadius(4)
      }
      
      Button {
        viewState = .settings
      } label: {
        Image(systemName: "gearshape.fill")
          .accessibilityIdentifier(AccessibilityIdentifier.MainView.settingsButton.rawValue)
          .font(.system(size: 24))
          .foregroundStyle(.black)
      }
    }
  }
}

#Preview {
  MainView()
}
