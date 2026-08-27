//  Copyright © 2024 Checkout.com. All rights reserved.

#if canImport(CheckoutComponents)
import CheckoutComponents
#elseif canImport(CheckoutComponentsSDK)
import CheckoutComponentsSDK
#endif

import SwiftUI

enum MainViewState: Hashable {
  case initial
  case component
  case settings
  case error(String)
}

struct MainView: View {
  @StateObject var viewModel = MainViewModel()
  @State private var viewState: MainViewState = .initial
  
  private var shouldShowUpdateAmountView: Bool {
    viewModel.selectedComponentType != .card &&
    viewModel.isShowUpdateView &&
    viewState == .component &&
    viewModel.handleSubmitManually
  }

  var body: some View {
    Group {
      if shouldShowUpdateAmountView {
        updateAmountView()
      }
      
      initialView()
      
      switch viewState {
      case .initial:
        EmptyView()

      case .component:
        makeComponentView()
      case .settings:
        settingView
      case .error(let errorMessage):
        Text("An error occurred: \(errorMessage)")
          .foregroundColor(.red)
      }
    }
    .padding()
    .onChange(of: viewState) { newState in
      if newState != .component {
        viewModel.cvvTokenizationResult = nil
      }
    }
    .sheet(isPresented: $viewModel.showPaymentResult) {
      PaymentResultView(
        isSuccess: viewModel.paymentSucceeded,
        paymentID: viewModel.paymentResultText,
        token: viewModel.generatedToken
      )
    }
    .task {
      // Hydrate from environment variables and the bundled baseline at launch.
      await hydrateLaunchConfig(deepLinkURL: nil)
    }
    .onOpenURL { url in
      // Deep Link Token has the highest precedence; re-resolve including it.
      Task { await hydrateLaunchConfig(deepLinkURL: url) }
    }
  }
}

// MARK: Declarative launch configuration
extension MainView {
  /// Resolves the launch configuration across all delivery channels, applies
  /// it to the view model, and — when `"render": "auto"` is present — renders
  /// the flow immediately, bypassing the tap-to-render state (AC 1).
  @MainActor
  func hydrateLaunchConfig(deepLinkURL: URL?) async {
    let config = LaunchConfigHydrator.resolve(
      deepLinkURL: deepLinkURL,
      environment: ProcessInfo.processInfo.environment
    )

    let shouldAutoRender = viewModel.applyLaunchConfig(config)

    // Only auto-render once, and never override a flow that is already shown.
    guard shouldAutoRender, viewState != .component else { return }

    do {
      try await viewModel.makeComponent()
      viewState = .component
    } catch {
      viewState = .error("\(error)")
    }
  }
}

// MARK: Create an initial view to trigger the component creation
extension MainView {
  @ViewBuilder
  func makeComponentView() -> some View {
    ScrollView {
      if let componentsView = viewModel.checkoutComponentsView {
        componentsView

        if viewModel.selectedComponentType == .cvv {
          // The CVV component tokenizes through the async `tokenize()` that returns the
          // CVV token result, so it gets its own button instead of the generic ones below.
          Button("CVV Tokenization") {
            viewModel.cvvTokenizationTapped()
          }
          .padding()

          cvvTokenizationResultView()
        } else {
          customButtonView()
        }
      }
    }
  }

  @ViewBuilder
  func cvvTokenizationResultView() -> some View {
    switch viewModel.cvvTokenizationResult {
    case .token(let token):
      Text("CVV token: \(token)")
        .accessibilityIdentifier(AccessibilityIdentifier.MainView.cvvTokenLabel.rawValue)
        .font(.subheadline)
        .foregroundColor(.green)
        .multilineTextAlignment(.center)
        .textSelection(.enabled)

    case .failure(let message):
      Text("CVV tokenization failed: \(message)")
        .accessibilityIdentifier(AccessibilityIdentifier.MainView.cvvTokenizationErrorLabel.rawValue)
        .font(.subheadline)
        .foregroundColor(.red)
        .multilineTextAlignment(.center)

    case .none:
      EmptyView()
    }
  }

  @ViewBuilder
  func customButtonView() -> some View {
    switch viewModel.customButtonOperation {

    case .tokenization:
      Button("Merchant Tokenization") {
        viewModel.merchantTokenizationTapped()
      }
      .padding()

    case .submitPayment:
      switch (viewModel.showCardPayButton, viewModel.showApplePayButton,
              viewModel.showAPMPayButton, viewModel.showStoredCardPayButton) {
      case (true, true, true, true):
        EmptyView()

      default:
        // Staged methods (e.g. STC Pay) report `isPayButtonRequired == false`
        // on their first stage, so keep the custom pay button hidden until
        // the SDK signals it is required.
        if viewModel.isPayButtonRequired {
          Button("Submit") {
            viewModel.submit()
          }
          .accessibilityIdentifier(AccessibilityIdentifier.MainView.merchantSubmitButton.rawValue)
          .padding()
        }
      }
    }
  }

  @ViewBuilder
  func updateAmountView() -> some View {
    VStack(alignment: .leading) {
      Divider()
      Text("Update Apple Pay amount - UI only")
      HStack {
        TextField("Amount", text: $viewModel.updatedAmount)
          .keyboardType(.numberPad)
        
        Button("Apply") {
          viewModel.updatePaymentAmount()
        }
      }
      Divider()
    }
  }

  @ViewBuilder
  func initialView() -> some View {
    HStack(spacing: 15) {
      Button(action: {
        Task {
          if viewState == .component { viewModel.resetToDefaultConfiguration() }
          do {
            try await viewModel.makeComponent()
            viewState = .component
          } catch {
            viewState = .error("\(error)")
          }
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

      Button {
        viewModel.showCallbackLog = true
      } label: {
        Image(systemName: "info.circle")
          .font(.system(size: 24))
          .foregroundStyle(.black)
      }
      .accessibilityIdentifier(AccessibilityIdentifier.MainView.callbackLogButton.rawValue)
      .accessibilityLabel("Callback Info")
      .sheet(isPresented: $viewModel.showCallbackLog) {
        CallbackLogView(store: viewModel.callbackInfoStore)
      }
    }
  }
}

#Preview {
  MainView()
}
