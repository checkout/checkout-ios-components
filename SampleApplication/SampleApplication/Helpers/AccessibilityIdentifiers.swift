//  Copyright © 2025 Checkout.com. All rights reserved.

import Foundation

enum AccessibilityIdentifier {
  enum MainView: String {
    case renderFlowComponent = "render_flow_component_button"
    case settingsButton = "settings_button"
  }
  
  enum SettingsView: String {
    case appearancePicker = "appearance_picker"
    case defaultAppearanceOption = "default_appearance_option"
    case darkThemeOption = "dark_theme_option"
    case environmentPicker = "environment_picker"
    case sandboxEnvironmentOption = "sandbox_environment_option"
    case productionEnvironmentOption = "production_environment_option"
    case localePicker = "locale_picker"
    case customLocale = "custom_locale_option"
    case addressPicker = "address_picker"
    case sdkPicker = "sdk_picker"
    case paymentMethodPicker = "payment_method_picker"
    case cardPaymentMethodOption = "card_payment_method_option"
    case applePayPaymentMethodOption = "google_apple_pay_payment_method_option"
    case payButtonPicker = "pay_button_picker"
    case payment = "payment"
    case tokenize = "tokenize"
    case showPayButtonPicker = "show_pay_button_picker"
    case submitPaymentMethodView = "submit_payment_method_view"
  }
  
  enum PaymentResultView: String {
    case paymentIDLabel = "payment_id_label"
    case generatedTokenLabel = "generated_token_label"
  }
}
