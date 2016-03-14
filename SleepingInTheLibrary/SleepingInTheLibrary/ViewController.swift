//
//  ViewController.swift
//  SleepingInTheLibrary
//
//  Created by Jarrod Parkes on 11/3/15.
//  Copyright © 2015 Udacity. All rights reserved.
//

import UIKit

// MARK: - ViewController: UIViewController

class ViewController: UIViewController {
    
    // MARK: Outlets
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var photoTitleLabel: UILabel!
    @IBOutlet weak var grabImageButton: UIButton!
    
    // MARK: Actions
    
    @IBAction func grabNewImage(sender: AnyObject) {
        setUIEnabled(false)
        getImageFromFlickr()
    }
    
    // MARK: Configure UI
    
    private func setUIEnabled(enabled: Bool) {
        photoTitleLabel.enabled = enabled
        grabImageButton.enabled = enabled
        
        if enabled {
            grabImageButton.alpha = 1.0
        } else {
            grabImageButton.alpha = 0.5
        }
    }
    
    // MARK: Make Network Request
    
    private func getImageFromFlickr() {
        let parameters = [
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.GalleryID: Constants.FlickrParameterValues.GalleryID,
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.GalleryPhotosMethod,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback
        ]
        
        let urlString = Constants.Flickr.APIBaseURL + escapeParameters(parameters)
        let url = NSURL(string: urlString)!
        let urlRequest = NSURLRequest(URL: url)
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(urlRequest) {
            (data, response, error) in
            
            if error != nil {
                self.displayError("\(error)")
                return
            }
            
            guard let data = data else {
                self.displayError("No data received")
                return
            }
            
            
            let parsedData: AnyObject!
            do {
                parsedData = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                self.displayError("Could not parse data \(data)")
                return
            }
            
            guard let photosDict = parsedData[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                self.displayError("Cannot find \(Constants.FlickrResponseKeys.Photos)")
                return
            }
            
            let photoArr = photosDict[Constants.FlickrResponseKeys.Photo] as? [[String:AnyObject]]
            
            let photoIndex = Int(arc4random_uniform(UInt32(photoArr!.count)))
            let photo = photoArr![photoIndex] as [String:AnyObject]
            
            guard let imageUrlString = photo[Constants.FlickrResponseKeys.MediumURL] as? String,
                let photoTitle = photo[Constants.FlickrResponseKeys.Title] as? String else {
                    self.displayError("Cannot find image url or title")
                    return
            }
            
            self.photoImageView.loadUrl(imageUrlString)
            performUIUpdatesOnMain {
                self.photoTitleLabel.text = photoTitle
                self.setUIEnabled(true)
            }
            
        }
        task.resume()
    }
    
    private func displayError(error: String) {
        print(error)
    }
    
    private func escapeParameters(parameters: [String:AnyObject]) -> String {
        if parameters.isEmpty {
            return ""
        }
        
        var keyValuePairs = [String]()
        
        for (key, value) in parameters {
            let stringValue = "\(value)"
            
            let escapeValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
            
            keyValuePairs.append(key + "=" + "\(escapeValue)")
        }
        
        return "?\(keyValuePairs.joinWithSeparator("&"))"
    }
}