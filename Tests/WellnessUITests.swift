import XCTest

final class WellnessUITests: XCTestCase {
    @MainActor
    func testLogOutReturnsToWelcomeAndAllowsANewJourney() throws {
        let app = XCUIApplication()
        app.launchEnvironment["WELLNESS_ISOLATED_TEST_STATE"] = "1"
        app.launchEnvironment["WELLNESS_RESET_PREFERENCES"] = "1"
        app.launchEnvironment["GEMINI_API_KEY"] = ""
        app.launch()
        let name = app.textFields["preferredName"]
        XCTAssertTrue(name.waitForExistence(timeout: 10))
        name.tap()
        name.typeText("Demo\n")
        app.buttons["safetyCheckbox"].tap()
        let begin = app.buttons["beginJourney"]
        if !begin.isHittable { app.swipeUp() }
        begin.tap()
        XCTAssertTrue(app.buttons["persona_teacup"].waitForExistence(timeout: 5))

        // Leave a synthetic local archive to verify separately after the test.
        app.buttons["persona_teacup"].tap()
        let input = app.textFields["messageInput"]
        XCTAssertTrue(input.waitForExistence(timeout: 5))
        input.tap()
        input.typeText("A logout archive check")
        app.buttons["sendMessage"].tap()
        XCTAssertTrue(app.buttons["Try again"].waitForExistence(timeout: 5))
        app.buttons["backToHome"].tap()
        app.buttons["Settings"].tap()
        let logout = app.buttons["logOut"]
        XCTAssertTrue(logout.waitForExistence(timeout: 5))
        if !logout.isHittable { app.swipeUp() }
        logout.tap()

        XCTAssertTrue(name.waitForExistence(timeout: 5))
        let displayedName = name.value as? String ?? ""
        XCTAssertTrue(displayedName.isEmpty || displayedName == "Your preferred name")
        XCTAssertFalse(begin.isEnabled)
        XCTAssertEqual(app.buttons["safetyCheckbox"].value as? String, "Unchecked")
        app.terminate()
        app.launchEnvironment["WELLNESS_RESET_PREFERENCES"] = "0"
        app.launch()
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        XCTAssertFalse(begin.isEnabled)
        name.tap()
        name.typeText("Casey\n")
        app.buttons["safetyCheckbox"].tap()
        if !begin.isHittable { app.swipeUp() }
        begin.tap()
        XCTAssertTrue(app.staticTexts["Hi, Casey."].waitForExistence(timeout: 5))
    }

    @MainActor
    func testTeacupSupportWorksWithoutAPIAndUrgentRouteRemainsAvailable() throws {
        let app = XCUIApplication()
        app.launchEnvironment["WELLNESS_ISOLATED_TEST_STATE"] = "1"
        app.launchEnvironment["GEMINI_API_KEY"] = ""
        app.launchArguments = ["-userName", "Demo", "-safetyAgreementVersion", "2"]
        app.launch()
        app.buttons["persona_teacup"].tap()
        let input = app.textFields["messageInput"]
        XCTAssertTrue(input.waitForExistence(timeout: 5))
        input.tap()
        input.typeText("People are bullying me in class")
        app.buttons["sendMessage"].tap()
        XCTAssertTrue(app.buttons["support_stopBullying"].waitForExistence(timeout: 10))
        let bullyingResource = app.buttons["support_stopBullying"]
        if !bullyingResource.isHittable { app.swipeUp() }
        XCTAssertTrue(bullyingResource.exists)
        XCTAssertTrue(app.buttons["support_namiYouth"].exists)
        let moreSupport = app.buttons["Find other support"]
        if !moreSupport.isHittable { app.swipeUp() }
        moreSupport.tap()
        let urgent = app.buttons["supportUrgentHelp"]
        XCTAssertTrue(urgent.waitForExistence(timeout: 5))
        if !urgent.isHittable { app.swipeUp() }
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "Teacup human support directory"
        shot.lifetime = .keepAlways
        add(shot)
        urgent.tap()
        XCTAssertTrue(app.staticTexts["crisisTitle"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Call 988"].exists)
        let home = app.buttons["crisisReturn"]
        if !home.isHittable { app.swipeUp() }
        home.tap()
        XCTAssertTrue(app.buttons["persona_teacup"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testOnboardingFourCompanionsAndImmediateCrisisRouting() throws {
        let app = XCUIApplication()
        app.launchEnvironment["WELLNESS_ISOLATED_TEST_STATE"] = "1"
        app.launchEnvironment["WELLNESS_RESET_PREFERENCES"] = "1"
        // Keep the safety test independent of any developer's real Gemini credentials.
        app.launchEnvironment["GEMINI_API_KEY"] = ""
        app.launch()
        let nameField = app.textFields["preferredName"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 10))
        let begin = app.buttons["beginJourney"]
        let checkbox = app.buttons["safetyCheckbox"]
        XCTAssertFalse(begin.isEnabled)
        if !checkbox.isHittable { app.swipeUp() }
        checkbox.tap()
        XCTAssertFalse(begin.isEnabled, "Consent alone is insufficient")
        checkbox.tap()
        nameField.tap()
        nameField.typeText("Alex\n")
        XCTAssertFalse(begin.isEnabled, "A name alone is insufficient")
        app.buttons["readTerms"].tap()
        XCTAssertTrue(app.staticTexts["1. Your Privacy (Local-First)"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "sent to Google's Gemini API")).firstMatch.exists)
        let termsShot = XCTAttachment(screenshot: app.screenshot())
        termsShot.name = "White Lotus terms"
        termsShot.lifetime = .keepAlways
        add(termsShot)
        app.buttons["termsDone"].tap()
        XCTAssertFalse(begin.isEnabled, "Reading terms does not grant consent")
        checkbox.tap()
        XCTAssertTrue(begin.isEnabled)
        let welcomeShot = XCTAttachment(screenshot: app.screenshot())
        welcomeShot.name = "White Lotus welcome"
        welcomeShot.lifetime = .keepAlways
        add(welcomeShot)
        begin.tap()
        for persona in ["teacup", "basket", "boomerang", "lantern"] {
            XCTAssertTrue(app.buttons["persona_\(persona)"].waitForExistence(timeout: 5))
        }
        let homeShot = XCTAttachment(screenshot: app.screenshot())
        homeShot.name = "Dashboard"
        homeShot.lifetime = .keepAlways
        add(homeShot)
        app.buttons["persona_teacup"].tap()
        let input = app.textFields["messageInput"]
        let multiLineInput = app.textViews["messageInput"]
        let composer = input.waitForExistence(timeout: 3) ? input : multiLineInput
        XCTAssertTrue(composer.waitForExistence(timeout: 5))
        composer.tap()
        composer.typeText("I want to die")
        app.buttons["sendMessage"].tap()
        XCTAssertTrue(app.staticTexts["crisisTitle"].waitForExistence(timeout: 5))
        // SwiftUI's styled native Links are exposed as buttons in iOS accessibility.
        XCTAssertTrue(app.buttons["Call 988"].exists)
        XCTAssertTrue(app.buttons["Text 988"].exists)
        let crisisShot = XCTAttachment(screenshot: app.screenshot())
        crisisShot.name = "Crisis intervention"
        crisisShot.lifetime = .keepAlways
        add(crisisShot)
        let returnButton = app.buttons["crisisReturn"]
        if !returnButton.isHittable { app.swipeUp() }
        returnButton.tap()
        XCTAssertTrue(app.buttons["persona_teacup"].waitForExistence(timeout: 5))
        app.buttons["persona_teacup"].tap()
        XCTAssertFalse(app.staticTexts["I want to die"].exists)
        XCTAssertTrue(app.buttons["Help me feel grounded"].exists)
        app.terminate()
        app.launchEnvironment["WELLNESS_RESET_PREFERENCES"] = "0"
        app.launch()
        XCTAssertTrue(app.buttons["persona_teacup"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.textFields["preferredName"].exists)
    }
}
