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
    
    /// Returns a set of ``ComposableContactKey`` values that represent keys currently holding non-empty or
    /// non-nil data in this ``CNContact`` instance. Unlike ``getFetchedKeys()``, this method checks the
    /// actual content of the contact fields. If a field is empty, absent, or nil, its associated key is
    /// not included in the result.
    ///
    /// Use this method when you need to know which properties of the contact are actually populated
    /// with meaningful information, regardless of whether they were fetched initially. This helps
    /// determine which user-visible data fields can be displayed or further processed.
    func getSetKeys() -> Set<ComposableContactKey> {
        var availableKeys = Set<ComposableContactKey>()
        for key in ComposableContactKey.allCases {
            switch key {
            case .identifier:
                if !self.identifier.isEmpty {
                    availableKeys.insert(.identifier)
                }
            case .contactType:
                // CNContactType is always available
                availableKeys.insert(.contactType)
            case .namePrefix:
                if !self.namePrefix.isEmpty {
                    availableKeys.insert(.namePrefix)
                }
            case .givenName:
                if !self.givenName.isEmpty {
                    availableKeys.insert(.givenName)
                }
            case .middleName:
                if !self.middleName.isEmpty {
                    availableKeys.insert(.middleName)
                }
            case .familyName:
                if !self.familyName.isEmpty {
                    availableKeys.insert(.familyName)
                }
            case .previousFamilyName:
                if !self.previousFamilyName.isEmpty {
                    availableKeys.insert(.previousFamilyName)
                }
            case .nameSuffix:
                if !self.nameSuffix.isEmpty {
                    availableKeys.insert(.nameSuffix)
                }
            case .nickname:
                if !self.nickname.isEmpty {
                    availableKeys.insert(.nickname)
                }
            case .organizationName:
                if !self.organizationName.isEmpty {
                    availableKeys.insert(.organizationName)
                }
            case .departmentName:
                if !self.departmentName.isEmpty {
                    availableKeys.insert(.departmentName)
                }
            case .jobTitle:
                if !self.jobTitle.isEmpty {
                    availableKeys.insert(.jobTitle)
                }
            case .phoneticGivenName:
                if !self.phoneticGivenName.isEmpty {
                    availableKeys.insert(.phoneticGivenName)
                }
            case .phoneticMiddleName:
                if !self.phoneticMiddleName.isEmpty {
                    availableKeys.insert(.phoneticMiddleName)
                }
            case .phoneticFamilyName:
                if !self.phoneticFamilyName.isEmpty {
                    availableKeys.insert(.phoneticFamilyName)
                }
            case .phoneticOrganizationName:
                if !self.phoneticOrganizationName.isEmpty {
                    availableKeys.insert(.phoneticOrganizationName)
                }
            case .birthday:
                if self.birthday != nil {
                    availableKeys.insert(.birthday)
                }
            case .nonGregorianBirthday:
                if self.nonGregorianBirthday != nil {
                    availableKeys.insert(.nonGregorianBirthday)
                }
            case .note:
                if !self.note.isEmpty {
                    availableKeys.insert(.note)
                }
            case .imageData:
                if self.imageData != nil {
                    availableKeys.insert(.imageData)
                }
            case .thumbnailImageData:
                if self.thumbnailImageData != nil {
                    availableKeys.insert(.thumbnailImageData)
                }
            case .imageDataAvailable:
                // imageDataAvailable is always available
                availableKeys.insert(.imageDataAvailable)
            case .phoneNumbers:
                if !self.phoneNumbers.isEmpty {
                    availableKeys.insert(.phoneNumbers)
                }
            case .emailAddresses:
                if !self.emailAddresses.isEmpty {
                    availableKeys.insert(.emailAddresses)
                }
            case .postalAddresses:
                if !self.postalAddresses.isEmpty {
                    availableKeys.insert(.postalAddresses)
                }
            case .urlAddresses:
                if !self.urlAddresses.isEmpty {
                    availableKeys.insert(.urlAddresses)
                }
            case .contactRelations:
                if !self.contactRelations.isEmpty {
                    availableKeys.insert(.contactRelations)
                }
            case .socialProfiles:
                if !self.socialProfiles.isEmpty {
                    availableKeys.insert(.socialProfiles)
                }
            case .instantMessageAddresses:
                if !self.instantMessageAddresses.isEmpty {
                    availableKeys.insert(.instantMessageAddresses)
                }
            case .dates:
                if !self.dates.isEmpty {
                    availableKeys.insert(.dates)
                }
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
