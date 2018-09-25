//
//  DetailViewController.swift
//  NYCLandmarks
//
//  Created by John Robokos on 9/19/18.
//  Copyright © 2018 Robokos, John. All rights reserved.
//

import Foundation
import UIKit
import WebKit
import XCGLogger
import Alamofire
import AlamofireImage

// When displaying a PDF within a WebView, the background is gray, regardless
// of the background color set in the Storyboard. This clears the color.
extension UIView {
    func clearBackgrounds() {
        self.backgroundColor = UIColor.clear
        for subview in self.subviews {
            subview.clearBackgrounds()
        }
    }
}

extension UIStackView {
    
    func removeAllArrangedSubviews() {
        
        let removedSubviews = arrangedSubviews.reduce([]) { (allSubviews, subview) -> [UIView] in
            self.removeArrangedSubview(subview)
            return allSubviews + [subview]
        }
        
        // Deactivate all constraints
        NSLayoutConstraint.deactivate(removedSubviews.flatMap({ $0.constraints }))
        
        // Remove the views from self
        removedSubviews.forEach({ $0.removeFromSuperview() })
    }
}

class DetailViewController: UIViewController {

    let log = XCGLogger.default

    var attributes: [String: Any] = [:]

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var webViewHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var name: UILabel!

    @IBOutlet weak var detailStackView: UIStackView!

    @IBAction func closeButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBOutlet weak var heartButton: UIButton!
    
    @IBOutlet weak var downloadPdfButton: UIButton!
    
    let activity = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
    var localPdfFilePath: URL?
    var docController: UIDocumentInteractionController?
    
    let filledHeart = UIImage(named: "heart-filled")!
    let normalHeart = UIImage(named: "heart")!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.webView.scrollView.isScrollEnabled = false
        self.webView.navigationDelegate = self
        self.webView.backgroundColor = UIColor.white
        self.webView.scrollView.backgroundColor = UIColor.white
        self.webView.isOpaque = false
        self.webView.addSubview(activity)
        self.activity.hidesWhenStopped = true
        self.activity.translatesAutoresizingMaskIntoConstraints = false
        self.activity.centerXAnchor.constraint(equalTo: self.webView.centerXAnchor).isActive = true
        self.activity.topAnchor.constraint(equalTo: self.webView.topAnchor, constant: 80).isActive = true
        self.heartButton.addTarget(self, action: #selector(heartPress(sender:)), for: .touchUpInside)
    }

    @objc func heartPress(sender: UIButton) {
        guard let id = self.attributes["FID"] as? Int else {
            fatalError("No ID found?")
        }
        
        if Favorites.default.isFavorite(id){
            self.heartButton.setImage(normalHeart, for: .normal)
            Favorites.default.unsaveFavorite(id)
        }
        else {
            self.heartButton.setImage(filledHeart, for: .normal)
            Favorites.default.saveFavorite(id)
        }
        
        NotificationCenter.default.post(name: MapViewController.Events.updateFavorites.notification, object: nil)
        
        
    }
    
    func addDataEntry(_ key: String, _ value: String) {
        guard let keyFont = UIFont(name: "Futura-Medium", size: 14.0),
            let valueFont = UIFont(name: "Futura-MediumItalic", size: 14.0) else {
            fatalError("Fonts missing?")
        }

        let label1 = UILabel()
        label1.text = key
        label1.textColor = .darkGray
        label1.font = keyFont

        //label1.translatesAutoresizingMaskIntoConstraints = false
        //label1.addConstraint(NSLayoutConstraint(item: label1, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.lessThanOrEqual, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: 150.0))

        let label2 = UILabel()
        label2.text = value
        label2.textColor = .darkGray
        //label2.translatesAutoresizingMaskIntoConstraints = false
        label2.numberOfLines = 2
        label2.font = valueFont

        let entry1 = UIStackView()
        //entry1.translatesAutoresizingMaskIntoConstraints = false
        entry1.axis = .horizontal
        entry1.alignment = .fill
        //entry1.spacing = 1.0
        entry1.distribution = .fillEqually
        entry1.addArrangedSubview(label1)
        entry1.addArrangedSubview(label2)
        self.detailStackView.addArrangedSubview(entry1)
    }

    override func viewWillAppear(_ animated: Bool) {
        if attributes.isEmpty {
            fatalError("The attributes should be set in the segue to this view controller")
        }
        
        self.detailStackView.removeAllArrangedSubviews()

        if let name = attributes["LPC_NAME"] as? String,
            let id = attributes["FID"] as? Int,
            let address = attributes["Address"] as? String,
            let type = attributes["BuildType"] as? String,
            let imageHref = attributes["URL_IMAGE"] as? String,
            let pdfHref = attributes["URL_REPORT"] as? String,
            let imageUrl = URL(string: imageHref),
            let s3ImageUrl = URL(string: "https://s3.amazonaws.com/nyclandmarks/\(imageUrl.lastPathComponent)"),
            let pdfUrl = URL(string: pdfHref),
            let s3PdfUrl = URL(string: "https://s3.amazonaws.com/nyclandmarks/small_\(pdfUrl.lastPathComponent)"){

            if Favorites.default.isFavorite(id){
                self.heartButton.setImage(filledHeart, for: .normal)
            } else {
                self.heartButton.setImage(normalHeart, for: .normal)
            }
            
            self.downloadPdfButton.isEnabled = false
            self.imageView.image = nil
            self.activity.startAnimating()
            let filter = AspectScaledToFillSizeWithRoundedCornersFilter(
                size: imageView.frame.size,
                radius: 10.0
            )
            
            func completionHandler(response: DataResponse<UIImage>) {
                self.imageView.isHidden = (response.error != nil)
            }
            
            self.imageView.af_setImage(
                withURL: s3ImageUrl,
                filter: filter,
                imageTransition: .crossDissolve(0.2),
                completion: completionHandler
            )

            // Download PDF
            let destination: DownloadRequest.DownloadFileDestination = { _, _ in
                let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let fileURL = documentsURL.appendingPathComponent(s3PdfUrl.lastPathComponent)

                return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
            }

            Alamofire.download(s3PdfUrl, to: destination).response { response in

                if response.error == nil, let filePath = response.destinationURL {
                    self.localPdfFilePath = filePath
                    self.webView.loadFileURL(filePath, allowingReadAccessTo: filePath)
                    self.downloadPdfButton.isEnabled = true
                }
            }

            self.name.text = name
            addDataEntry("Address:", address)
            addDataEntry("Building Type:", type)

            if let style = attributes["Style_Prim"] as? String, style.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                addDataEntry("Style:", style)
            }

            if let use = attributes["USE_ORIG"] as? String, use.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false,
                use != "Unknown" {
                addDataEntry("Original Use:", use)
            }

            if let architects = attributes["Arch_Prima"] as? String,
                architects.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false,
                architects != "Unknown" {
                addDataEntry("Architects:", architects)
            }

            if let buildDate = attributes["Date_Comb"] as? String {
                addDataEntry("Built:", buildDate)
            }

        }

    }

    @IBAction func downloadPdf(_ sender: Any) {
        if let localPath = self.localPdfFilePath {
            self.docController = UIDocumentInteractionController(url: localPath)
            self.docController!.uti = "com.adobe.pdf"
            self.docController!.presentOptionsMenu(from: .zero, in: self.view, animated: true)
        }
    }

}
