import XCTest
import ImageIO

private struct ScreenshotPixels {
    let width: Int
    let height: Int
    let scale: CGFloat
    private let rgba: [UInt8]

    init(app: XCUIApplication) {
        let png = app.screenshot().pngRepresentation
        let source = CGImageSourceCreateWithData(png as CFData, nil)!
        let image = CGImageSourceCreateImageAtIndex(source, 0, nil)!
        let imageWidth = image.width
        let imageHeight = image.height
        width = imageWidth
        height = imageHeight
        scale = CGFloat(imageWidth) / app.windows.firstMatch.frame.width
        var pixels = [UInt8](repeating: 0, count: imageWidth * imageHeight * 4)
        pixels.withUnsafeMutableBytes { bytes in
            let space = CGColorSpace(name: CGColorSpace.sRGB)!
            let context = CGContext(data: bytes.baseAddress, width: imageWidth, height: imageHeight,
                                    bitsPerComponent: 8, bytesPerRow: imageWidth * 4,
                                    space: space,
                                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            context.draw(image, in: CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight))
        }
        rgba = pixels
    }

    func color(at point: CGPoint) -> [Int] {
        color(x: Int(point.x * scale), y: Int(point.y * scale))
    }

    func color(x: Int, y: Int) -> [Int] {
        precondition(x >= 0 && x < width && y >= 0 && y < height)
        let offset = (y * width + x) * 4
        return (0..<3).map { Int(rgba[offset + $0]) }
    }
}

final class AppMainUITests: XCTestCase {
    func testManagedSwiftUIAppFormPickerTabsAndNativeBack() {
        let app = XCUIApplication(bundleIdentifier:
            "com.davidortinau.microsoftswiftui.appmainprobe20261003")

        func capture(_ title: String) {
            let screenshot = XCTAttachment(screenshot: app.screenshot())
            screenshot.name = title
            screenshot.lifetime = .keepAlways
            add(screenshot)
            let hierarchy = XCTAttachment(string: app.debugDescription)
            hierarchy.name = "\(title)-accessibility"
            hierarchy.lifetime = .keepAlways
            add(hierarchy)
        }

        app.launch()
        let language = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Language")).firstMatch
        let password = app.secureTextFields["Password"]
        let submit = app.buttons["Continue"]
        XCTAssertTrue(language.waitForExistence(timeout: 20))
        XCTAssertTrue(password.exists)
        XCTAssertEqual(password.elementType, .secureTextField)
        XCTAssertTrue(app.secureTextFields["probe.password"].exists)
        XCTAssertTrue(app.buttons["probe.language"].exists)
        XCTAssertTrue(submit.exists)
        XCTAssertFalse(submit.isEnabled)
        XCTAssertTrue(app.staticTexts["Selected: English"].exists)
        XCTAssertTrue(app.staticTexts["Appear: yes"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Scene: Active"].waitForExistence(timeout: 5))
        capture("managed-account-form")

        language.tap()
        let korean = app.buttons["Korean"]
        XCTAssertTrue(korean.waitForExistence(timeout: 5))
        korean.tap()
        XCTAssertTrue(app.staticTexts["Selected: Korean"].waitForExistence(timeout: 5))
        capture("bound-managed-picker")

        app.buttons["Open detail"].tap()
        XCTAssertTrue(app.staticTexts["Detail from managed C#"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.tabBars.buttons["Resources"].exists)
        app.buttons["Refresh detail"].tap()
        XCTAssertTrue(app.staticTexts["Detail refreshed in C#"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.navigationBars["Detail refreshed"].exists)
        app.buttons["Lock Back"].tap()
        XCTAssertTrue(app.staticTexts["Back locked"].exists)
        XCTAssertFalse(app.navigationBars.buttons["BackButton"].exists)
        app.buttons["Unlock Back"].tap()
        XCTAssertTrue(app.navigationBars.buttons["BackButton"].waitForExistence(timeout: 5))
        capture("managed-detail-pushed")
        let nativeBack = app.navigationBars.buttons.firstMatch
        XCTAssertTrue(nativeBack.waitForExistence(timeout: 5))
        nativeBack.tap()
        XCTAssertTrue(app.buttons["Open detail"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Returned to root"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["Resources"].exists)
        capture("native-back-synchronized")

        app.tabBars.buttons["Resources"].tap()
        XCTAssertTrue(app.staticTexts["Resources in SwiftUI List"].waitForExistence(timeout: 5))
        app.buttons["Open resource"].tap()
        XCTAssertTrue(app.staticTexts["Source detail"].waitForExistence(timeout: 5))
        capture("independent-resources-stack")

        app.tabBars.buttons["Account"].tap()
        XCTAssertTrue(app.buttons["Open detail"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Selected: Korean"].exists)
        capture("account-tab-state-preserved")

        app.tabBars.buttons["Resources"].tap()
        XCTAssertTrue(app.staticTexts["Source detail"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Account"].tap()
        password.tap()
        password.typeText("bridge")
        XCTAssertTrue(app.staticTexts["Password entered"].waitForExistence(timeout: 5))
        XCTAssertTrue(submit.isEnabled)
        submit.tap()
        XCTAssertTrue(app.staticTexts["Submitted"].waitForExistence(timeout: 5))
        capture("secure-input-managed-state")
    }

    func testFullResourceCardIsTappableAtMetadataAndEdge() {
        let app = XCUIApplication(bundleIdentifier:
            "com.davidortinau.microsoftswiftui.appmainprobe20261003")
        app.launch()
        app.tabBars.buttons["Resources"].tap()
        let card = app.buttons["Open resource card"]
        XCTAssertTrue(card.waitForExistence(timeout: 15))
        XCTAssertGreaterThan(card.frame.width, 100)
        card.coordinate(withNormalizedOffset: CGVector(dx: 0.90, dy: 0.85)).tap()
        XCTAssertTrue(app.staticTexts["Card detail"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        card.coordinate(withNormalizedOffset: CGVector(dx: 0.10, dy: 0.15)).tap()
        XCTAssertTrue(app.staticTexts["Card detail"].waitForExistence(timeout: 5))
    }

    func testCancellingFileImporterDoesNotReportReadFailure() {
        let app = XCUIApplication(bundleIdentifier:
            "com.davidortinau.microsoftswiftui.appmainprobe20261003")
        app.launch()
        app.tabBars.buttons["Resources"].tap()
        app.buttons["Choose file"].tap()
        let cancel = app.buttons["Cancel"].firstMatch
        XCTAssertTrue(cancel.waitForExistence(timeout: 15))
        cancel.tap()
        XCTAssertTrue(app.staticTexts["Import cancelled"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["File error: readFailed"].exists)
    }

    func testCSharpSourceStyleThemeProgressInsetAndAdaptiveViewport() {
        let app = XCUIApplication(bundleIdentifier:
            "com.davidortinau.microsoftswiftui.appmainprobe20261003")
        func capture(_ title: String) {
            let screenshot = XCTAttachment(screenshot: app.screenshot())
            screenshot.name = title
            screenshot.lifetime = .keepAlways
            add(screenshot)
            let tree = XCTAttachment(string: app.debugDescription)
            tree.name = "\(title)-accessibility"
            tree.lifetime = .keepAlways
            add(tree)
        }

        app.launch()
        app.tabBars.buttons["Resources"].tap()
        app.buttons["Open styling probe"].tap()
        XCTAssertTrue(app.staticTexts["Scheme: Dark"].waitForExistence(timeout: 10))
        let viewport = app.staticTexts["probe.style.viewport"]
        XCTAssertTrue(viewport.waitForExistence(timeout: 5))
        XCTAssertTrue(viewport.label.contains("resources 1 tiles 2"), viewport.label)

        let card = app.buttons["probe.style.card"]
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        let availableWidth = app.windows.firstMatch.frame.width - 24
        XCTAssertGreaterThan(card.frame.width, availableWidth - 32)
        XCTAssertLessThanOrEqual(card.frame.width, 441)
        card.coordinate(withNormalizedOffset: CGVector(dx: 0.90, dy: 0.85)).tap()
        XCTAssertTrue(app.staticTexts["Card taps: 1"].waitForExistence(timeout: 5))

        let progress = app.progressIndicators["probe.style.progress"]
        let thinProgress = app.progressIndicators["probe.style.progress.thin"]
        XCTAssertTrue(progress.waitForExistence(timeout: 5))
        XCTAssertTrue(thinProgress.exists)
        XCTAssertTrue((progress.value as? String ?? "").contains("33"), "\(String(describing: progress.value))")
        XCTAssertEqual(progress.frame.height, 8, accuracy: 2)
        XCTAssertEqual(thinProgress.frame.height, 4, accuracy: 2)
        capture("style-source-dark-phone")

        app.buttons["Toggle Scheme"].tap()
        XCTAssertTrue(app.staticTexts["Scheme: Light"].waitForExistence(timeout: 5))
        capture("style-source-light-phone")
        app.buttons["Advance Progress"].tap()
        XCTAssertTrue(app.staticTexts["Progress: 2 of 3"].waitForExistence(timeout: 5))
        XCTAssertTrue((progress.value as? String ?? "").contains("67"), "\(String(describing: progress.value))")

        let portraitLabel = viewport.label
        let portraitWidth = Int(portraitLabel.split(separator: " ")[1]) ?? 0
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        let rotated = NSPredicate(format: "label != %@", portraitLabel)
        expectation(for: rotated, evaluatedWith: viewport)
        waitForExpectations(timeout: 10)
        let landscapeWidth = Int(viewport.label.split(separator: " ")[1]) ?? 0
        XCTAssertGreaterThan(landscapeWidth, portraitWidth)
        XCTAssertLessThan(landscapeWidth, 768)
        XCTAssertTrue(viewport.label.contains("resources 1 tiles 2"), viewport.label)
        capture("style-source-light-wide")
        XCUIDevice.shared.orientation = .portrait

        let firstFilter = app.buttons["probe.style.filter.one"]
        let secondFilter = app.buttons["probe.style.filter.two"]
        for _ in 0..<4 where !secondFilter.isHittable { app.swipeUp() }
        XCTAssertTrue(firstFilter.isHittable && secondFilter.isHittable)
        XCTAssertGreaterThanOrEqual(secondFilter.frame.minY, firstFilter.frame.maxY - 3)

        let input = app.textFields["probe.style.input"]
        for _ in 0..<4 where !input.isHittable { app.swipeUp() }
        XCTAssertTrue(input.isHittable)
        input.tap()
        input.typeText("crew")
        let inputStatus = app.staticTexts["probe.style.input.status"]
        XCTAssertTrue(app.staticTexts["Input: crew"].waitForExistence(timeout: 5))
        XCTAssertEqual(inputStatus.label, "Input: crew")

        let footer = app.descendants(matching: .any)["probe.style.footer"].firstMatch
        let footerAction = app.buttons["probe.style.footer.action"]
        XCTAssertTrue(footer.waitForExistence(timeout: 5))
        XCTAssertTrue(footerAction.isHittable)
        XCTAssertGreaterThan(footer.frame.minY, app.windows.firstMatch.frame.midY)
        XCTAssertLessThanOrEqual(footer.frame.maxY, app.windows.firstMatch.frame.maxY)
        if app.keyboards.firstMatch.exists {
            XCTAssertLessThanOrEqual(footerAction.frame.maxY,
                                     app.keyboards.firstMatch.frame.minY + 2)
        }
        footerAction.tap()
        XCTAssertTrue(app.staticTexts["Footer activated"].waitForExistence(timeout: 5))
        capture("style-source-keyboard-footer")
    }

    func testCSharpStyleRespectsAccessibilityTextSize() {
        let app = XCUIApplication(bundleIdentifier:
            "com.davidortinau.microsoftswiftui.appmainprobe20261003")
        app.launchArguments += [
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityM"
        ]
        app.launch()
        app.tabBars.buttons["Resources"].tap()
        app.buttons["Open styling probe"].tap()
        let viewport = app.staticTexts["probe.style.viewport"]
        XCTAssertTrue(viewport.waitForExistence(timeout: 10))
        XCTAssertTrue(viewport.label.contains("size Accessibility1"), viewport.label)
        let filters = app.buttons["probe.style.filter.two"]
        for _ in 0..<5 where !filters.isHittable { app.swipeUp() }
        XCTAssertTrue(filters.isHittable)
        let first = app.buttons["probe.style.filter.one"]
        XCTAssertGreaterThanOrEqual(filters.frame.minY, first.frame.maxY - 3)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "style-source-accessibility-xl"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    func testV8FormAndListUsePairedNativeSurfacesAndInlineTitles() {
        let app = XCUIApplication(bundleIdentifier:
            "com.davidortinau.microsoftswiftui.appmainprobe20261003")
        func capture(_ name: String) {
            let screenshot = XCTAttachment(screenshot: app.screenshot())
            screenshot.name = name
            screenshot.lifetime = .keepAlways
            add(screenshot)
            let tree = XCTAttachment(string: app.debugDescription)
            tree.name = "\(name)-accessibility"
            tree.lifetime = .keepAlways
            add(tree)
        }
        app.launch()
        app.tabBars.buttons["Resources"].tap()
        app.buttons["probe.v8.open"].tap()
        app.buttons["probe.v8.open.form"].tap()

        let formTitle = app.navigationBars["Source Form"]
        let email = app.textFields["probe.v8.form.email"]
        let secure = app.secureTextFields["probe.v8.form.password"]
        XCTAssertTrue(formTitle.waitForExistence(timeout: 10))
        XCTAssertGreaterThanOrEqual(formTitle.frame.height, 44)
        XCTAssertLessThanOrEqual(formTitle.frame.height, 64)
        XCTAssertTrue(email.exists && secure.exists)
        XCTAssertEqual(secure.elementType, .secureTextField)
        XCTAssertEqual(secure.placeholderValue, "Password")
        XCTAssertTrue(app.staticTexts["probe.v8.form.heading"].exists)
        capture("v8-native-form-dark")

        app.buttons["probe.v8.form.theme"].tap()
        XCTAssertTrue(app.staticTexts["Mode: Light"].waitForExistence(timeout: 5))
        capture("v8-native-form-light")
        app.buttons["probe.v8.form.theme"].tap()
        XCTAssertTrue(app.staticTexts["Mode: Dark"].waitForExistence(timeout: 5))
        secure.tap()
        secure.typeText("bridge")
        XCTAssertTrue(app.staticTexts["Secure input entered"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.keyboards.firstMatch.exists)
        capture("v8-native-form-secure-keyboard")

        formTitle.buttons.firstMatch.tap()
        XCTAssertTrue(app.buttons["probe.v8.open.list"].waitForExistence(timeout: 5))
        app.buttons["probe.v8.open.list"].tap()
        let listTitle = app.navigationBars["Source List"]
        XCTAssertTrue(listTitle.waitForExistence(timeout: 5))
        XCTAssertLessThanOrEqual(listTitle.frame.height, 64)
        XCTAssertTrue(app.staticTexts["probe.v8.list.first"].exists)
        XCTAssertTrue(app.staticTexts["probe.v8.list.second"].exists)
        XCTAssertTrue(app.staticTexts["probe.v8.list.third"].exists)
        capture("v8-native-list-dark")
    }

    func testV8MinimumButtonHeightBelongsToActualButton() {
        let app = XCUIApplication(bundleIdentifier:
            "com.davidortinau.microsoftswiftui.appmainprobe20261003")
        app.launch()
        app.tabBars.buttons["Resources"].tap()
        app.buttons["probe.v8.open"].tap()
        app.buttons["probe.v8.open.buttons"].tap()

        let next = app.buttons["probe.v8.next"]
        let done = app.buttons["probe.v8.done"]
        let visibility = app.buttons["probe.v8.visibility"]
        XCTAssertTrue(next.waitForExistence(timeout: 10))
        XCTAssertTrue(done.exists && visibility.exists)
        XCTAssertEqual(app.buttons.matching(identifier: "probe.v8.next").count, 1)
        XCTAssertEqual(app.buttons.matching(identifier: "probe.v8.done").count, 1)
        XCTAssertGreaterThanOrEqual(next.frame.height, 44)
        XCTAssertGreaterThanOrEqual(done.frame.height, 44)
        XCTAssertGreaterThanOrEqual(visibility.frame.height, 44)
        next.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.95)).tap()
        XCTAssertTrue(app.staticTexts["Next tapped"].waitForExistence(timeout: 5))
        done.coordinate(withNormalizedOffset: CGVector(dx: 0.75, dy: 0.95)).tap()
        XCTAssertTrue(app.staticTexts["Done tapped"].waitForExistence(timeout: 5))
        visibility.coordinate(withNormalizedOffset: CGVector(dx: 0.80, dy: 0.90)).tap()
        XCTAssertTrue(app.staticTexts["Visibility tapped"].waitForExistence(timeout: 5))

        let geometry = XCTAttachment(string:
            "Next: \(next.frame); Done: \(done.frame); Visibility: \(visibility.frame)")
        geometry.name = "v8-native-button-hit-geometry"
        geometry.lifetime = .keepAlways
        add(geometry)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "v8-native-button-hit"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    func testV8ShortSignInCentersAndKeyboardDoesNotTrapControls() {
        let app = XCUIApplication(bundleIdentifier:
            "com.davidortinau.microsoftswiftui.appmainprobe20261003")
        app.launch()
        app.tabBars.buttons["Resources"].tap()
        app.buttons["probe.v8.open"].tap()
        app.buttons["probe.v8.open.center"].tap()

        let brand = app.staticTexts["probe.v8.center.brand"]
        let secure = app.secureTextFields["probe.v8.center.password"]
        let scroll = app.scrollViews["probe.v8.center.scroll"]
        XCTAssertTrue(brand.waitForExistence(timeout: 10))
        XCTAssertTrue(secure.exists)
        XCTAssertTrue(scroll.exists)
        XCTAssertGreaterThan(brand.frame.minY, 140)
        XCTAssertEqual(secure.elementType, .secureTextField)
        XCTAssertEqual(secure.placeholderValue, "Password")
        let centered = XCTAttachment(screenshot: app.screenshot())
        centered.name = "v8-source-signin-centered-dark"
        centered.lifetime = .keepAlways
        add(centered)

        secure.tap()
        secure.typeText("bridge")
        let bottom = app.staticTexts["probe.v8.center.bottom"]
        for _ in 0..<5 where !bottom.isHittable { scroll.swipeUp() }
        XCTAssertTrue(bottom.isHittable)
        XCTAssertTrue(app.keyboards.firstMatch.exists)
        XCTAssertLessThanOrEqual(bottom.frame.maxY,
                                 app.keyboards.firstMatch.frame.minY + 2)
        XCTAssertTrue(app.staticTexts["Password entered"].exists)
        let keyboard = XCTAttachment(screenshot: app.screenshot())
        keyboard.name = "v8-source-signin-keyboard-scroll"
        keyboard.lifetime = .keepAlways
        add(keyboard)
    }

    func testV8XLSignInRemainsScrollableWithSecureFocus() {
        let app = XCUIApplication(bundleIdentifier:
            "com.davidortinau.microsoftswiftui.appmainprobe20261003")
        app.launchArguments += [
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityM"
        ]
        app.launch()
        app.tabBars.buttons["Resources"].tap()
        app.buttons["probe.v8.open"].tap()
        app.buttons["probe.v8.open.center"].tap()

        let scroll = app.scrollViews["probe.v8.center.scroll"]
        let secure = app.secureTextFields["probe.v8.center.password"]
        XCTAssertTrue(scroll.waitForExistence(timeout: 10))
        for _ in 0..<5 where !secure.isHittable { scroll.swipeUp() }
        XCTAssertTrue(secure.isHittable)
        secure.tap()
        secure.typeText("bridge")
        XCTAssertTrue(app.keyboards.firstMatch.exists)
        let submit = app.buttons["probe.v8.center.submit"]
        for _ in 0..<6 where !submit.isHittable { scroll.swipeUp() }
        XCTAssertTrue(submit.isHittable)
        XCTAssertGreaterThanOrEqual(submit.frame.height, 44)
        XCTAssertLessThanOrEqual(submit.frame.maxY,
                                 app.keyboards.firstMatch.frame.minY + 2)
        let capture = XCTAttachment(screenshot: app.screenshot())
        capture.name = "v8-source-signin-xl-keyboard"
        capture.lifetime = .keepAlways
        add(capture)
    }

    func testV9SourceButtonAppearanceTransparencyOpacityRadiusAndHit() {
        let app = XCUIApplication(bundleIdentifier:
            "com.davidortinau.microsoftswiftui.appmainprobe20261003")
        app.launch()
        app.tabBars.buttons["Resources"].tap()
        app.buttons["probe.v9.open"].tap()

        let tertiary = app.buttons["probe.v9.tertiary"]
        XCTAssertTrue(tertiary.waitForExistence(timeout: 10))
        let dark = ScreenshotPixels(app: app)
        assertColor(dark.color(at: CGPoint(x: tertiary.frame.minX + 8,
                                           y: tertiary.frame.midY)),
                    [18, 27, 51], "dark filled secondary")
        let darkOutlineBody = app.buttons["probe.v9.outline.body"]
        let darkOutlineCard = app.buttons["probe.v9.outline.card"]
        let darkDisabled = app.buttons["probe.v9.disabled"]
        assertColor(dark.color(at: CGPoint(x: darkOutlineBody.frame.minX + 8,
                                           y: darkOutlineBody.frame.midY)),
                    [6, 9, 19], "clear outline over dark body")
        assertColor(dark.color(at: CGPoint(x: darkOutlineCard.frame.minX + 8,
                                           y: darkOutlineCard.frame.midY)),
                    [18, 27, 51], "clear outline over dark card")
        assertColor(dark.color(at: CGPoint(x: darkOutlineBody.frame.minX + 0.5,
                                           y: darkOutlineBody.frame.midY)),
                    [147, 163, 199], "dark outline border")
        assertColor(dark.color(at: CGPoint(x: darkDisabled.frame.minX + 8,
                                           y: darkDisabled.frame.midY)),
                    [72, 94, 173], "disabled dark 0.65 composite", tolerance: 3)
        captureV9(app, "v9-buttons-dark")

        app.buttons["probe.v9.theme"].tap()
        XCTAssertTrue(app.staticTexts["Mode: Light"].waitForExistence(timeout: 5))
        let radius6 = app.buttons["probe.v9.radius.6"]
        let radius25 = app.buttons["probe.v9.radius.25"]
        let radius2Point4 = app.buttons["probe.v9.radius.2.4"]
        XCTAssertTrue(radius6.isHittable && radius25.isHittable && radius2Point4.isHittable)
        let light = ScreenshotPixels(app: app)
        assertColor(light.color(at: CGPoint(x: tertiary.frame.minX + 8,
                                            y: tertiary.frame.midY)),
                    [248, 249, 250], "Flatly filled secondary")
        assertColor(light.color(at: CGPoint(x: radius6.frame.minX + 4,
                                            y: radius6.frame.minY + 4)),
                    [44, 62, 80], "6pt rounded fill")
        assertColor(light.color(at: CGPoint(x: radius25.frame.minX + 4,
                                            y: radius25.frame.minY + 4)),
                    [255, 255, 255], "25pt clear corner")
        assertColor(light.color(at: CGPoint(x: radius25.frame.minX + 20,
                                            y: radius25.frame.minY + 4)),
                    [44, 62, 80], "25pt inside fill")
        assertColor(light.color(at: CGPoint(x: radius2Point4.frame.minX + 1.5,
                                            y: radius2Point4.frame.minY + 1.5)),
                    [44, 62, 80], "2.4pt small corner")
        XCTAssertGreaterThanOrEqual(radius6.frame.height, 44)
        radius6.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.9)).tap()
        XCTAssertTrue(app.staticTexts["Radius six tapped"].waitForExistence(timeout: 5))
        captureV9(app, "v9-buttons-light-radii")

        let scroll = app.scrollViews["probe.v9.screen"]
        let outlineBody = app.buttons["probe.v9.outline.body"]
        let outlineCard = app.buttons["probe.v9.outline.card"]
        let disabled = app.buttons["probe.v9.disabled"]
        let parentDisabled = app.buttons["probe.v9.parent.disabled"]
        for _ in 0..<5 where !parentDisabled.isHittable { scroll.swipeUp() }
        XCTAssertTrue(outlineBody.isHittable && outlineCard.isHittable)
        XCTAssertGreaterThanOrEqual(outlineBody.frame.height, 44)
        XCTAssertEqual(app.buttons.matching(identifier: "probe.v9.outline.body").count, 1)
        let lower = ScreenshotPixels(app: app)
        assertColor(lower.color(at: CGPoint(x: outlineBody.frame.minX + 8,
                                            y: outlineBody.frame.midY)),
                    [255, 255, 255], "clear outline over white")
        assertColor(lower.color(at: CGPoint(x: outlineCard.frame.minX + 8,
                                            y: outlineCard.frame.midY)),
                    [238, 241, 255], "clear outline over a card")
        assertColor(lower.color(at: CGPoint(x: outlineBody.frame.minX + 0.5,
                                            y: outlineBody.frame.midY)),
                    [107, 120, 136], "light outline border")
        assertColor(lower.color(at: CGPoint(x: disabled.frame.minX + 8,
                                            y: disabled.frame.midY)),
                    [118, 130, 141], "disabled Flatly 0.65 composite", tolerance: 3)
        XCTAssertFalse(disabled.isEnabled)
        XCTAssertFalse(parentDisabled.isEnabled)
        disabled.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.85)).tap()
        parentDisabled.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.85)).tap()
        XCTAssertTrue(app.staticTexts["Radius six tapped"].exists)
        outlineBody.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.85)).tap()
        XCTAssertTrue(app.staticTexts["probe.v9.outline.body tapped"].waitForExistence(timeout: 5))
        outlineCard.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.85)).tap()
        XCTAssertTrue(app.staticTexts["probe.v9.outline.card tapped"].waitForExistence(timeout: 5))
        captureV9(app, "v9-buttons-clear-disabled")
    }

    func testV10VaporLightTwoPointButtonStrokeAndUnchangedOnePointSibling() {
        let app = XCUIApplication(bundleIdentifier:
            "com.davidortinau.microsoftswiftui.appmainprobe20261003")
        app.launch()
        app.tabBars.buttons["Resources"].tap()
        app.buttons["probe.v10.open"].tap()

        let source = app.buttons["probe.v10.vapor.override"]
        let standard = app.buttons["probe.v10.default"]
        let mutable = app.buttons["probe.v10.mutable"]
        let disabled = app.buttons["probe.v10.disabled"]
        let inheritedDisabled = app.buttons["probe.v10.parent.disabled"]
        XCTAssertTrue(source.waitForExistence(timeout: 10))
        for button in [source, standard, mutable, disabled, inheritedDisabled] {
            XCTAssertEqual(app.buttons.matching(identifier: button.identifier).count, 1)
            XCTAssertGreaterThanOrEqual(button.frame.height + 0.01, 44)
        }
        XCTAssertFalse(disabled.isEnabled)
        XCTAssertFalse(inheritedDisabled.isEnabled)

        let background = [26, 9, 51]
        let border = [60, 242, 129]
        let disabledBorder = [48, 160, 102]
        let before = ScreenshotPixels(app: app)
        XCTAssertEqual(before.scale, 3, accuracy: 0.01)

        func edge(_ pixels: ScreenshotPixels, _ button: XCUIElement, _ offset: CGFloat) -> [Int] {
            pixels.color(at: CGPoint(x: button.frame.minX + offset, y: button.frame.midY))
        }
        func strokePixels(_ pixels: ScreenshotPixels, _ button: XCUIElement) -> Int {
            let x = Int(button.frame.minX * pixels.scale)
            let y = Int(button.frame.midY * pixels.scale)
            let samples = (0..<12).map { pixels.color(x: x + $0, y: y) }
            guard let first = samples.firstIndex(where: { near($0, border, tolerance: 12) })
            else { return 0 }
            return samples.dropFirst(first)
                .prefix(while: { near($0, border, tolerance: 12) }).count
        }

        assertColor(edge(before, source, 0.5), border, "Vapor 2pt outer edge")
        assertColor(edge(before, source, 1.5), border, "Vapor 2pt inner edge")
        assertColor(edge(before, source, 2.5), background, "transparent fill past 2pt")
        assertColor(edge(before, standard, 0.5), border, "default 1pt edge")
        assertColor(edge(before, standard, 1.5), background, "default 1pt interior")
        assertColor(edge(before, mutable, 1.5), border, "width before appearance")
        assertColor(edge(before, disabled, 1.5), disabledBorder,
                    "direct disabled border has one 65% composite", tolerance: 6)
        assertColor(edge(before, inheritedDisabled, 1.5), disabledBorder,
                    "inherited disabled border has one 65% composite", tolerance: 6)
        let sourceRun = strokePixels(before, source)
        let defaultRun = strokePixels(before, standard)
        XCTAssertEqual(Double(sourceRun), 6, accuracy: 1)
        XCTAssertEqual(Double(defaultRun), 3, accuracy: 1)
        let runEvidence = XCTAttachment(string:
            "deviceScale=\(before.scale); Vapor source stroke=\(sourceRun) px; " +
            "default stroke=\(defaultRun) px; button=\(source.frame)")
        runEvidence.name = "v10-source-vapor-light-stroke-width"
        runEvidence.lifetime = .keepAlways
        add(runEvidence)
        captureV9(app, "v10-vapor-light-2pt-default-1pt")

        source.coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.93)).tap()
        XCTAssertTrue(app.staticTexts["Override tapped"].waitForExistence(timeout: 5))
        disabled.coordinate(withNormalizedOffset: CGVector(dx: 0.90, dy: 0.90)).tap()
        inheritedDisabled.coordinate(withNormalizedOffset: CGVector(dx: 0.90, dy: 0.90)).tap()
        XCTAssertTrue(app.staticTexts["Override tapped"].exists)

        let toggle = app.buttons["probe.v10.toggle"]
        toggle.tap()
        XCTAssertTrue(app.staticTexts["Stroke one"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons.matching(identifier: "probe.v10.mutable").count, 1)
        let narrow = ScreenshotPixels(app: app)
        assertColor(edge(narrow, mutable, 1.5), background, "mounted setter changes to 1pt")
        assertColor(edge(narrow, source, 1.5), border, "other 2pt button unchanged")
        XCTAssertEqual(Double(strokePixels(narrow, mutable)), 3, accuracy: 1)
        captureV9(app, "v10-mounted-stroke-1pt")

        toggle.tap()
        XCTAssertTrue(app.staticTexts["Stroke two"].waitForExistence(timeout: 5))
        let restored = ScreenshotPixels(app: app)
        assertColor(edge(restored, mutable, 1.5), border, "mounted setter restores 2pt")
        XCTAssertEqual(Double(strokePixels(restored, mutable)), 6, accuracy: 1)
        mutable.coordinate(withNormalizedOffset: CGVector(dx: 0.90, dy: 0.90)).tap()
        XCTAssertTrue(app.staticTexts["Mutable tapped"].waitForExistence(timeout: 5))
        captureV9(app, "v10-mounted-stroke-2pt-hit")
    }

    func testV11SketchyEightAxesUseRealButtonInBothModesAndUpdateInPlace() {
        let app = XCUIApplication(bundleIdentifier:
            "com.davidortinau.microsoftswiftui.appmainprobe20261003")
        app.launch()
        app.tabBars.buttons["Resources"].tap()
        app.buttons["probe.v11.open"].tap()

        let source = app.buttons["probe.v11.sketchy.source"]
        let longer = app.buttons["probe.v11.sketchy.long"]
        let mutable = app.buttons["probe.v11.sketchy.mutable"]
        let rounded = app.buttons["probe.v11.rounded.default"]
        let disabled = app.buttons["probe.v11.sketchy.disabled"]
        let parentDisabled = app.buttons["probe.v11.sketchy.parent.disabled"]
        XCTAssertTrue(source.waitForExistence(timeout: 10))
        for button in [source, longer, mutable, rounded, disabled, parentDisabled] {
            XCTAssertEqual(app.buttons.matching(identifier: button.identifier).count, 1)
            XCTAssertGreaterThanOrEqual(button.frame.height + 0.01, 44)
        }
        XCTAssertGreaterThan(longer.frame.width, source.frame.width)
        XCTAssertFalse(disabled.isEnabled)
        XCTAssertFalse(parentDisabled.isEnabled)

        let light = ScreenshotPixels(app: app)
        XCTAssertEqual(light.scale, 3, accuracy: 0.01)
        assertSketchyCorners(light, source, [40, 167, 69], [255, 255, 255], "light")
        assertEllipseNotOldCircle(light, ellipse: source, oldCircle: rounded,
                                  border: [40, 167, 69], background: [255, 255, 255])
        func topStrokePixels(_ pixels: ScreenshotPixels, _ button: XCUIElement,
                             _ expected: [Int]) -> Int {
            let x = Int(button.frame.midX * pixels.scale)
            let y = Int(button.frame.minY * pixels.scale)
            let samples = (0..<12).map { pixels.color(x: x, y: y + $0) }
            guard let first = samples.firstIndex(where: { near($0, expected, tolerance: 8) })
            else { return 0 }
            return samples.dropFirst(first)
                .prefix(while: { near($0, expected, tolerance: 8) }).count
        }
        let lightStroke = topStrokePixels(light, source, [40, 167, 69])
        let oldStroke = topStrokePixels(light, rounded, [40, 167, 69])
        XCTAssertEqual(Double(lightStroke), 6, accuracy: 1)
        XCTAssertEqual(Double(oldStroke), 3, accuracy: 1)
        let strokeRecord = XCTAttachment(string:
            "deviceScale=\(light.scale); Sketchy source 2pt=\(lightStroke) physical pixels; " +
            "unmodified old 1pt=\(oldStroke) physical pixels")
        strokeRecord.name = "v11-sketchy-source-vs-old-stroke-pixels"
        strokeRecord.lifetime = .keepAlways
        add(strokeRecord)
        captureV9(app, "v11-sketchy-light-four-ellipses")
        source.coordinate(withNormalizedOffset: CGVector(dx: 0.94, dy: 0.86)).tap()
        XCTAssertTrue(app.staticTexts["probe.v11.sketchy.source tapped"].waitForExistence(timeout: 5))
        disabled.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.85)).tap()
        parentDisabled.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.85)).tap()
        XCTAssertTrue(app.staticTexts["probe.v11.sketchy.source tapped"].exists)

        let corner = CGPoint(x: mutable.frame.minX + 1.5, y: mutable.frame.minY + 1.5)
        assertColor(light.color(at: corner), [255, 255, 255], "elliptical top-left exterior")
        app.buttons["probe.v11.corners.toggle"].tap()
        XCTAssertTrue(app.staticTexts["Corners square"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons.matching(identifier: "probe.v11.sketchy.mutable").count, 1)
        let square = ScreenshotPixels(app: app)
        assertColor(square.color(at: corner), [40, 167, 69], "mounted square corner", tolerance: 12)
        assertColor(square.color(at: CGPoint(x: source.frame.minX + 1.5,
                                             y: source.frame.minY + 1.5)),
                    [255, 255, 255], "sibling ellipse unchanged")
        captureV9(app, "v11-mounted-square-corner")
        app.buttons["probe.v11.corners.toggle"].tap()
        XCTAssertTrue(app.staticTexts["Corners elliptical"].waitForExistence(timeout: 5))
        let restored = ScreenshotPixels(app: app)
        assertColor(restored.color(at: corner), [255, 255, 255], "mounted ellipse restored")
        mutable.coordinate(withNormalizedOffset: CGVector(dx: 0.88, dy: 0.86)).tap()
        XCTAssertTrue(app.staticTexts["probe.v11.sketchy.mutable tapped"].waitForExistence(timeout: 5))

        let scroll = app.scrollViews["probe.v11.screen"]
        let theme = app.buttons["probe.v11.theme"]
        for _ in 0..<5 where !theme.isHittable { scroll.swipeUp() }
        theme.tap()
        XCTAssertTrue(app.staticTexts["Mode: Dark"].waitForExistence(timeout: 5))
        for _ in 0..<5 where !source.isHittable { scroll.swipeDown() }
        let dark = ScreenshotPixels(app: app)
        assertSketchyCorners(dark, source, [18, 184, 134], [33, 37, 41], "dark")
        assertEllipseNotOldCircle(dark, ellipse: source, oldCircle: rounded,
                                  border: [18, 184, 134], background: [33, 37, 41])
        XCTAssertEqual(Double(topStrokePixels(dark, source, [18, 184, 134])),
                       6, accuracy: 1)
        captureV9(app, "v11-sketchy-dark-four-ellipses")
    }

    func testV11BriteLightAndDarkDisabledFillAndBorderCompositeOnce() {
        let app = XCUIApplication(bundleIdentifier:
            "com.davidortinau.microsoftswiftui.appmainprobe20261003")
        app.launch()
        app.tabBars.buttons["Resources"].tap()
        app.buttons["probe.v11.open"].tap()

        let enabled = app.buttons["probe.v11.brite.enabled"]
        let disabled = app.buttons["probe.v11.brite.disabled"]
        let parentDisabled = app.buttons["probe.v11.brite.parent.disabled"]
        let scroll = app.scrollViews["probe.v11.screen"]
        XCTAssertTrue(enabled.waitForExistence(timeout: 10))
        for _ in 0..<5 where !enabled.isHittable { scroll.swipeUp() }
        for button in [enabled, disabled, parentDisabled] {
            XCTAssertEqual(app.buttons.matching(identifier: button.identifier).count, 1)
            XCTAssertGreaterThanOrEqual(button.frame.height + 0.01, 44)
        }
        XCTAssertFalse(disabled.isEnabled)
        XCTAssertFalse(parentDisabled.isEnabled)
        let light = ScreenshotPixels(app: app)
        assertBriteComposite(light, enabled: enabled, disabled: disabled,
                             expectedDisabled: [194, 237, 124])
        captureV9(app, "v11-brite-light-single-opacity")

        disabled.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.85)).tap()
        parentDisabled.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.85)).tap()
        XCTAssertTrue(app.staticTexts["No action"].exists)
        enabled.coordinate(withNormalizedOffset: CGVector(dx: 0.86, dy: 0.85)).tap()
        XCTAssertTrue(app.staticTexts["probe.v11.brite.enabled tapped"].waitForExistence(timeout: 5))

        let theme = app.buttons["probe.v11.theme"]
        for _ in 0..<5 where !theme.isHittable { scroll.swipeUp() }
        theme.tap()
        XCTAssertTrue(app.staticTexts["Mode: Dark"].waitForExistence(timeout: 5))
        for _ in 0..<5 where !enabled.isHittable { scroll.swipeDown() }
        let dark = ScreenshotPixels(app: app)
        assertBriteComposite(dark, enabled: enabled, disabled: disabled,
                             expectedDisabled: [117, 161, 49])
        captureV9(app, "v11-brite-dark-single-opacity")
    }

    private func assertEllipseNotOldCircle(
        _ pixels: ScreenshotPixels, ellipse: XCUIElement, oldCircle: XCUIElement,
        border: [Int], background: [Int],
        file: StaticString = #filePath, line: UInt = #line
    ) {
        func distinguishingPoints(_ box: CGRect) -> [CGPoint] {
            [
                CGPoint(x: box.minX + 1, y: box.minY + 4),
                CGPoint(x: box.maxX - 3, y: box.minY + 3),
                CGPoint(x: box.maxX - 1, y: box.maxY - 4),
                CGPoint(x: box.minX + 3, y: box.maxY - 3)
            ]
        }
        for (corner, (newPoint, oldPoint)) in zip(
            ["top-left", "top-right", "bottom-right", "bottom-left"],
            zip(distinguishingPoints(ellipse.frame), distinguishingPoints(oldCircle.frame))
        ) {
            let newPixel = pixels.color(at: newPoint)
            let oldPixel = pixels.color(at: oldPoint)
            XCTAssertTrue(near(newPixel, border, tolerance: 8),
                          "\(corner) ellipse border: \(newPixel)", file: file, line: line)
            XCTAssertTrue(near(oldPixel, background, tolerance: 8),
                          "\(corner) unchanged circle exterior: \(oldPixel)", file: file, line: line)
        }
    }

    private func assertSketchyCorners(_ pixels: ScreenshotPixels, _ button: XCUIElement,
                                      _ border: [Int], _ background: [Int], _ mode: String,
                                      file: StaticString = #filePath, line: UInt = #line) {
        let bounds = button.frame
        let factor = min(1, bounds.width / 280, bounds.height / 250,
                         bounds.width / 250, bounds.height / 280)
        let radii: [CGSize] = [
            CGSize(width: 255 * factor, height: 25 * factor),
            CGSize(width: 25 * factor, height: 225 * factor),
            CGSize(width: 225 * factor, height: 25 * factor),
            CGSize(width: 25 * factor, height: 255 * factor)
        ]
        var observations: [String] = [
            "borderBox=\(bounds), CSS common factor=\(factor), scale=\(pixels.scale)"
        ]
        for (index, radius) in radii.enumerated() {
            let left = index == 0 || index == 3
            let top = index <= 1
            let signX: CGFloat = left ? -1 : 1
            let signY: CGFloat = top ? -1 : 1
            let center = CGPoint(x: (left ? bounds.minX : bounds.maxX) - signX * radius.width,
                                 y: (top ? bounds.minY : bounds.maxY) - signY * radius.height)
            let sqrtHalf = CGFloat(1 / sqrt(2.0))
            let mid = CGPoint(x: center.x + signX * radius.width * sqrtHalf,
                              y: center.y + signY * radius.height * sqrtHalf)
            let gradientX = signX / radius.width
            let gradientY = signY / radius.height
            let norm = hypot(gradientX, gradientY)
            let inward = CGPoint(x: mid.x - gradientX / norm,
                                 y: mid.y - gradientY / norm)
            let outside = CGPoint(x: mid.x + gradientX / norm,
                                  y: mid.y + gradientY / norm)
            let insideRgb = pixels.color(at: inward)
            let outsideRgb = pixels.color(at: outside)
            observations.append("corner\(index) axes=\(radius) inside=\(insideRgb) outside=\(outsideRgb)")
            XCTAssertTrue(near(insideRgb, border, tolerance: 16),
                          "\(mode) corner\(index) expected border \(border), got \(insideRgb)",
                          file: file, line: line)
            XCTAssertTrue(near(outsideRgb, background, tolerance: 8),
                          "\(mode) corner\(index) expected exterior \(background), got \(outsideRgb)",
                          file: file, line: line)
        }
        let record = XCTAttachment(string: observations.joined(separator: "\n"))
        record.name = "v11-\(mode)-measured-asymmetric-corners"
        record.lifetime = .keepAlways
        add(record)
    }

    private func assertBriteComposite(_ pixels: ScreenshotPixels, enabled: XCUIElement,
                                      disabled: XCUIElement, expectedDisabled: [Int],
                                      file: StaticString = #filePath, line: UInt = #line) {
        func rgb(_ button: XCUIElement, _ x: CGFloat) -> [Int] {
            pixels.color(at: CGPoint(x: button.frame.minX + x, y: button.frame.midY))
        }
        for x in [CGFloat(0.5), 1.5] {
            XCTAssertTrue(near(rgb(enabled, x), [0, 0, 0], tolerance: 1),
                          "enabled black 2pt border at \(x): \(rgb(enabled, x))",
                          file: file, line: line)
            XCTAssertTrue(near(rgb(disabled, x), expectedDisabled, tolerance: 1),
                          "disabled green 2pt border at \(x): \(rgb(disabled, x))",
                          file: file, line: line)
        }
        XCTAssertTrue(near(rgb(enabled, 8), [162, 228, 54], tolerance: 1),
                      "enabled Brite fill: \(rgb(enabled, 8))", file: file, line: line)
        XCTAssertTrue(near(rgb(disabled, 8), expectedDisabled, tolerance: 1),
                      "disabled Brite fill: \(rgb(disabled, 8))", file: file, line: line)
        let record = XCTAttachment(string:
            "Brite disabled expected=\(expectedDisabled) borderOuter=\(rgb(disabled, 0.5)) " +
            "borderInner=\(rgb(disabled, 1.5)) fill=\(rgb(disabled, 8)); " +
            "enabled border=\(rgb(enabled, 1.5)) fill=\(rgb(enabled, 8))")
        record.name = "v11-brite-measured-single-opacity"
        record.lifetime = .keepAlways
        add(record)
    }

    func testV12BriteHardButtonShadowDisabledAlphaAndTransparentLink() {
        let app = XCUIApplication(bundleIdentifier:
            "com.davidortinau.microsoftswiftui.appmainprobe20261003")
        app.launch()
        app.tabBars.buttons["Resources"].tap()
        app.buttons["probe.v12.open"].tap()

        let enabled = app.buttons["probe.v12.brite.enabled"]
        let disabled = app.buttons["probe.v12.brite.disabled"]
        let parentDisabled = app.buttons["probe.v12.brite.parent.disabled"]
        let outline = app.buttons["probe.v12.outline"]
        let link = app.buttons["probe.v12.link"]
        let scroll = app.scrollViews["probe.v12.screen"]
        XCTAssertTrue(enabled.waitForExistence(timeout: 10))
        for button in [enabled, disabled, parentDisabled, outline, link] {
            XCTAssertEqual(app.buttons.matching(identifier: button.identifier).count, 1)
            XCTAssertGreaterThanOrEqual(button.frame.height + 0.01, 44)
        }
        XCTAssertFalse(disabled.isEnabled)
        XCTAssertFalse(parentDisabled.isEnabled)
        let light = ScreenshotPixels(app: app)
        XCTAssertEqual(light.scale, 3, accuracy: 0.01)
        assertBriteComposite(light, enabled: enabled, disabled: disabled,
                             expectedDisabled: [194, 237, 124])
        assertV12Shadow(light, enabled, color: [0, 0, 0], background: [255, 255, 255])
        assertV12Shadow(light, disabled, color: [89, 89, 89], background: [255, 255, 255])
        assertV12Shadow(light, parentDisabled, color: [89, 89, 89],
                        background: [255, 255, 255])
        assertColor(light.color(at: CGPoint(x: outline.frame.maxX + 1.5,
                                            y: outline.frame.midY)),
                    [255, 255, 255], "source outline resets shadow", tolerance: 1)
        assertColor(light.color(at: CGPoint(x: link.frame.minX + 8, y: link.frame.midY)),
                    [255, 255, 255], "transparent link interior", tolerance: 1)
        assertV12Shadow(light, link, color: [0, 0, 0], background: [255, 255, 255])
        captureV9(app, "v12-brite-light-button-shadow-and-link")

        disabled.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.85)).tap()
        parentDisabled.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.85)).tap()
        XCTAssertTrue(app.staticTexts["No action"].exists)
        let originalLinkBounds = link.frame
        app.buttons["probe.v12.link.toggle"].tap()
        XCTAssertTrue(app.staticTexts["Link shadow off"].waitForExistence(timeout: 5))
        XCTAssertEqual(link.frame, originalLinkBounds)
        let noLinkShadow = ScreenshotPixels(app: app)
        assertColor(noLinkShadow.color(at: CGPoint(x: link.frame.maxX + 1.5,
                                                  y: link.frame.midY)),
                    [255, 255, 255], "opted-out link has no shadow", tolerance: 1)
        var largestInteriorDelta = 0
        let scale = Int(light.scale)
        for y in stride(from: Int((link.frame.minY + 4) * light.scale),
                        to: Int((link.frame.maxY - 4) * light.scale), by: scale) {
            for x in stride(from: Int((link.frame.minX + 4) * light.scale),
                            to: Int((link.frame.maxX - 4) * light.scale), by: scale) {
                largestInteriorDelta = max(largestInteriorDelta,
                    zip(light.color(x: x, y: y), noLinkShadow.color(x: x, y: y))
                        .map { abs($0.0 - $0.1) }.max() ?? 0)
            }
        }
        XCTAssertLessThanOrEqual(largestInteriorDelta, 1,
            "Shadow only changes outside the transparent Button; no text-glyph shadow copies")
        let record = XCTAttachment(string:
            "Link frame \(link.frame); interior RGB maximum delta \(largestInteriorDelta); " +
            "shadow is outside the real Button shape, not the underlined text glyphs.")
        record.name = "v12-transparent-link-no-glyph-shadow"
        record.lifetime = .keepAlways
        add(record)

        app.buttons["probe.v12.link.toggle"].tap()
        XCTAssertTrue(app.staticTexts["Link shadow on"].waitForExistence(timeout: 5))
        assertV12Shadow(ScreenshotPixels(app: app), link, color: [0, 0, 0],
                        background: [255, 255, 255])
        enabled.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.85)).tap()
        XCTAssertTrue(app.staticTexts["Shadow x0"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons.matching(identifier: "probe.v12.brite.enabled").count, 1)
        let onlyVertical = ScreenshotPixels(app: app)
        assertColor(onlyVertical.color(at: CGPoint(x: enabled.frame.maxX + 1.5,
                                                   y: enabled.frame.midY)),
                    [255, 255, 255], "mounted offset x0 leaves right edge clear", tolerance: 1)
        assertColor(onlyVertical.color(at: CGPoint(x: enabled.frame.midX,
                                                   y: enabled.frame.maxY + 1.5)),
                    [0, 0, 0], "existing vertical shadow remains", tolerance: 1)
        enabled.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.85)).tap()
        XCTAssertTrue(app.staticTexts["Shadow x3"].waitForExistence(timeout: 5))
        assertV12Shadow(ScreenshotPixels(app: app), enabled, color: [0, 0, 0],
                        background: [255, 255, 255])

        let theme = app.buttons["probe.v12.theme"]
        for _ in 0..<5 where !theme.isHittable { scroll.swipeUp() }
        theme.tap()
        XCTAssertTrue(app.staticTexts["Mode: Dark"].waitForExistence(timeout: 5))
        for _ in 0..<5 where !enabled.isHittable { scroll.swipeDown() }
        let dark = ScreenshotPixels(app: app)
        assertBriteComposite(dark, enabled: enabled, disabled: disabled,
                             expectedDisabled: [117, 161, 49])
        assertV12Shadow(dark, enabled, color: [0, 0, 0], background: [33, 37, 41])
        assertV12Shadow(dark, disabled, color: [12, 13, 14], background: [33, 37, 41])
        assertV12Shadow(dark, parentDisabled, color: [12, 13, 14],
                        background: [33, 37, 41])
        assertColor(dark.color(at: CGPoint(x: outline.frame.maxX + 1.5,
                                           y: outline.frame.midY)),
                    [33, 37, 41], "dark outline has no resting shadow", tolerance: 1)
        assertColor(dark.color(at: CGPoint(x: link.frame.minX + 8, y: link.frame.midY)),
                    [33, 37, 41], "dark link keeps clear fill", tolerance: 1)
        assertV12Shadow(dark, link, color: [0, 0, 0], background: [33, 37, 41])
        captureV9(app, "v12-brite-dark-button-shadow-and-link")
    }

    func testV12EllipticalShapeShadowAndOldSurfaceDefaultX() {
        let app = XCUIApplication(bundleIdentifier:
            "com.davidortinau.microsoftswiftui.appmainprobe20261003")
        app.launch()
        app.tabBars.buttons["Resources"].tap()
        app.buttons["probe.v12.open"].tap()
        let scroll = app.scrollViews["probe.v12.screen"]
        let ellipse = app.buttons["probe.v12.ellipse"]
        let surface = app.buttons["probe.v12.surface"]
        XCTAssertTrue(ellipse.waitForExistence(timeout: 10))
        for _ in 0..<5 where !surface.isHittable || surface.frame.maxY + 4 > scroll.frame.maxY {
            scroll.swipeUp()
        }
        XCTAssertTrue(surface.isHittable && ellipse.isHittable)
        XCTAssertEqual(app.buttons.matching(identifier: "probe.v12.ellipse").count, 1)
        XCTAssertEqual(app.buttons.matching(identifier: "probe.v12.surface").count, 1)
        XCTAssertGreaterThanOrEqual(ellipse.frame.height, 44)
        let pixels = ScreenshotPixels(app: app)
        XCTAssertEqual(pixels.scale, 3, accuracy: 0.01)
        assertColor(pixels.color(at: CGPoint(x: ellipse.frame.minX + 8, y: ellipse.frame.midY)),
                    [255, 255, 255], "elliptical transparent fill", tolerance: 1)
        assertColor(pixels.color(at: CGPoint(x: ellipse.frame.maxX + 1.5,
                                             y: ellipse.frame.midY)),
                    [0, 0, 0], "shadow follows ellipse near right center", tolerance: 1)
        assertColor(pixels.color(at: CGPoint(x: ellipse.frame.maxX + 2.5,
                                             y: ellipse.frame.minY + 4)),
                    [255, 255, 255], "no rectangular shadow at ellipse top-right", tolerance: 1)
        assertColor(pixels.color(at: CGPoint(x: surface.frame.maxX + 1.5,
                                             y: surface.frame.midY)),
                    [255, 255, 255], "old surface shadow x defaults to zero", tolerance: 1)
        assertColor(pixels.color(at: CGPoint(x: surface.frame.midX,
                                             y: surface.frame.maxY + 1.5)),
                    [0, 0, 0], "old surface shadow y remains three", tolerance: 1)
        captureV9(app, "v12-ellipse-shape-and-legacy-surface-shadow")
        ellipse.coordinate(withNormalizedOffset: CGVector(dx: 0.89, dy: 0.85)).tap()
        XCTAssertTrue(app.staticTexts["Ellipse tapped"].waitForExistence(timeout: 5))
        surface.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.85)).tap()
        XCTAssertTrue(app.staticTexts["Surface tapped"].waitForExistence(timeout: 5))
    }

    func testV13ClearStrokeReservesTheRealButtonsBorderBoxInBothModes() {
        let app = openV13Probe()
        let clear = app.buttons["probe.v13.link.clear"]
        let opaque = app.buttons["probe.v13.link.opaque"]
        let disabled = app.buttons["probe.v13.link.disabled"]
        let parentDisabled = app.buttons["probe.v13.link.parent.disabled"]
        XCTAssertTrue(clear.waitForExistence(timeout: 10))
        for button in [clear, opaque, disabled, parentDisabled] {
            XCTAssertEqual(app.buttons.matching(identifier: button.identifier).count, 1)
            XCTAssertGreaterThanOrEqual(button.frame.height + 0.01, 44)
            XCTAssertTrue(button.label.contains("Logout"))
        }
        XCTAssertFalse(disabled.isEnabled)
        XCTAssertFalse(parentDisabled.isEnabled)
        XCTAssertEqual(clear.frame.width - opaque.frame.width, 4, accuracy: 0.4)
        XCTAssertEqual(clear.frame.height - opaque.frame.height, 4, accuracy: 0.4)
        XCTAssertEqual(clear.frame.midX, app.windows.firstMatch.frame.midX, accuracy: 1)

        let light = ScreenshotPixels(app: app)
        XCTAssertEqual(light.scale, 3, accuracy: 0.01)
        assertColor(light.color(at: CGPoint(x: clear.frame.maxX - 0.7,
                                            y: clear.frame.midY)),
                    [255, 255, 255], "transparent 2pt right-edge stroke", tolerance: 2)
        assertColor(light.color(at: CGPoint(x: opaque.frame.maxX - 0.7,
                                            y: opaque.frame.midY)),
                    [0, 0, 0], "opaque reference inner stroke", tolerance: 8)
        captureV9(app, "v13-clear-stroke-2pt-border-box-light")
        disabled.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        parentDisabled.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.staticTexts["No action"].exists)
        clear.coordinate(withNormalizedOffset: CGVector(dx: 0.88, dy: 0.75)).tap()
        XCTAssertTrue(app.staticTexts["Link tapped"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons.matching(identifier: "probe.v13.link.clear").count, 1)

        let scroll = app.scrollViews["probe.v13.screen"]
        let theme = app.buttons["probe.v13.theme"]
        for _ in 0..<5 where !theme.isHittable { scroll.swipeUp() }
        theme.tap()
        XCTAssertTrue(app.staticTexts["Mode: Dark"].waitForExistence(timeout: 5))
        for _ in 0..<5 where !clear.isHittable { scroll.swipeDown() }
        XCTAssertEqual(clear.frame.width - opaque.frame.width, 4, accuracy: 0.4)
        XCTAssertEqual(clear.frame.height - opaque.frame.height, 4, accuracy: 0.4)
        let dark = ScreenshotPixels(app: app)
        assertColor(dark.color(at: CGPoint(x: clear.frame.maxX - 0.7,
                                           y: clear.frame.midY)),
                    [33, 37, 41], "dark transparent stroke shows the actual parent", tolerance: 2)
        assertColor(dark.color(at: CGPoint(x: opaque.frame.maxX - 0.7,
                                           y: opaque.frame.midY)),
                    [255, 255, 255], "dark opaque reference stroke", tolerance: 8)
        captureV9(app, "v13-clear-stroke-2pt-border-box-dark")
    }

    func testV13SelectedButtonOwnsTheExactTwoPointSeamAndWrappedSixKeepOrder() {
        let app = openV13Probe()
        let first = app.buttons["probe.v13.joined.first"]
        let second = app.buttons["probe.v13.joined.second"]
        XCTAssertTrue(first.waitForExistence(timeout: 10))
        XCTAssertEqual(app.buttons.matching(identifier: "probe.v13.joined.first").count, 1)
        XCTAssertEqual(app.buttons.matching(identifier: "probe.v13.joined.second").count, 1)
        XCTAssertGreaterThanOrEqual(first.frame.height, 44)
        XCTAssertGreaterThanOrEqual(second.frame.height, 44)
        XCTAssertEqual(first.frame.maxX - second.frame.minX, 2, accuracy: 0.35)
        let seam = first.coordinate(withNormalizedOffset: CGVector(dx: 1, dy: 0.5))
            .withOffset(CGVector(dx: -1, dy: 0))
        seam.tap()
        XCTAssertTrue(app.staticTexts["First seam"].waitForExistence(timeout: 5))
        captureV9(app, "v13-joined-selected-first-seam")
        app.buttons["probe.v13.joined.select.second"].tap()
        XCTAssertTrue(app.staticTexts["Selected: Second"].waitForExistence(timeout: 5))
        XCTAssertEqual(first.frame.maxX - second.frame.minX, 2, accuracy: 0.35)
        seam.tap()
        XCTAssertTrue(app.staticTexts["Second seam"].waitForExistence(timeout: 5))
        captureV9(app, "v13-joined-selected-second-seam")

        let choices = (0..<6).map { app.buttons["probe.v13.choice.\($0)"] }
        let scroll = app.scrollViews["probe.v13.screen"]
        for _ in 0..<5 where !choices[0].isHittable { scroll.swipeUp() }
        for (index, button) in choices.enumerated() {
            XCTAssertTrue(button.exists, "original group child \(index)")
            XCTAssertEqual(app.buttons.matching(identifier: button.identifier).count, 1)
            XCTAssertGreaterThanOrEqual(button.frame.height, 44)
        }
        func rows() -> Set<Int> {
            Set(choices.map { Int(round($0.frame.minY)) })
        }
        func assertAccessibleChildrenAndVisualOrder() {
            let accessible = app.otherElements["probe.v13.choices"]
                .descendants(matching: .button)
                .matching(NSPredicate(format: "identifier BEGINSWITH %@",
                                      "probe.v13.choice."))
                .allElementsBoundByIndex.map(\.identifier)
            let expected = (0..<6).map { "probe.v13.choice.\($0)" }
            XCTAssertEqual(accessible.count, 6)
            XCTAssertEqual(Set(accessible), Set(expected))
            for index in 1..<choices.count {
                let previous = choices[index - 1].frame
                let current = choices[index].frame
                XCTAssertGreaterThanOrEqual(current.minY + 0.5, previous.minY)
                if abs(current.minY - previous.minY) < 0.5 {
                    XCTAssertEqual(previous.maxX - current.minX, 2, accuracy: 0.35)
                } else {
                    XCTAssertEqual(current.minX, choices[0].frame.minX - 2, accuracy: 0.35)
                }
            }
        }
        let wideRows = rows()
        XCTAssertGreaterThan(wideRows.count, 2,
                             "intrinsic widths must produce more than a fixed 3+3 grid")
        assertAccessibleChildrenAndVisualOrder()
        captureV9(app, "v13-six-intrinsic-buttons-320pt")
        let contraction = app.buttons["probe.v13.width"]
        for _ in 0..<5 where !contraction.isHittable { scroll.swipeUp() }
        contraction.tap()
        XCTAssertTrue(app.staticTexts["Width: 195"].waitForExistence(timeout: 5))
        let narrowRows = rows()
        XCTAssertGreaterThan(narrowRows.count, wideRows.count)
        XCTAssertEqual(choices.map(\.identifier), (0..<6).map { "probe.v13.choice.\($0)" })
        XCTAssertEqual(app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "probe.v13.choice.")).count, 6)
        assertAccessibleChildrenAndVisualOrder()
        captureV9(app, "v13-six-intrinsic-buttons-195pt")
        let localized = app.buttons["probe.v13.locale"]
        for _ in 0..<5 where !localized.isHittable { scroll.swipeUp() }
        localized.tap()
        XCTAssertTrue(app.staticTexts["Label expanded"].waitForExistence(timeout: 5))
        XCTAssertTrue(choices[3].label.contains("längerer"))
        XCTAssertEqual(app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "probe.v13.choice.")).count, 6)
        assertAccessibleChildrenAndVisualOrder()
        captureV9(app, "v13-six-buttons-localized-in-place")
    }

    func testV15OnePointGroupFills378WithoutEqualizingTheOriginalButtons() {
        let app = openV13Probe()
        let scroll = app.scrollViews["probe.v13.screen"]
        let first = app.buttons["probe.v15.group.first"]
        let second = app.buttons["probe.v15.group.second"]
        let status = app.staticTexts["probe.v15.status"]
        for _ in 0..<6 where !first.isHittable { scroll.swipeUp() }
        XCTAssertTrue(first.waitForExistence(timeout: 10))
        XCTAssertTrue(second.exists)
        XCTAssertTrue(status.exists)
        XCTAssertEqual(app.staticTexts["probe.v15.guards"].label, "Group guards passed")
        XCTAssertEqual(app.buttons.matching(identifier: first.identifier).count, 1)
        XCTAssertEqual(app.buttons.matching(identifier: second.identifier).count, 1)
        XCTAssertEqual(first.elementType, .button)
        XCTAssertEqual(second.elementType, .button)
        XCTAssertEqual(app.windows.firstMatch.frame.width, 402, accuracy: 1)
        XCTAssertEqual(first.frame.minX, 12, accuracy: 0.6)
        XCTAssertEqual(first.frame.maxX - second.frame.minX, 1, accuracy: 0.35)
        XCTAssertLessThan(second.frame.maxX, 380,
                          "the intrinsic Resources pair must not silently fill the row")
        let firstIntrinsic = first.frame.width
        let secondIntrinsic = second.frame.width
        XCTAssertGreaterThan(secondIntrinsic, firstIntrinsic + 5)
        captureV9(app, "v15-intrinsic-one-point-source-pair")

        let seam = first.coordinate(withNormalizedOffset: CGVector(dx: 1, dy: 0.5))
            .withOffset(CGVector(dx: -0.5, dy: 0))
        seam.tap()
        XCTAssertEqual(status.label, "Source: Today (1)")
        second.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertEqual(status.label, "Source: Choose Your Own (1)")
        seam.tap()
        XCTAssertEqual(status.label, "Source: Choose Your Own (2)")

        let fill = app.buttons["probe.v15.fill"]
        for _ in 0..<4 where !fill.isHittable { scroll.swipeUp() }
        fill.tap()
        XCTAssertEqual(status.label, "Source group: Filled")
        XCTAssertEqual(first.frame.minX, 12, accuracy: 0.6)
        XCTAssertEqual(second.frame.maxX, 390, accuracy: 0.6)
        XCTAssertEqual(first.frame.maxX - second.frame.minX, 1, accuracy: 0.35)
        XCTAssertEqual(first.frame.width + second.frame.width - 1, 378, accuracy: 0.6)
        XCTAssertEqual(first.frame.width - firstIntrinsic,
                       second.frame.width - secondIntrinsic, accuracy: 0.7,
                       "positive surplus adds equally to unequal intrinsic bases")
        XCTAssertEqual(second.frame.width - first.frame.width,
                       secondIntrinsic - firstIntrinsic, accuracy: 0.7)
        XCTAssertGreaterThanOrEqual(first.frame.height, 44)
        XCTAssertGreaterThanOrEqual(second.frame.height, 44)
        XCTAssertEqual(app.buttons.matching(identifier: first.identifier).count, 1)
        XCTAssertEqual(app.buttons.matching(identifier: second.identifier).count, 1)
        seam.tap()
        XCTAssertEqual(status.label, "Source: Choose Your Own (3)")
        captureV9(app, "v15-filled-378-one-point-source-pair")
    }

    func testV15GroupQueryBindingOrdersDoNotClaimVoiceOverTraversal() {
        let app = openV13Probe()
        let first = app.buttons["probe.v13.joined.first"]
        let second = app.buttons["probe.v13.joined.second"]
        let group = app.otherElements["probe.v13.joined"]
        XCTAssertTrue(group.waitForExistence(timeout: 10))
        let buttons = group.descendants(matching: .button)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@",
                                  "probe.v13.joined."))
        let expected = Set(["probe.v13.joined.first", "probe.v13.joined.second"])

        func observe(_ phase: String) {
            let indexed = buttons.allElementsBoundByIndex.map(\.identifier)
            let boundToAccessibility = buttons.allElementsBoundByAccessibilityElement
                .map(\.identifier)
            XCTAssertEqual(indexed.count, 2)
            XCTAssertEqual(boundToAccessibility.count, 2)
            XCTAssertEqual(Set(indexed), expected)
            XCTAssertEqual(Set(boundToAccessibility), expected)
            XCTAssertEqual(first.elementType, .button)
            XCTAssertEqual(second.elementType, .button)
            XCTAssertEqual(first.frame.maxX - second.frame.minX, 2, accuracy: 0.35)
            print("BridgeGroupAXQuery phase=\(phase) indexed=\(indexed) "
                  + "boundToAccessibility=\(boundToAccessibility)")
        }

        observe("selected-first")
        let selectSecond = app.buttons["probe.v13.joined.select.second"]
        let scroll = app.scrollViews["probe.v13.screen"]
        for _ in 0..<4 where !selectSecond.isHittable { scroll.swipeUp() }
        selectSecond.tap()
        XCTAssertTrue(app.staticTexts["Selected: Second"].waitForExistence(timeout: 5))
        observe("selected-second")
    }

    func testV13ButtonGroupReflowsForAccessibilityXLWithoutReplacingChildren() {
        let app = openV13Probe(accessibilityXL: true)
        let choices = (0..<6).map { app.buttons["probe.v13.choice.\($0)"] }
        let scroll = app.scrollViews["probe.v13.screen"]
        for _ in 0..<6 where !choices[0].isHittable { scroll.swipeUp() }
        XCTAssertTrue(choices[0].waitForExistence(timeout: 10))
        let viewport = app.staticTexts["probe.v13.viewport"]
        XCTAssertTrue(viewport.waitForExistence(timeout: 5))
        XCTAssertTrue(viewport.label.contains("Type: Accessibility"))
        let originalRows = Set(choices.map { Int(round($0.frame.minY)) })
        XCTAssertGreaterThan(originalRows.count, 1)
        captureV9(app, "v13-six-intrinsic-buttons-xl-320pt")
        let contraction = app.buttons["probe.v13.width"]
        for _ in 0..<6 where !contraction.isHittable { scroll.swipeUp() }
        contraction.tap()
        XCTAssertTrue(app.staticTexts["Width: 195"].waitForExistence(timeout: 5))
        XCTAssertTrue(viewport.label.contains("Type: Accessibility"))
        let contractedRows = Set(choices.map { Int(round($0.frame.minY)) })
        XCTAssertGreaterThan(contractedRows.count, originalRows.count)
        for (index, button) in choices.enumerated() {
            XCTAssertEqual(app.buttons.matching(identifier: button.identifier).count, 1,
                           "original child identity \(index) at XL")
            XCTAssertGreaterThanOrEqual(button.frame.height, 44)
        }
        let accessible = app.otherElements["probe.v13.choices"]
            .descendants(matching: .button)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@",
                                  "probe.v13.choice."))
            .allElementsBoundByIndex.map(\.identifier)
        XCTAssertEqual(accessible.count, 6)
        XCTAssertEqual(Set(accessible),
                       Set((0..<6).map { "probe.v13.choice.\($0)" }))
        captureV9(app, "v13-six-intrinsic-buttons-xl-195pt")
    }

    private func openV13Probe(accessibilityXL: Bool = false) -> XCUIApplication {
        let app = XCUIApplication(bundleIdentifier:
            "com.davidortinau.microsoftswiftui.appmainprobe20261003")
        if accessibilityXL {
            app.launchArguments += [
                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityM"
            ]
        }
        app.launch()
        app.tabBars.buttons["Resources"].tap()
        let open = app.buttons["probe.v13.open"]
        for _ in 0..<4 where !open.isHittable { app.swipeUp() }
        XCTAssertTrue(open.waitForExistence(timeout: 10))
        open.tap()
        XCTAssertTrue(app.scrollViews["probe.v13.screen"].waitForExistence(timeout: 10))
        return app
    }

    private func assertV12Shadow(_ pixels: ScreenshotPixels, _ button: XCUIElement,
                                 color: [Int], background: [Int],
                                 file: StaticString = #filePath, line: UInt = #line) {
        for offset in [CGFloat(0.5), 1.5] {
            assertColor(pixels.color(at: CGPoint(x: button.frame.maxX + offset,
                                                 y: button.frame.midY)), color,
                        "right shadow at \(offset)pt", tolerance: 2, file: file, line: line)
            assertColor(pixels.color(at: CGPoint(x: button.frame.midX,
                                                 y: button.frame.maxY + offset)), color,
                        "bottom shadow at \(offset)pt", tolerance: 2, file: file, line: line)
        }
        // The last device pixel can be partially covered by the zero-blur shape edge.
        for edge in [
            pixels.color(at: CGPoint(x: button.frame.maxX + 2.5, y: button.frame.midY)),
            pixels.color(at: CGPoint(x: button.frame.midX, y: button.frame.maxY + 2.5))
        ] {
            for channel in 0..<3 {
                let fringe = Int(ceil(Double(abs(background[channel] - color[channel])) / 8)) + 2
                XCTAssertLessThanOrEqual(abs(edge[channel] - color[channel]), fringe,
                    "last shadow pixel remains predominantly shadow-colored: \(edge)",
                    file: file, line: line)
            }
        }
        assertColor(pixels.color(at: CGPoint(x: button.frame.maxX + 3.5,
                                             y: button.frame.midY)), background,
                    "shadow stops after three points", tolerance: 2, file: file, line: line)
        assertColor(pixels.color(at: CGPoint(x: button.frame.minX - 1.5,
                                             y: button.frame.midY)), background,
                    "no left shadow", tolerance: 2, file: file, line: line)
        assertColor(pixels.color(at: CGPoint(x: button.frame.midX,
                                             y: button.frame.minY - 1.5)), background,
                    "no upper shadow", tolerance: 2, file: file, line: line)
    }

    func testV9FixedCircleAndUnderlinedButtonAtNormalSize() {
        checkV9CircleAndLink(accessibilityXL: false)
    }

    func testV9FixedCircleAndUnderlinedButtonAtAccessibilityXL() {
        checkV9CircleAndLink(accessibilityXL: true)
    }

    private func checkV9CircleAndLink(accessibilityXL: Bool) {
        let app = XCUIApplication(bundleIdentifier:
            "com.davidortinau.microsoftswiftui.appmainprobe20261003")
        if accessibilityXL {
            app.launchArguments += [
                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityM"
            ]
        }
        app.launch()
        app.tabBars.buttons["Resources"].tap()
        app.buttons["probe.v9.open"].tap()
        app.buttons["probe.v9.theme"].tap()
        XCTAssertTrue(app.staticTexts["Mode: Light"].waitForExistence(timeout: 5))

        let selected = app.descendants(matching: .any)["probe.v9.step"].firstMatch
        XCTAssertTrue(selected.waitForExistence(timeout: 10))
        XCTAssertEqual(selected.label, "Step 3 of 6")
        XCTAssertEqual(app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", "of 6")).count, 1)
        XCTAssertEqual(selected.frame.width, 8, accuracy: 0.25)
        XCTAssertEqual(selected.frame.height, 8, accuracy: 0.25)
        XCTAssertEqual(app.windows.firstMatch.frame.width, 402, accuracy: 1)
        XCTAssertEqual(selected.frame.minX, app.windows.firstMatch.frame.midX - 10,
                       accuracy: 1)

        let pixels = ScreenshotPixels(app: app)
        let middleY = Int(selected.frame.midY * pixels.scale)
        let midX = app.windows.firstMatch.frame.midX
        let left = Int((midX - 45) * pixels.scale)
        let right = Int((midX + 45) * pixels.scale)
        var runs: [ClosedRange<Int>] = []
        var start: Int?
        for x in left..<right {
            let color = pixels.color(x: x, y: middleY)
            let dot = near(color, [44, 62, 80]) || near(color, [160, 160, 160])
            if dot && start == nil { start = x }
            if !dot, let first = start {
                runs.append(first...(x - 1))
                start = nil
            }
        }
        if let first = start { runs.append(first...(right - 1)) }
        XCTAssertEqual(runs.count, 6, "Six native circles at the selected dot's center: \(runs)")
        if runs.count == 6 {
            for run in runs {
                XCTAssertEqual(CGFloat(run.count) / pixels.scale, 8, accuracy: 1,
                               "Circle diameter: \(run)")
            }
            for index in 1..<runs.count {
                XCTAssertEqual(CGFloat(runs[index].lowerBound - runs[index - 1].lowerBound)
                    / pixels.scale, 12, accuracy: 0.6, "Dot gap at \(index)")
            }
            XCTAssertEqual(CGFloat(runs.last!.upperBound - runs.first!.lowerBound + 1)
                / pixels.scale, 68, accuracy: 1)
            XCTAssertEqual(CGFloat(runs.first!.lowerBound + runs.last!.upperBound + 1)
                / (2 * pixels.scale), midX, accuracy: 1)
        }

        let link = app.buttons["probe.v9.logout"]
        XCTAssertTrue(link.exists)
        XCTAssertEqual(app.buttons.matching(identifier: "probe.v9.logout").count, 1)
        XCTAssertGreaterThanOrEqual(link.frame.height, 44)
        let before = ScreenshotPixels(app: app)
        captureV9(app, accessibilityXL ? "v9-xl-dots-underlined" : "v9-normal-dots-underlined")
        app.buttons["probe.v9.underline.off"].tap()
        XCTAssertTrue(app.staticTexts["Underline off"].waitForExistence(timeout: 5))
        let after = ScreenshotPixels(app: app)
        let bounds = link.frame
        var changed = 0
        for y in Int(bounds.minY * before.scale)..<Int(bounds.maxY * before.scale) {
            for x in Int(bounds.minX * before.scale)..<Int(bounds.maxX * before.scale) {
                if before.color(x: x, y: y) != after.color(x: x, y: y) {
                    changed += 1
                }
            }
        }
        XCTAssertGreaterThan(changed, 5, "Native Text underline changed \(changed) pixels")
        XCTAssertGreaterThanOrEqual(link.frame.height, 44)
        link.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.85)).tap()
        XCTAssertTrue(app.staticTexts["Logout tapped"].waitForExistence(timeout: 5))
        captureV9(app, accessibilityXL ? "v9-xl-logout-hit" : "v9-normal-logout-hit")
    }

    func testP16RealPhotoSheetSubmitSpinnerAndCompletedCard() {
        let app = openP16()
        let window = app.windows.firstMatch
        XCTAssertTrue(app.activityIndicators["probe.p16.spinner"].exists)
        let divider = app.descendants(matching: .any)["probe.p16.divider"].firstMatch
        XCTAssertTrue(divider.exists)
        XCTAssertGreaterThan(divider.frame.width, 250)
        XCTAssertLessThanOrEqual(divider.frame.height, 2)
        let completed = app.buttons["probe.p16.completed"]
        XCTAssertTrue(completed.exists)
        completed.tap()
        XCTAssertTrue(app.staticTexts["Completed card tapped"].waitForExistence(timeout: 5))

        let answer = app.textFields["probe.p16.quiz.answer"]
        XCTAssertTrue(answer.exists)
        answer.tap()
        answer.typeText("target\n")
        XCTAssertTrue(app.staticTexts["Answer submitted: 1"].waitForExistence(timeout: 5))
        let correction = app.buttons["probe.p16.quiz.correct"]
        for _ in 0..<4 where !correction.isHittable { app.swipeUp() }
        XCTAssertTrue(correction.isHittable)
        correction.tap()
        XCTAssertEqual(app.textFields.matching(identifier: "probe.p16.quiz.answer").count, 1)
        answer.typeText("correct\n")
        XCTAssertTrue(app.staticTexts["Correction submitted: 2"].waitForExistence(timeout: 5))
        captureV9(app, "p16-same-focused-field-correction")

        let info = app.buttons["probe.p16.details.open"]
        for _ in 0..<5 where !info.isHittable { app.swipeUp() }
        XCTAssertTrue(info.isHittable)
        XCTAssertTrue(app.staticTexts["Photo displayed"].waitForExistence(timeout: 10))
        info.tap()
        let heading = app.staticTexts["probe.p16.details.heading"]
        XCTAssertTrue(heading.waitForExistence(timeout: 5))
        let detailsScroll = app.scrollViews["probe.p16.details.scroll"]
        XCTAssertTrue(detailsScroll.exists)
        XCTAssertLessThanOrEqual(detailsScroll.frame.height, window.frame.height * 0.75)
        captureV9(app, "p16-70-percent-learning-details")
        app.buttons["probe.p16.details.close"].tap()
        XCTAssertTrue(app.staticTexts["Details dismissed"].waitForExistence(timeout: 5))

        let bad = app.buttons["probe.p16.photo.bad"]
        for _ in 0..<4 where !bad.isHittable { app.swipeUp() }
        XCTAssertTrue(bad.isHittable)
        bad.tap()
        XCTAssertTrue(app.staticTexts["Photo failed: decodeFailed"]
            .waitForExistence(timeout: 5))
        let openPhoto = app.buttons["probe.p16.photo.open"]
        for _ in 0..<5 where !openPhoto.isHittable { app.swipeUp() }
        XCTAssertTrue(openPhoto.isHittable)
        openPhoto.tap()
        let close = app.buttons["probe.p16.photo.close"]
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        XCTAssertTrue(close.isHittable)
        let image = app.images["probe.p16.photo.fullscreen"]
        XCTAssertTrue(image.exists)
        let fitted = ScreenshotPixels(app: app)
        let center = fitted.color(at: CGPoint(x: window.frame.midX, y: window.frame.midY))
        let outside = fitted.color(at: CGPoint(x: window.frame.midX, y: 150))
        XCTAssertTrue(center[2] > 130 && center[1] > center[0] + 40,
                      "The actual decoded photo should occupy the centered fitted area.")
        XCTAssertTrue(outside.allSatisfy { $0 < 50 },
                      "The square photo should not stretch into the full-height viewer.")
        captureV9(app, "p16-fullscreen-photo-aspect-fit")
        image.pinch(withScale: 2.5, velocity: 1)
        image.coordinate(withNormalizedOffset: CGVector(dx: 0.4, dy: 0.5))
            .press(forDuration: 0.1,
                   thenDragTo: image.coordinate(withNormalizedOffset:
                       CGVector(dx: 0.68, dy: 0.55)))
        captureV9(app, "p16-real-fullscreen-photo")
        close.tap()
        XCTAssertTrue(app.staticTexts["Photo dismissed"].waitForExistence(timeout: 5))
        openPhoto.tap()
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        app.windows.firstMatch.coordinate(withNormalizedOffset:
            CGVector(dx: 0.01, dy: 0.5)).tap()
        XCTAssertTrue(app.staticTexts["Photo dismissed"].waitForExistence(timeout: 5))
    }

    func testP16AnchoredQuickAddArrowSelectionOutsideAndTap() {
        let app = openP16()
        let field = app.textFields["probe.p16.quick.field"]
        for _ in 0..<5 where !field.isHittable { app.swipeUp() }
        XCTAssertTrue(field.isHittable)
        field.tap()
        field.typeText("word")
        let first = app.buttons["probe.p16.quick.option.0"]
        let last = app.buttons["probe.p16.quick.option.2"]
        XCTAssertTrue(first.waitForExistence(timeout: 5))
        XCTAssertTrue(last.exists)
        XCTAssertGreaterThanOrEqual(first.frame.minY, field.frame.maxY - 3)
        XCTAssertLessThanOrEqual(last.frame.maxY - field.frame.maxY, 288)
        XCTAssertTrue(app.scrollViews["probe.p16.quick.listbox.scroll"].exists)
        let below = app.staticTexts["probe.p16.quick.row-below"]
        XCTAssertTrue(below.exists)
        XCTAssertTrue(first.isHittable)
        captureV9(app, "p16-anchored-quick-add")

        field.typeKey(XCUIKeyboardKey.downArrow, modifierFlags: [])
        XCTAssertTrue(app.staticTexts["Highlighted: 0"].waitForExistence(timeout: 5))
        XCTAssertTrue(first.isSelected)
        field.typeKey(XCUIKeyboardKey.upArrow, modifierFlags: [])
        XCTAssertTrue(app.staticTexts["Highlighted: 2"].waitForExistence(timeout: 5))
        XCTAssertTrue(last.isSelected)
        let popupScroll = app.scrollViews["probe.p16.quick.listbox.scroll"]
        XCTAssertLessThanOrEqual(popupScroll.frame.height, 288)
        XCTAssertGreaterThanOrEqual(last.frame.minY, popupScroll.frame.minY - 2)
        XCTAssertLessThanOrEqual(last.frame.maxY, popupScroll.frame.maxY + 2)
        let selectedPixels = ScreenshotPixels(app: app)
        let visibleOption = selectedPixels.color(at:
            CGPoint(x: last.frame.minX + 300, y: last.frame.midY))
        XCTAssertTrue(visibleOption[2] > 200 &&
                      visibleOption[2] > visibleOption[0] + 80,
                      "The highlighted option must be visually visible above the keyboard.")
        print("Quick Add selected option before scrolling: \(last.frame); list \(popupScroll.frame)")
        captureV9(app, "p16-quick-add-selected-last-before-scroll")
        for _ in 0..<3 where !last.isHittable { popupScroll.swipeUp() }
        print("Quick Add selected option after scrolling: \(last.frame); list \(popupScroll.frame)")
        captureV9(app, "p16-quick-add-selected-last-after-scroll")
        XCTAssertTrue(last.isHittable,
                      "The selected option must remain visible above the focused keyboard.")
        last.tap()
        let chosen = app.staticTexts["Chosen: 2, count: 1"]
        XCTAssertTrue(chosen.waitForExistence(timeout: 3))
        XCTAssertFalse(first.exists)
        field.tap()
        field.typeText("again")
        XCTAssertTrue(first.waitForExistence(timeout: 5))
        app.staticTexts["probe.p16.quick.status"].tap()
        XCTAssertFalse(first.waitForExistence(timeout: 3),
                       "Tapping outside must dismiss focused Quick Add.")
        XCTAssertTrue(app.staticTexts["Suggestions dismissed"].exists)
        captureV9(app, "p16-quick-add-keyboard-cancel")
    }

    func testP17RetainedQuickAddBackKeepsTheSceneResponsive() {
        let app = openP16()
        let back = app.navigationBars.buttons["BackButton"]
        XCTAssertTrue(back.waitForExistence(timeout: 5))
        back.tap()
        let open = app.buttons["probe.p16.open"]
        XCTAssertTrue(open.waitForExistence(timeout: 5))
        open.tap()
        XCTAssertTrue(app.navigationBars["Four-screen bridge"].waitForExistence(timeout: 5))

        let field = app.textFields["probe.p16.quick.field"]
        for _ in 0..<5 where !field.isHittable { app.swipeUp() }
        XCTAssertTrue(field.isHittable)
        field.tap()
        field.typeText("word")
        XCTAssertTrue(app.buttons["probe.p16.quick.option.0"].waitForExistence(timeout: 5))
        back.tap()
        XCTAssertTrue(open.waitForExistence(timeout: 5))
        open.tap()
        XCTAssertTrue(app.navigationBars["Four-screen bridge"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["probe.p16.completed"].exists)
        captureV9(app, "p17-quick-add-retained-back-and-reopen")
    }

    func testP17TextEditorPlaceholderUsesTheSameFocusedEditor() {
        let app = openP16()
        let editor = app.textViews["probe.p17.sentence.input"]
        for _ in 0..<8 where !editor.isHittable { app.swipeUp() }
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        XCTAssertTrue(editor.isHittable)
        XCTAssertEqual(app.descendants(matching: .any)
            .matching(identifier: "probe.p17.sentence.input").count, 1)
        XCTAssertFalse(app.staticTexts["Write a sentence with the target word"].exists)
        captureV9(app, "p17-sentence-editor-empty-placeholder")

        editor.tap()
        captureV9(app, "p17-sentence-editor-focused-empty-placeholder")
        editor.typeText("word")
        XCTAssertTrue(app.staticTexts["Sentence length: 4"].waitForExistence(timeout: 5))
        captureV9(app, "p17-sentence-editor-typed-no-placeholder")
        editor.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 4))
        XCTAssertTrue(app.staticTexts["Sentence empty"].waitForExistence(timeout: 5))
        captureV9(app, "p17-sentence-editor-focused-cleared-placeholder")
    }

    func testP18HorizontalGridSharesColumnsAndKeepsInputFocusAfterRowRemoval() {
        let app = openP18()
        let scroll = app.scrollViews["probe.p18.grid"]
        XCTAssertTrue(scroll.waitForExistence(timeout: 10))
        let headerTarget = app.staticTexts["probe.p18.header.target"]
        let headerType = app.staticTexts["probe.p18.header.type"]
        let headerTags = app.staticTexts["probe.p18.header.tags"]
        let targetA = app.textFields["probe.p18.target.a"]
        let targetB = app.textFields["probe.p18.target.b"]
        XCTAssertTrue(headerTarget.exists && headerType.exists && headerTags.exists)
        XCTAssertTrue(targetA.exists && targetB.exists)
        XCTAssertEqual(targetA.frame.minX, targetB.frame.minX, accuracy: 3)
        XCTAssertEqual(headerTarget.frame.minX, targetA.frame.minX, accuracy: 3)
        XCTAssertGreaterThanOrEqual(headerTags.frame.minX - headerType.frame.minX, 118)
        XCTAssertLessThan(scroll.frame.width, app.windows.firstMatch.frame.width)
        captureV9(app, "p18-grid-aligned-phone-left")

        let removeA = app.buttons["probe.p18.remove.a"]
        XCTAssertFalse(removeA.isHittable)
        scroll.swipeLeft()
        XCTAssertTrue(removeA.isHittable)
        XCTAssertTrue(app.staticTexts["probe.p18.header.remove"].isHittable)
        captureV9(app, "p18-grid-horizontal-pan-right")

        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        XCTAssertTrue(app.navigationBars["Horizontal grid"].waitForExistence(timeout: 5))
        XCTAssertGreaterThan(scroll.frame.width, 600)
        let form = app.collectionViews.firstMatch
        XCTAssertTrue(form.exists)
        for _ in 0..<4 where scroll.frame.maxY > app.windows.firstMatch.frame.maxY - 12 {
            form.swipeUp()
        }
        XCTAssertTrue(scroll.isHittable)
        XCTAssertLessThanOrEqual(scroll.frame.maxY, app.windows.firstMatch.frame.maxY)
        scroll.swipeRight()
        XCTAssertTrue(targetA.isHittable)
        XCTAssertTrue(removeA.isHittable)
        captureV9(app, "p18-grid-wide-single-row-columns")

        let kindB = app.buttons["probe.p18.kind.b"]
        XCTAssertTrue(kindB.exists)
        kindB.tap()
        app.buttons["Phrase"].tap()
        XCTAssertTrue(app.staticTexts["Type B: Phrase"].waitForExistence(timeout: 5))

        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(targetB.isHittable)
        targetB.tap()
        targetB.typeText("!")
        XCTAssertTrue(app.staticTexts["Rows: 1"].waitForExistence(timeout: 5))
        XCTAssertFalse(targetA.exists)
        XCTAssertTrue(targetB.exists)
        XCTAssertEqual(targetB.value as? String, "good afternoon!")
        XCTAssertTrue(app.staticTexts["Focus B: yes"].exists)
        targetB.typeText("?")
        XCTAssertTrue(app.staticTexts["Input B: good afternoon!?"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Type B: Phrase"].exists)
        captureV9(app, "p18-grid-removed-row-retained-focused-input-and-picker")
    }

    func testP18StyledMenuPickerBorderEdgesOpenTheNativeMenu() {
        let app = openP18()
        let picker = app.buttons["probe.p18.kind.a"]
        let typeHeader = app.staticTexts["probe.p18.header.type"]
        let tagsHeader = app.staticTexts["probe.p18.header.tags"]
        XCTAssertTrue(picker.waitForExistence(timeout: 10))
        XCTAssertTrue(typeHeader.exists && tagsHeader.exists)
        let window = app.windows.firstMatch.frame
        let left = CGPoint(x: typeHeader.frame.minX + 7, y: picker.frame.midY)
        let right = CGPoint(x: tagsHeader.frame.minX - 12 - 7, y: picker.frame.midY)
        XCTAssertGreaterThanOrEqual(picker.frame.width, 118)
        XCTAssertGreaterThan(right.x - left.x, 100)
        captureV9(app, "p18-styled-menu-picker-before-edge-tap")

        func tap(_ point: CGPoint) {
            app.windows.firstMatch.coordinate(withNormalizedOffset:
                CGVector(dx: point.x / window.width, dy: point.y / window.height)).tap()
        }

        tap(left)
        let leftOpened = app.buttons["Phrase"].waitForExistence(timeout: 2)
        captureV9(app, "p18-styled-menu-picker-left-edge")
        if leftOpened { app.buttons["Word"].tap() }
        XCTAssertTrue(leftOpened, "The real Picker must respond 7pt inside its left border.")

        picker.tap()
        XCTAssertTrue(app.buttons["Phrase"].waitForExistence(timeout: 5))
        app.buttons["Phrase"].tap()
        XCTAssertTrue(app.staticTexts["Type A: Phrase"].waitForExistence(timeout: 5))
        captureV9(app, "p18-styled-menu-picker-center-selects")

        tap(right)
        let rightOpened = app.buttons["Sentence"].waitForExistence(timeout: 2)
        captureV9(app, "p18-styled-menu-picker-right-edge")
        if rightOpened { app.buttons["Sentence"].tap() }
        XCTAssertTrue(rightOpened, "The real Picker must respond 7pt inside its right border.")
        if rightOpened {
            XCTAssertTrue(app.staticTexts["Type A: Sentence"].waitForExistence(timeout: 5))
        }

        tap(left)
        XCTAssertTrue(app.buttons["Word"].waitForExistence(timeout: 5))
        app.windows.firstMatch.coordinate(withNormalizedOffset:
            CGVector(dx: 0.05, dy: 0.37)).tap()
        XCTAssertFalse(app.buttons["Word"].exists)

        let targetB = app.textFields["probe.p18.target.b"]
        targetB.tap()
        targetB.typeText("!")
        XCTAssertTrue(app.staticTexts["Rows: 1"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Focus B: yes"].exists)
        targetB.typeText("?")
        XCTAssertEqual(targetB.value as? String, "good afternoon!?")
        captureV9(app, "picker-hit-focused-row-after-native-menu-dismiss")

        app.navigationBars.buttons["BackButton"].tap()
        XCTAssertTrue(app.buttons["probe.p18.open"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Account"].tap()
        let naturalPicker = app.buttons["probe.language"]
        XCTAssertTrue(naturalPicker.waitForExistence(timeout: 5))
        naturalPicker.tap()
        let korean = app.buttons["Korean"]
        XCTAssertTrue(korean.waitForExistence(timeout: 5))
        korean.tap()
        XCTAssertTrue(app.staticTexts["Selected: Korean"].waitForExistence(timeout: 5))
        app.terminate()
    }

    func testP18RemoveButtonsThenNativeBackLeaveTheSceneResponsive() {
        let app = openP18()
        let scroll = app.scrollViews["probe.p18.grid"]
        let removeA = app.buttons["probe.p18.remove.a"]
        scroll.swipeLeft()
        XCTAssertTrue(removeA.isHittable)
        removeA.tap()
        XCTAssertTrue(app.staticTexts["Rows: 1"].waitForExistence(timeout: 5))
        XCTAssertFalse(removeA.exists)
        let removeB = app.buttons["probe.p18.remove.b"]
        XCTAssertTrue(removeB.isHittable)
        removeB.tap()
        XCTAssertTrue(app.staticTexts["Rows: 0"].waitForExistence(timeout: 5))
        XCTAssertFalse(removeB.exists)
        XCTAssertTrue(app.staticTexts["probe.p18.header.remove"].exists)
        captureV9(app, "p18-grid-remove-actions-and-header")

        app.navigationBars.buttons["BackButton"].tap()
        let open = app.buttons["probe.p18.open"]
        XCTAssertTrue(open.waitForExistence(timeout: 5))
        open.tap()
        XCTAssertTrue(app.staticTexts["Rows: 2"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.textFields["probe.p18.target.b"].exists)
        captureV9(app, "p18-grid-reopened-after-back-dispose")
    }

    func testP19ComposedNativeMenuSelectOwnsBothEdgesAndSelection() {
        let app = XCUIApplication(bundleIdentifier:
            "com.davidortinau.microsoftswiftui.appmainprobe20261003")
        app.launch()
        app.tabBars.buttons["Resources"].tap()
        app.buttons["probe.p19.open"].tap()
        XCTAssertTrue(app.navigationBars["Composed selects"].waitForExistence(timeout: 10))

        let media = app.buttons["probe.p19.media"]
        let language = app.buttons["probe.p19.language"]
        XCTAssertTrue(media.waitForExistence(timeout: 5))
        XCTAssertTrue(language.exists)
        XCTAssertGreaterThan(media.frame.width, 280)
        XCTAssertGreaterThan(language.frame.width, 280)
        XCTAssertEqual(media.value as? String, "Video")
        XCTAssertEqual(language.value as? String, "English")
        let selected = app.staticTexts["probe.p19.media.value"]
        let chevron = app.images["probe.p19.media.chevron"]
        XCTAssertTrue(selected.exists && chevron.exists)
        XCTAssertLessThan(selected.frame.minX, media.frame.midX)
        XCTAssertGreaterThan(chevron.frame.maxX, media.frame.midX)
        captureV9(app, "p19-native-menu-leading-value-trailing-chevron")

        func tap(_ menu: XCUIElement, at fraction: CGFloat) {
            menu.coordinate(withNormalizedOffset: CGVector(dx: fraction, dy: 0.5)).tap()
        }

        tap(media, at: 7 / media.frame.width)
        let textOption = app.buttons["probe.p19.media.option.1"]
        XCTAssertTrue(textOption.waitForExistence(timeout: 5))
        textOption.tap()
        XCTAssertTrue(app.staticTexts["Media type selection: Text (1)"]
            .waitForExistence(timeout: 5))
        XCTAssertEqual(media.value as? String, "Text")
        captureV9(app, "p19-native-media-left-edge-selected")

        tap(media, at: 1 - 7 / media.frame.width)
        let audioOption = app.buttons["probe.p19.media.option.2"]
        XCTAssertTrue(audioOption.waitForExistence(timeout: 5))
        audioOption.tap()
        XCTAssertTrue(app.staticTexts["Media type selection: Audio (2)"]
            .waitForExistence(timeout: 5))
        XCTAssertEqual(media.value as? String, "Audio")
        tap(media, at: 0.5)
        XCTAssertTrue(app.buttons["probe.p19.media.option.2"].isSelected)
        app.staticTexts["Media type selection: Audio (2)"].tap()
        XCTAssertFalse(app.buttons["probe.p19.media.option.2"].exists)

        tap(language, at: 7 / language.frame.width)
        let korean = app.buttons["probe.p19.language.option.1"]
        XCTAssertTrue(korean.waitForExistence(timeout: 5))
        korean.tap()
        XCTAssertTrue(app.staticTexts["Language selection: Korean (1)"]
            .waitForExistence(timeout: 5))
        XCTAssertEqual(language.value as? String, "Korean")
        tap(language, at: 1 - 7 / language.frame.width)
        let spanish = app.buttons["probe.p19.language.option.2"]
        XCTAssertTrue(spanish.waitForExistence(timeout: 5))
        spanish.tap()
        XCTAssertTrue(app.staticTexts["Language selection: Spanish (2)"]
            .waitForExistence(timeout: 5))
        XCTAssertEqual(language.value as? String, "Spanish")
        captureV9(app, "p19-native-menu-both-edges-selection-and-outline")

        app.navigationBars.buttons["BackButton"].tap()
        XCTAssertTrue(app.buttons["probe.p19.open"].waitForExistence(timeout: 5))
        app.buttons["probe.p19.open"].tap()
        XCTAssertTrue(app.buttons["probe.p19.media"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["probe.p19.media"].value as? String, "Video")
        app.terminate()
    }

    func testP16ResourceDeleteCenteredCallbacksHaveNoDataEffect() {
        let app = openP16()
        let openDelete = app.buttons["probe.p16.delete.open"]
        for _ in 0..<5 where !openDelete.isHittable { app.swipeUp() }
        XCTAssertTrue(openDelete.isHittable)
        openDelete.tap()
        XCTAssertTrue(app.buttons["probe.p16.delete.close"].waitForExistence(timeout: 5))
        app.buttons["probe.p16.delete.close"].tap()
        XCTAssertTrue(app.staticTexts["Delete cancelled, draft retained"]
            .waitForExistence(timeout: 5))
        openDelete.tap()
        app.buttons["probe.p16.delete.cancel"].tap()
        XCTAssertTrue(app.staticTexts["Delete cancelled, draft retained"].exists)
        openDelete.tap()
        app.windows.firstMatch.coordinate(withNormalizedOffset:
            CGVector(dx: 0.01, dy: 0.5)).tap()
        XCTAssertTrue(app.staticTexts["Delete cancelled, draft retained"].exists)
        openDelete.tap()
        let dialog = app.buttons["probe.p16.delete.confirm"]
        XCTAssertTrue(dialog.waitForExistence(timeout: 5))
        captureV9(app, "p16-centered-delete-with-close-cancel")
        dialog.tap()
        XCTAssertTrue(app.staticTexts["Dummy confirm callback only"]
            .waitForExistence(timeout: 5))
        XCTAssertTrue(openDelete.exists)
    }

    func testP16StarterScrimBlocksTheWholeTabViewAndNeverSelfDismisses() {
        let app = openP16()
        let background = app.buttons["probe.p16.background.action"]
        let busy = app.buttons["probe.p16.starter.open"]
        for _ in 0..<6 where !busy.isHittable { app.swipeUp() }
        XCTAssertTrue(busy.isHittable)
        XCTAssertTrue(background.exists)
        let window = app.windows.firstMatch
        let before = background.frame
        let backgroundPoint = CGVector(
            dx: (before.midX - window.frame.minX) / window.frame.width,
            dy: (before.midY - window.frame.minY) / window.frame.height)
        busy.tap()
        let status = app.staticTexts["Creating starter resource"]
        XCTAssertTrue(status.waitForExistence(timeout: 5))
        let busyIndicator = app.activityIndicators["probe.p16.starter.spinner"]
        XCTAssertTrue(busyIndicator.exists)
        window.coordinate(withNormalizedOffset: backgroundPoint).tap()
        XCTAssertFalse(app.staticTexts["Background activated"].exists)
        let account = app.tabBars.buttons["Account"]
        XCTAssertFalse(account.isHittable)
        sleep(2)
        XCTAssertTrue(status.exists)
        captureV9(app, "p16-starter-full-root-blocking-overlay")
    }

    private func openP16() -> XCUIApplication {
        let app = XCUIApplication(bundleIdentifier:
            "com.davidortinau.microsoftswiftui.appmainprobe20261003")
        app.launch()
        app.tabBars.buttons["Resources"].tap()
        let open = app.buttons["probe.p16.open"]
        XCTAssertTrue(open.waitForExistence(timeout: 20))
        open.tap()
        XCTAssertTrue(app.navigationBars["Four-screen bridge"].waitForExistence(timeout: 10))
        return app
    }

    private func openP18() -> XCUIApplication {
        let app = XCUIApplication(bundleIdentifier:
            "com.davidortinau.microsoftswiftui.appmainprobe20261003")
        app.launch()
        app.tabBars.buttons["Resources"].tap()
        let open = app.buttons["probe.p18.open"]
        XCTAssertTrue(open.waitForExistence(timeout: 20))
        open.tap()
        XCTAssertTrue(app.navigationBars["Horizontal grid"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Column guard: passed"].exists)
        return app
    }

    private func near(_ actual: [Int], _ expected: [Int], tolerance: Int = 4) -> Bool {
        zip(actual, expected).allSatisfy { abs($0.0 - $0.1) <= tolerance }
    }

    private func assertColor(_ actual: [Int], _ expected: [Int], _ description: String,
                             tolerance: Int = 4, file: StaticString = #filePath,
                             line: UInt = #line) {
        XCTAssertTrue(near(actual, expected, tolerance: tolerance),
                      "\(description): expected \(expected), got \(actual)",
                      file: file, line: line)
    }

    private func captureV9(_ app: XCUIApplication, _ title: String) {
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = title
        screenshot.lifetime = .keepAlways
        add(screenshot)
        let tree = XCTAttachment(string: app.debugDescription)
        tree.name = "\(title)-accessibility"
        tree.lifetime = .keepAlways
        add(tree)
    }
}
