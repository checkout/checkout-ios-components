//  Copyright © 2024 Checkout.com. All rights reserved.

#if canImport(CheckoutComponents)
import CheckoutComponents
#elseif canImport(CheckoutComponentsSDK)
import CheckoutComponentsSDK
#endif

import SwiftUI

struct DarkTheme {

  let designToken: CheckoutComponents.DesignTokens

  init() {
    // Balanced, high-contrast dark palette
    let colorTokens: CheckoutComponents.ColorTokens = .init(
      action: .brightBlue,                         // CTA background
      background: Color(hex: "#0D1117"),           // App background
      border: Color(hex: "#30363D"),               // Neutral border
      disabled: Color(hex: "#6E7681"),             // Placeholder/disabled
      error: .deepRed,                              // Error states
      formBackground: Color(hex: "#161B22"),       // Cards/inputs surface
      formBorder: Color(hex: "#30363D"),           // Input borders
      inverse: .white,                              // Text on action
      outline: .lightBlue,                          // Focus/outline
      primary: Color(hex: "#C9D1D9"),              // Primary text
      secondary: Color(hex: "#8B949E"),            // Secondary text
      success: .checkoutGreen                       // Success states
    )

    // Use SDK’s default font styles to respect Dynamic Type and avoid overflow
    let fonts = CheckoutComponents.Font.Style(
      button: .button,
      footnote: .footnote,
      input: .input,
      label: .label,
      subheading: .subheading
    )

    // Consistent, all-corner radii (no asymmetric corners)
    self.designToken = .init(
      colorTokensMain: colorTokens,
      fonts: fonts,
      borderButtonRadius: .init(radius: 12),
      borderFormRadius: .init(radius: 12)
    )
  }
}
