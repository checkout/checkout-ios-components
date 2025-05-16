# Change Log

All notable changes to this project will be documented in this file.
`checkout-ios-components` adheres to [Semantic Versioning](http://semver.org/).

#### 1.x Releases

## [1.0.0-beta-7](https://github.com/checkout/checkout-ios-components/releases/tag/1.0.0-beta-7)

Released on 15.05.2025

Updates:

- **User interaction Callback**  
  – Added an `onChange` callback to give merchants control over the payment button. This allows them to customize the button's appearance and toggle its enabled state based on validation results by calling `isValid`. For example, merchants can require users to accept terms before enabling the button, depending on interactions with card fields or switching between payment methods. Once all conditions are satisfied, merchants can trigger the payment flow by calling `submit()`.
- ** Public API changes** 
  - The `Actionable` changed to a type alias that groups multiple protocols. A component conforming to `Actionable` can be described, rendered, tokenized, and submitted.
  - The `Describable` represents the component’s name. 
  - The `Callbacks` now return a component conforming to the `Describable` protocol instead of `Actionable`.

## [1.0.0-beta-6](https://github.com/checkout/checkout-ios-components/releases/tag/1.0.0-beta-6)

Released on 15.04.2025

Updates:

-   **Address Component** – Introduced a new Address Component, providing a streamlined and user-friendly interface for collecting customer address information. This component simplifies address input, improving the checkout experience and reducing potential errors.

## [1.0.0-beta-5](https://github.com/checkout/checkout-ios-components/releases/tag/1.0.0-beta-5)

Released on 19.03.2025

Updates:

- **Fix Apple Pay Button Bug** – Fixes the view hierarchy that prevented the Apple Pay Button to receive the tap gestures.

## [1.0.0-beta-4](https://github.com/checkout/checkout-ios-components/releases/tag/1.0.0-beta-4)

Released on 13.03.2025

Updates:

- **Risk SDK Integration** – Risk SDK calls are now integrated as part of Flow SDK. This is automatically done behind the scenes and requires no code change.
- **Card Tokenisation Callback** – A new optional callback is added - `onTokenized()` alongside a new function to trigger it `tokenize()`. Ability to hide the pay button in addition to pay button modes: `tokenize and payment` are also implemented.

## [1.0.0-beta-3](https://github.com/checkout/checkout-ios-components/releases/tag/1.0.0-beta-3)

Released on 11.02.2025

Updates:

- **Fix a Distribution Setting** – Fixing a distribution setting that allows backwards compatibility with Xcode versions.

## [1.0.0-beta-2](https://github.com/checkout/checkout-ios-components/releases/tag/1.0.0-beta-2)

Released on 07.02.2025

Updates:

- **Improved Dependencies & Integration** – Improved dependencies and made integration easier.
- **Signed XCFramework** – XCFramework is now signed so you can verify the source safely.
- **Locale Fixes** – Fixed locale strings so that they always match the payment session counterpart.

## [1.0.0-beta-1](https://github.com/checkout/checkout-ios-components/releases/tag/1.0.0-beta-1)

Released on 30.01.2025

Updates:

- **End-to-End Payment Experience** – Delivering a seamless, secured and integrated payment journey.

- **Apple Pay** – Added support for Apple Pay as a payment method.

- **Card Payments** – Introduced a complete card payment experience, including card scheme detection and input validation.

- **3DS Authentication Challenge Handling** – Introduced webview handling for 3DS authentication.

- **Multi-Language Support** – Available in 23 languages, with customizable locale settings and full support for right-to-left (RTL) layouts.

- **Visual Customization** – Enhanced UI customization options for a more tailored user experience.

- **Swift Package Manager (SPM)** – Available via SPM for easier integration and dependency management.
