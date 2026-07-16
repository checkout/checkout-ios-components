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
    case merchantKeyPresetPicker = "merchant_key_preset_picker"
    case localePicker = "locale_picker"
    case paymentSessionLocalePicker = "payment_session_locale_picker"
    case countryPicker = "country_picker"
    case currencyPicker = "currency_picker"
    case customLocale = "custom_locale_option"
    case addressPicker = "address_picker"
    case applePayTypePicker = "applepay_type_picker"
    case applePayButtonStylePicker = "applepay_button_style_picker"
    case applePayButtonTypePicker = "applepay_button_type_picker"
    case displayCardholderNamePicker = "display_cardholder_name_picker"
    case sdkPicker = "sdk_picker"
    case paymentMethodPicker = "payment_method_picker"
    case cardPaymentMethodOption = "card_payment_method_option"
    case applePayPaymentMethodOption = "google_apple_pay_payment_method_option"
    case tabbyPaymentMethodOption = "tabby_payment_method_option"
    case tamaraPaymentMethodOption = "tamara_payment_method_option"
    case stcPayPaymentMethodOption = "stc_pay_payment_method_option"
    case klarnaPaymentMethodOption = "klarna_payment_method_option"
    case payButtonPicker = "pay_button_picker"
    case payment = "payment"
    case tokenize = "tokenize"
    case showPayButtonPicker = "show_pay_button_picker"
    case submitPaymentMethodView = "submit_payment_method_view"
    case hideSecurityCodeToggle = "hide_security_code_toggle"
    case acceptedCardSchemesPicker = "accepted_card_schemes_picker"
    case acceptedCardTypesPicker = "accepted_card_types_picker"
    case advancedFeaturesExpandable = "advanced_features"
    case cardholderNameMaxLengthInput = "cardholder_name_max_length_input"

    // Payment Session
    case paymentSessionConfigurationsExpandable = "ps_configurations_button"
    case paymentSessionUsernameTextField = "ps_username_textfield"
    case paymentSessionUserEmailTextField = "ps_user_email_textfield"
    case paymentSessionUserCountryCodeTextField = "ps_user_country_code_textfield"
    case paymentSessionUserPhoneNumberTextField = "ps_user_phone_number_textfield"

    // RemeberMe
    case rememberMeConfigurationsExpandable = "remember_me_configurations"
    case showRememberMeToggle = "show_remember_me_toggle"
    case showRememberMePayButtonToggle = "show_remember_me_pay_button_toggle"
    case ignoreRememberMeEmailFeatureFlagToggle = "ignore_remember_me_email_feature_flag_toggle"
    case captureCvvFeatureFlagToggle = "capture_cvv_feature_flag_toggle"

    // SDK RememberMe config
    case rememberMeSDKSetupExpandable = "remember_me_sdk_setup"
    case userEmailTextField = "user_email_text_field"
    case userCountryCodeTextField = "user_country_code_text_field"
    case userPhoneNumberTextField = "user_phone_number_text_field"

    // RememberMe Payment Session / Customer config
    case rememberMePaymentSessionSetupExpandable = "remember_me_payment_session_setup"
    case customerEmailInput = "customer_email_input"
    case customerPhoneCountryCodePicker = "customer_phone_country_code_picker"
    case customerPhoneNumberInput = "customer_phone_number_input"
  }
  
  enum PaymentResultView: String {
    case closeButton = "payment_result_close_button"
    case paymentIDLabel = "payment_id_label"
    case generatedTokenLabel = "generated_token_label"
  }
}
