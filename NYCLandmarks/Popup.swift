//
//  Popup.swift
//  StreamGageView
//
//  Created by John Robokos on 10/20/16.
//  Copyright © 2016 John Robokos. All rights reserved.
//

import Foundation
import UIKit
import Mapbox
import Alamofire
import AlamofireImage

class Popup: UIView {

    var leftRightMargin: CGFloat = 10
    var attributes: [String: Any] = [:]
    var mapViewController: MapViewController?

    @IBOutlet weak var heartButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var address: UILabel!
    @IBOutlet weak var type: UILabel!
    @IBOutlet weak var name: UILabel!

    // You need to set this as the anchor point, usually
    // the parent view's safeAreaLayoutGuide. Set this before
    // adding the subview
    var safeLayoutGuide: UILayoutGuide?

    private var tapGesture = UITapGestureRecognizer()

    @objc func swipedUp() {
        self.hide()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public func show(withAttributes attributes: [String: Any], animated: Bool = true) {
        if let id = attributes["FID"] as? Int,
            let name = attributes["LPC_NAME"] as? String,
            let address = attributes["Address"] as? String,
            let type = attributes["BuildType"] as? String,
            let imageHref = attributes["URL_IMAGE"] as? String,
            let imageUrl = URL(string: imageHref),
            let s3ImageUrl = URL(string: "https://s3.amazonaws.com/nyclandmarks/\(imageUrl.lastPathComponent)") {

            self.heartButton.isHidden = Favorites.default.isFavorite(id) ? false : true
            
            self.attributes = attributes
            self.name.text = name
            self.address.text = address
            self.type.text = type

            self.imageView.image = nil
            let filter = AspectScaledToFillSizeWithRoundedCornersFilter(
                size: imageView.frame.size,
                radius: 5.0
            )
           
            self.imageView.af_setImage(
                withURL: s3ImageUrl,
                filter: filter,
                imageTransition: .crossDissolve(0.2)                
            )

        }
        self.isHidden = false
    }

    public func hide(animated: Bool = true) {
        super.isHidden = true
    }

    public override func didMoveToSuperview() {

        if safeLayoutGuide == nil {
            fatalError("safeLayoutGuide must be set!")
        }
        
        self.heartButton.isHidden = true
        

        self.tapGesture = UITapGestureRecognizer(target: self, action: #selector(Popup.tappedName))

        self.name.addGestureRecognizer(self.tapGesture)

        NSLayoutConstraint.activate([
            self.leadingAnchor.constraint(equalTo: safeLayoutGuide!.leadingAnchor, constant: leftRightMargin),
            self.trailingAnchor.constraint(equalTo: safeLayoutGuide!.trailingAnchor, constant: -leftRightMargin),
            self.topAnchor.constraintEqualToSystemSpacingBelow(safeLayoutGuide!.topAnchor, multiplier: 1.0)
            ])

        self.layer.cornerRadius = 5

        self.isHidden = true

        self.translatesAutoresizingMaskIntoConstraints = false
        self.layoutIfNeeded()

    }

    @IBAction func moreInfoPressed(_ sender: Any) {
        self.mapViewController?.performSegue(withIdentifier: "DetailViewSegue",
                                             sender: self)
    }

    @objc func tappedName(sender: UITapGestureRecognizer) {
        self.mapViewController?.performSegue(withIdentifier: "DetailViewSegue", sender: self)
    }

}
