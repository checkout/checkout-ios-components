//  Copyright © 2024 Checkout.com. All rights reserved.

import SwiftUI

@MainActor
struct PaymentResultView: View {
  let isSuccess: Bool
  let paymentID: String
  let token: String

  @Environment(\.presentationMode) var presentationMode

  @State private var animateMessage = false

  private var symbolName: String {
    isSuccess ? "checkmark.seal.fill" : "x.circle.fill"
  }

  private var messageText: String {
    isSuccess ? "Payment Successful!" : "Payment Failed"
  }

  var body: some View {
    ZStack {
      Color(.systemBackground)
        .edgesIgnoringSafeArea(.all)

      VStack(spacing: 40) {
        paymentSymbolView
        messageView
        closeButton
      }
      .padding()
    }
    .onAppear {
      animateMessage = true
    }
  }

  // Payment symbol view
  private var paymentSymbolView: some View {
    Image(systemName: symbolName)
      .foregroundColor(.blue)
      .font(.system(size: 100, weight: .black))
      .opacity(animateMessage ? 1 : 0)
      .animation(.easeIn(duration: 0.5), value: animateMessage)
  }

  // Message view
  private var messageView: some View {
    VStack(spacing: 10) {
      Text(messageText)
        .font(.largeTitle)
        .fontWeight(.bold)
        .foregroundColor(.blue)
        .opacity(animateMessage ? 1 : 0)
        .animation(.easeIn(duration: 0.5).delay(0.5), value: animateMessage)

      Text("Payment ID: \(paymentID)")
        .accessibilityIdentifier(AccessibilityIdentifier.PaymentResultView.paymentIDLabel.rawValue)
        .font(.subheadline)
        .foregroundColor(.gray)
        .opacity(animateMessage ? 1 : 0)
        .animation(.easeIn(duration: 0.5).delay(1.0), value: animateMessage)
      
      Text("Generated token: \(token)")
        .accessibilityIdentifier(AccessibilityIdentifier.PaymentResultView.generatedTokenLabel.rawValue)
        .font(.subheadline)
        .foregroundColor(.gray)
        .opacity(animateMessage ? 1 : 0)
        .animation(.easeIn(duration: 0.5).delay(1.0), value: animateMessage)
    }
  }

  // Close button
  private var closeButton: some View {
    Button(action: {
      presentationMode.wrappedValue.dismiss()
    }) {
      Text("Close")
        .padding()
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(4)
        .opacity(animateMessage ? 1 : 0)
        .animation(.easeIn(duration: 0.5).delay(1.5), value: animateMessage)
    }
  }
}

// Preview
struct PaymentResultView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      PaymentResultView(isSuccess: true, paymentID: "ABC123XYZ", token: "Token")
      PaymentResultView(isSuccess: false, paymentID: "Error: Payment Declined", token: "Token")
    }
  }
}
