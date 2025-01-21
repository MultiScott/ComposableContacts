//
//  CNContactExtensions.swift
//  ComposableContacts
//
//  Created by Scott Hoge on 12/11/24.
//

@preconcurrency import Contacts

//MARK: Functional Extensions
public extension CNContact {
    
    /// Returns a set of ``ComposableContactKey`` values that correspond to keys the `CNContact` instance
    /// has actually been fetched with. In other words, it checks against the underlying contact store
    /// to determine which properties were requested and loaded during the fetch.
    ///
    /// This method does not guarantee that the associated values are non-empty or meaningful; it only
    /// confirms that these keys were made available from the contact store. This is useful when you
    /// need to know what data fields were included in the original fetch request and are thus safe
    /// to access without causing a refetch or error.
    func getFetchedKeys() -> Set<ComposableContactKey> {
        var availableKeys = Set<ComposableContactKey>()
        for key in ComposableContactKey.allCases {
            let cnKey = key.keyDescriptor as! String
            if self.isKeyAvailable(cnKey) {
                availableKeys.insert(key)
            }
        }
        return availableKeys
    }

}

//MARK: Mock Data
public extension CNContact {
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
