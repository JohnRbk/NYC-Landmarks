//
//  DetailViewController+WKNavigationDelegate.swift
//  NYCLandmarks
//
//  Created by John Robokos on 9/21/18.
//  Copyright © 2018 Robokos, John. All rights reserved.
//

import UIKit
import WebKit

extension DetailViewController: WKNavigationDelegate {

    // When loading a PDF in WebKit, a page number indicator is displayed
    // in the upper-left. This disables the page view indicator.
    // https://stackoverflow.com/questions/21219562/is-it-possible-to-remove-page-1-of-20-view-in-a-uiwebview-when-displaying-pd
    func hidePageNumberView(_ v: UIView) {
        for subView in v.subviews {
            if subView is UIImageView || subView is UILabel || subView is UIVisualEffectView {
                subView.isHidden = true

                if subView is UILabel {
                    if let sv = subView.superview {
                        sv.isHidden = true
                    }
                }
            } else {
                hidePageNumberView(subView)
            }
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.log.info("Finished displaying PDF in webview")
        for subview in webView.subviews {
            subview.clearBackgrounds()
        }
        hidePageNumberView(webView)
        self.webViewHeightConstraint.constant = webView.scrollView.contentSize.height
        self.activity.stopAnimating()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        log.error(error)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        for subview in webView.subviews {
            subview.clearBackgrounds()
        }
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        for subview in webView.subviews {
            subview.clearBackgrounds()
        }
    }

}
