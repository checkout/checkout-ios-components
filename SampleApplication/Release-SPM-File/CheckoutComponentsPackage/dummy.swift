// SPM requires every regular target to contain at least one source file.
// `CheckoutComponentsPackage` is a thin wrapper target that exposes the
// `CheckoutComponentsSDK` binary target through SPM's product graph; it has
// no real implementation of its own. This empty file satisfies that
// requirement without affecting the published binary.
