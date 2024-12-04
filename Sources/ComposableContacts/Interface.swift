//
//  Interface.swift
//  MultiOnBrowser
//
//  Created by Scott Hoge on 12/3/24.
//

///Per Apple Documentation:
///A CNContact object stores an immutable copy of a contact’s information, so you cannot change the information in this object directly. Contact objects are thread-safe, so you may access them from any thread of your app.
@preconcurrency import Contacts
import Dependencies
import DependenciesMacros


@DependencyClient
public struct ContactsClient: Sendable {
    public var requestAccess: @Sendable () async throws -> CNAuthorizationStatus = { .authorized }
    public var getDataForContacts: @Sendable ([ComposableContactKey]) async throws -> [CNContact] = { _ in [] }
    public var getDataForContact: @Sendable ([ComposableContactKey]) async throws -> ComposableContact = { _ in  .johnDoe}
    public var getKeyForContact: @Sendable () async throws -> String = {""}
}

// MARK: DataTypes
public enum ContactError: Error {
    case requestAccessCompleteFail
    case requestAccessFailed(String)
    case getContactsCompleteFail
    case getContactsFailed(String)
    case unauthorized
}

extension CNContact {
    static let johnDoe: CNContact = {

        let contact = CNMutableContact()

        contact.givenName = "John"
        contact.familyName = "Doe"
        contact.organizationName = "Acme Corp"
        contact.jobTitle = "Software Engineer"

        let workPhone = CNLabeledValue(
            label: CNLabelWork,
            value: CNPhoneNumber(stringValue: "123-456-7890")
        )
        let homePhone = CNLabeledValue(
            label: CNLabelHome,
            value: CNPhoneNumber(stringValue: "987-654-3210")
        )
        contact.phoneNumbers = [workPhone, homePhone]

        let workEmail = CNLabeledValue(
            label: CNLabelWork,
            value: "john.doe@acme.com" as NSString
        )
        let personalEmail = CNLabeledValue(
            label: CNLabelHome,
            value: "john.doe@example.com" as NSString
        )
        contact.emailAddresses = [workEmail, personalEmail]

        let homeAddress = CNMutablePostalAddress()
        homeAddress.street = "123 Elm St"
        homeAddress.city = "Springfield"
        homeAddress.state = "IL"
        homeAddress.postalCode = "62701"
        homeAddress.country = "USA"

        contact.postalAddresses = [
            CNLabeledValue(label: CNLabelHome, value: homeAddress)
        ]

        contact.birthday = DateComponents(year: 1990, month: 5, day: 15)

        let website = CNLabeledValue(
            label: CNLabelWork,
            value: "https://www.acme.com" as NSString
        )
        contact.urlAddresses = [website]

        let socialProfile = CNSocialProfile(
            urlString: nil,
            username: "johndoe",
            userIdentifier: nil,
            service: CNSocialProfileServiceTwitter
        )
        contact.socialProfiles = [
            CNLabeledValue(label: CNLabelWork, value: socialProfile)
        ]

        contact.note = "This is a sample contact."
        
        guard let immutableContact = contact.copy() as? CNContact else {
            return CNContact()
        }
        return immutableContact
    }()

    static let janeDoe: CNContact = {

        let contact = CNMutableContact()

        contact.givenName = "Jane"
        contact.familyName = "Doe"
        contact.organizationName = "Any Company"
        contact.jobTitle = "Realest Human"

        let workPhone = CNLabeledValue(
            label: CNLabelWork,
            value: CNPhoneNumber(stringValue: "123-456-7222")
        )
        let homePhone = CNLabeledValue(
            label: CNLabelHome,
            value: CNPhoneNumber(stringValue: "987-654-32444")
        )
        contact.phoneNumbers = [workPhone, homePhone]

        let workEmail = CNLabeledValue(
            label: CNLabelWork,
            value: "jane.doe@any.com" as NSString
        )
        let personalEmail = CNLabeledValue(
            label: CNLabelHome,
            value: "jane.doe@example.com" as NSString
        )
        contact.emailAddresses = [workEmail, personalEmail]

        let homeAddress = CNMutablePostalAddress()
        homeAddress.street = "123 Any St"
        homeAddress.city = "Any Town"
        homeAddress.state = "CA"
        homeAddress.postalCode = "23423"
        homeAddress.country = "USA"

        contact.postalAddresses = [
            CNLabeledValue(label: CNLabelHome, value: homeAddress)
        ]

        contact.birthday = DateComponents(year: 1983, month: 2, day: 21)

        let website = CNLabeledValue(
            label: CNLabelWork,
            value: "https://www.any.com" as NSString
        )
        contact.urlAddresses = [website]

        let socialProfile = CNSocialProfile(
            urlString: nil,
            username: "janedoe",
            userIdentifier: nil,
            service: CNSocialProfileServiceTwitter
        )
        contact.socialProfiles = [
            CNLabeledValue(label: CNLabelWork, value: socialProfile)
        ]

        contact.note = "This is another sample contact."
        
        guard let immutableContact = contact.copy() as? CNContact else {
            return CNContact()
        }
        return immutableContact
    }()
}
