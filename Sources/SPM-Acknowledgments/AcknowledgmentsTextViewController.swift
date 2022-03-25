//
//  AcknowledgmentsTextViewController.swift
//  FlightTrack
//
//  Created by Tim Roesner on 2/20/20.
//  Copyright © 2020 Tim Roesner. All rights reserved.
//

import UIKit

internal class AcknowledgmentsTextViewController: UIViewController {
	private let package: Package
	private let loadingSpinner = UIActivityIndicatorView()
	private let textView: UITextView = {
		let textView = UITextView()
		textView.dataDetectorTypes = .link
		textView.isEditable = false
		textView.font = UIFont.preferredFont(forTextStyle: .body)
		textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
		return textView
	}()
	
	init(package: Package) {
		self.package = package
		super.init(nibName: nil, bundle: nil)
		title = package.name
		if #available(iOS 13.0, *) {
			view.backgroundColor = .systemBackground
		} else {
			view.backgroundColor = .white
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		
		textView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(textView)
		
		loadingSpinner.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(loadingSpinner)
		
		let safeArea = view.safeAreaLayoutGuide
		NSLayoutConstraint.activate([
			textView.topAnchor.constraint(equalTo: safeArea.topAnchor),
			textView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
			safeArea.trailingAnchor.constraint(equalTo: textView.trailingAnchor),
			safeArea.bottomAnchor.constraint(equalTo: textView.bottomAnchor),
			
			loadingSpinner.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor),
			loadingSpinner.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor)
		])
		
		loadingSpinner.startAnimating()
	}
	
	override func viewDidAppear(_ animated: Bool) {
        package.fetchLicense { licenseText in
            DispatchQueue.main.async {
                self.textView.text = licenseText ?? "No license found."
                self.loadingSpinner.stopAnimating()
            }
        }
	}
	
	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
