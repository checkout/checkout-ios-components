# Flow for Mobile iOS SDK ![BETA](https://img.shields.io/badge/status-BETA-yellow)

To see the details of how to integrate the SDK, please refer to our [public documentation](https://www.checkout.com/docs/payments/accept-payments/accept-a-payment-on-your-mobile-app).

Also, you can find an example integration by running our Sample Application.

## Configuring the sample app:
When you first clone the repository, you will see 2 files under the `SampleApplication/SampleApplication/Configuration` file:

<img width="213" alt="initial-state" src="https://github.com/user-attachments/assets/dc5d279d-1902-4c9c-9a8e-0aa5f9053883" />

`env-example.xcconfig`: Includes a dummy example of environment variables to be tracked under source control and to be shared.
`EnvironmentVars.stencil`: Code generation template file for a new tool that we start using: [Sourcery](https://github.com/krzysztofzablocki/Sourcery)

The actions that you need to take after cloning the repo:

`cd` to the repository's root folder.
run `bash .github/scripts/init-env-vars.sh`

Go to the newly copied file that’s `env.xcconfig`, which is an untracked (by `.gitignore`) version of the example file to host the public and private keys
Replace the dummy values with their own values that you received from Checkout.com.

run bash `.github/scripts/codegen-env-vars.sh`

This will create another untracked but compilable file named `EnvironmentVars.generated.swift` which will be referenced in the code.

You can run the sample project and see it up and running!

The final thing you will have will look like below:

<img width="292" alt="latest-state" src="https://github.com/user-attachments/assets/afd548ac-fe75-4722-966c-1627152b8b8d"/>


> [!CAUTION]
> Embedding the secret key into the `Sample Application` is only to see the sample app in a quick way. In real life, you must never embed a secret key into your actual application since there is practically no viable way to secure it fully. You must make a request to your own APIs to create a payment session.

## Dependencies
Please add NetworkClient dynamic dependency to the sample app's Package Dependencies: https://github.com/checkout/NetworkClient-iOS
