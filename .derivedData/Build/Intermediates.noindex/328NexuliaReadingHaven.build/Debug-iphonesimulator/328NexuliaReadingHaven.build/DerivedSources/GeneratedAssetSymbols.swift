import Foundation
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

    /// The "AccentColor" asset catalog color resource.
    static let accent = DeveloperToolsSupport.ColorResource(name: "AccentColor", bundle: resourceBundle)

    /// The "AppAccent" asset catalog color resource.
    static let appAccent = DeveloperToolsSupport.ColorResource(name: "AppAccent", bundle: resourceBundle)

    /// The "AppBackground" asset catalog color resource.
    static let appBackground = DeveloperToolsSupport.ColorResource(name: "AppBackground", bundle: resourceBundle)

    /// The "AppPrimary" asset catalog color resource.
    static let appPrimary = DeveloperToolsSupport.ColorResource(name: "AppPrimary", bundle: resourceBundle)

    /// The "AppSurface" asset catalog color resource.
    static let appSurface = DeveloperToolsSupport.ColorResource(name: "AppSurface", bundle: resourceBundle)

    /// The "AppTextPrimary" asset catalog color resource.
    static let appTextPrimary = DeveloperToolsSupport.ColorResource(name: "AppTextPrimary", bundle: resourceBundle)

    /// The "AppTextSecondary" asset catalog color resource.
    static let appTextSecondary = DeveloperToolsSupport.ColorResource(name: "AppTextSecondary", bundle: resourceBundle)

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

    /// The "bannerPagesGlow" asset catalog image resource.
    static let bannerPagesGlow = DeveloperToolsSupport.ImageResource(name: "bannerPagesGlow", bundle: resourceBundle)

    /// The "bannerPenNotes" asset catalog image resource.
    static let bannerPenNotes = DeveloperToolsSupport.ImageResource(name: "bannerPenNotes", bundle: resourceBundle)

    /// The "bgBookDesk" asset catalog image resource.
    static let bgBookDesk = DeveloperToolsSupport.ImageResource(name: "bgBookDesk", bundle: resourceBundle)

    /// The "btnDestructiveSkin" asset catalog image resource.
    static let btnDestructiveSkin = DeveloperToolsSupport.ImageResource(name: "btnDestructiveSkin", bundle: resourceBundle)

    /// The "btnFabSkin" asset catalog image resource.
    static let btnFabSkin = DeveloperToolsSupport.ImageResource(name: "btnFabSkin", bundle: resourceBundle)

    /// The "btnPrimarySkin" asset catalog image resource.
    static let btnPrimarySkin = DeveloperToolsSupport.ImageResource(name: "btnPrimarySkin", bundle: resourceBundle)

    /// The "btnSecondarySkin" asset catalog image resource.
    static let btnSecondarySkin = DeveloperToolsSupport.ImageResource(name: "btnSecondarySkin", bundle: resourceBundle)

    /// The "btnTabIdleSkin" asset catalog image resource.
    static let btnTabIdleSkin = DeveloperToolsSupport.ImageResource(name: "btnTabIdleSkin", bundle: resourceBundle)

    /// The "btnTabSelectedSkin" asset catalog image resource.
    static let btnTabSelectedSkin = DeveloperToolsSupport.ImageResource(name: "btnTabSelectedSkin", bundle: resourceBundle)

    /// The "fieldPaperSkin" asset catalog image resource.
    static let fieldPaperSkin = DeveloperToolsSupport.ImageResource(name: "fieldPaperSkin", bundle: resourceBundle)

    /// The "imgBookStack" asset catalog image resource.
    static let imgBookStack = DeveloperToolsSupport.ImageResource(name: "imgBookStack", bundle: resourceBundle)

}

