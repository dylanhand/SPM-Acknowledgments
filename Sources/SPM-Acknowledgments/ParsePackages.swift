//
//  ParsePackages.swift
//  FlightTrack
//
//  Created by Tim Roesner on 2/19/20.
//  Copyright © 2020 Tim Roesner. All rights reserved.
//

import Foundation
import SwiftUI

// Removes ".git" from a url such as https://github.com/dylanhand/SPM-Acknowledgments.git
func stripGitExtension(_ url: URL) -> URL {
    let separator = "."
    var components = url.absoluteString.components(separatedBy: separator)
    if components.last == "git" {
        components.removeLast()
    }
    guard let strippedURL = URL(string: components.joined(separator: separator)) else {
        return url
    }
    return strippedURL
}

internal struct Package: Decodable {
	let name: String
	let licenseURLMain: URL
    let licenseURLMaster: URL

	private enum CodingKeys: String, CodingKey {
		case name = "identity"
		case licenseURL = "location"
	}

	init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		name = try values.decode(String.self, forKey: .name)
		let baseURL = try values.decode(URL.self, forKey: .licenseURL)
        let baseURLStripped = stripGitExtension(baseURL)
		licenseURLMain = baseURLStripped.appendingPathComponent("/raw/main/LICENSE")
        licenseURLMaster = baseURLStripped.appendingPathComponent("/raw/master/LICENSE")
	}
}

internal class ParsePackages {
	private struct Pins: Decodable {
		var pins: [Package]
	}
	
	func parsePackages() -> [Package] {
		guard let packagesPath = Bundle.main.path(forResource: "Package", ofType: "resolved"),
			let data = try? Data(contentsOf: URL(fileURLWithPath: packagesPath)) ,
			let json = try? JSONDecoder().decode(Pins.self, from: data) else {
            return []
        }
        json.pins.forEach { print($0) }
        return json.pins.filter({ !$0.licenseURLMain.absoluteString.contains(".git/") })
	}
}

extension Package {
    func fetchLicense() async -> String? {
        // First try to get the license from the `master` branch. If not found, use `main` branch.
        let licenseUrls = [
            licenseURLMaster,
            licenseURLMain,
            licenseURLMaster.appendingPathExtension("md"),
            licenseURLMain.appendingPathExtension("md")
        ]

        for url in licenseUrls {
            if let license = await fetchLicense(at: url) {
                return license
            }
        }

        return nil
    }

    private func fetchLicense(at url: URL) async -> String? {
        var taskResponse: (data: Data, response: URLResponse)

        do {
            taskResponse = try await URLSession.shared.data(from: url)
        } catch {
            return nil
        }

        guard taskResponse.response.mimeType == "text/plain" else {
            // The license should be plain text. If it's HTML, we probably got a 404 for using the wrong branch name.
            return nil
        }

        guard let license = String(data: taskResponse.data, encoding: .utf8) else {
            return nil
        }

        return license
    }
}
