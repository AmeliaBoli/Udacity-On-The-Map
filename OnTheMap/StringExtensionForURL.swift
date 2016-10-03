//
//  StringExtensionForURL.swift
//  OnTheMap
//
//  Created by Amelia Boli on 8/29/16.
//  Copyright © 2016 Amelia Boli. All rights reserved.
//

import Foundation

extension String {
    enum UrlErrors: ErrorType {
        case invalidString
        case invalidComponents
        case noDataDetector
        case noHost
        case wrongNumberOfLinks
        case invalidCharacter(Character)
    }

    func createValidURL() throws -> NSURL {

        let startingString = self.lowercaseString

        guard var mediaURL = NSURL(string: startingString) else {
            throw UrlErrors.invalidString
        }

        if mediaURL.scheme == "" {
            if mediaURL.host == nil {
                let stringWithDelimeter = "http://" + startingString

                guard let urlWithSchemeAndHost = NSURL(string: stringWithDelimeter) else {
                    throw UrlErrors.invalidString
                }

                mediaURL = urlWithSchemeAndHost

            } else {

                guard let components = NSURLComponents(URL: mediaURL, resolvingAgainstBaseURL: true) else {
                    throw UrlErrors.invalidComponents
                }
                components.scheme = "http"


                guard let urlWithScheme = components.URL else {
                    throw UrlErrors.invalidComponents
                }

                mediaURL = urlWithScheme
            }
        }

        let dataDetector: NSDataDetector
        do {
            dataDetector = try NSDataDetector(types: NSTextCheckingType.Link.rawValue)
        } catch {
            throw UrlErrors.noDataDetector
        }

        guard let hostString = mediaURL.host else {
            throw UrlErrors.noHost
        }

        let numberOfLinks = dataDetector.numberOfMatchesInString(hostString, options: [], range: NSMakeRange(0, hostString.characters.count))

        guard numberOfLinks == 1 else {
            throw UrlErrors.wrongNumberOfLinks
        }

        let characterSet = NSCharacterSet(charactersInString: "abcdefghijklmnopqrstuvwxyz0123456789-.")

        for character in hostString.utf16 {
            guard characterSet.characterIsMember(character) else {
                throw UrlErrors.invalidCharacter(Character(UnicodeScalar(character)))
            }
        }

        return mediaURL
    }
}
