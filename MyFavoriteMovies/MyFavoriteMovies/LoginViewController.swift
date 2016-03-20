//
//  LoginViewController.swift
//  MyFavoriteMovies
//
//  Created by Jarrod Parkes on 1/23/15.
//  Copyright (c) 2015 Udacity. All rights reserved.
//

import UIKit
import Alamofire

// MARK: - LoginViewController: UIViewController

class LoginViewController: UIViewController {
    
    // MARK: Properties
    
    var appDelegate: AppDelegate!
    var keyboardOnScreen = false
    
    // MARK: Outlets
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: BorderedButton!
    @IBOutlet weak var debugTextLabel: UILabel!
    @IBOutlet weak var movieImageView: UIImageView!
        
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // get the app delegate
        appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate                        
        
        configureUI()
        
        subscribeToNotification(UIKeyboardWillShowNotification, selector: Constants.Selectors.KeyboardWillShow)
        subscribeToNotification(UIKeyboardWillHideNotification, selector: Constants.Selectors.KeyboardWillHide)
        subscribeToNotification(UIKeyboardDidShowNotification, selector: Constants.Selectors.KeyboardDidShow)
        subscribeToNotification(UIKeyboardDidHideNotification, selector: Constants.Selectors.KeyboardDidHide)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromAllNotifications()
    }
    
    // MARK: Login
    
    @IBAction func loginPressed(sender: AnyObject) {
        
        userDidTapView(self)
        
        if usernameTextField.text!.isEmpty || passwordTextField.text!.isEmpty {
            debugTextLabel.text = "Username or Password Empty."
        } else {
            setUIEnabled(false)
            getRequestToken()
        }
    }
    
    private func completeLogin() {
        performUIUpdatesOnMain {
            self.debugTextLabel.text = ""
            self.setUIEnabled(true)
            let controller = self.storyboard!.instantiateViewControllerWithIdentifier("MoviesTabBarController") as! UITabBarController
            self.presentViewController(controller, animated: true, completion: nil)
        }
    }
    
    // MARK: TheMovieDB
    
    private func getRequestToken() {
        let methodParameters = [
            Constants.TMDBParameterKeys.ApiKey: Constants.TMDBParameterValues.ApiKey
        ]
        
        Alamofire.request(.GET, appDelegate.tmdbURLFromParameters(methodParameters, withPathExtension: "/authentication/token/new")).responseJSON { response in
            
            func displayError(error: String) {
                print(error)
                performUIUpdatesOnMain {
                    self.setUIEnabled(true)
                    self.debugTextLabel.text = "Request has failed"
                }
            }
            
            if response.result.error != nil {
                displayError("\(response.result.error)")
                return
            }
            
            guard let JSON = response.result.value else {
                displayError("Cannot parse JSON data")
                return
            }
            
            if let statusCode = JSON[Constants.TMDBResponseKeys.StatusCode] as? Int {
                if statusCode != 0 {
                    if let statusMessage = JSON[Constants.TMDBResponseKeys.StatusMessage] as? String {
                        displayError(statusMessage)
                    } else {
                        displayError("Unknown error with code \(statusCode)")
                    }
                    return
                }
            }
            
            guard let requestToken = JSON[Constants.TMDBResponseKeys.RequestToken] as? String else {
                displayError("Cannot find requestToken in \(JSON)")
                return
            }
            
            print("Got requestToken = \(requestToken)")
            self.appDelegate.requestToken = requestToken
            
            self.loginWithToken(requestToken)
        }
    }
    
    private func loginWithToken(requestToken: String) {
        let methodParameters = [
            Constants.TMDBParameterKeys.ApiKey: Constants.TMDBParameterValues.ApiKey,
            Constants.TMDBParameterKeys.RequestToken: requestToken,
            Constants.TMDBParameterKeys.Username: usernameTextField.text!,
            Constants.TMDBParameterKeys.Password: passwordTextField.text!
        ];
        
        Alamofire.request(.GET, appDelegate.tmdbURLFromParameters(methodParameters, withPathExtension: "/authentication/token/validate_with_login")).responseJSON { response in
            
            func displayError(error: String) {
                print(error)
                performUIUpdatesOnMain {
                    self.setUIEnabled(true)
                    self.debugTextLabel.text = "Request has failed"
                }
            }
            
            if response.result.error != nil {
                displayError("\(response.result.error)");
                return;
            }
            
            guard let JSON = response.result.value else {
                displayError("Cannot parse JSON data");
                return;
            }
            
            if let statusCode = JSON[Constants.TMDBResponseKeys.StatusCode] as? Int {
                if statusCode != 0 {
                    if let statusMessage = JSON[Constants.TMDBResponseKeys.StatusMessage] as? String {
                        displayError(statusMessage)
                    } else {
                        displayError("Unknown error with code \(statusCode)")
                    }
                    return
                }
            }
            
            self.getSessionID(self.appDelegate.requestToken!)
        }
    }
    
    private func getSessionID(requestToken: String) {
        let methodParameters = [
            Constants.TMDBParameterKeys.ApiKey: Constants.TMDBParameterValues.ApiKey,
            Constants.TMDBParameterKeys.RequestToken: requestToken        ];
        
        Alamofire.request(.GET, appDelegate.tmdbURLFromParameters(methodParameters, withPathExtension: "/authentication/session/new")).responseJSON { response in
            
            func displayError(error: String) {
                print(error)
                performUIUpdatesOnMain {
                    self.setUIEnabled(true)
                    self.debugTextLabel.text = "Request has failed"
                }
            }
            
            if response.result.error != nil {
                displayError("\(response.result.error)");
                return;
            }
            
            guard let JSON = response.result.value else {
                displayError("Cannot parse JSON data");
                return;
            }
            
            if let statusCode = JSON[Constants.TMDBResponseKeys.StatusCode] as? Int {
                if statusCode != 0 {
                    if let statusMessage = JSON[Constants.TMDBResponseKeys.StatusMessage] as? String {
                        displayError(statusMessage)
                    } else {
                        displayError("Unknown error with code \(statusCode)")
                    }
                    return
                }
            }
            
            guard let sessionID = JSON[Constants.TMDBResponseKeys.SessionID] as? String else {
                displayError("Cannot find sessionID in \(JSON)");
                return;
            }
            
            print("Got sessionID = \(sessionID)")
            self.appDelegate.sessionID = sessionID
            
            self.getUserID(sessionID)
        }
    }
    
    private func getUserID(sessionID: String) {
        let methodParameters = [
            Constants.TMDBParameterKeys.ApiKey: Constants.TMDBParameterValues.ApiKey,
            Constants.TMDBParameterKeys.SessionID: sessionID
        ];
        
        Alamofire.request(.GET, appDelegate.tmdbURLFromParameters(methodParameters, withPathExtension: "/account")).responseJSON { response in
            
            func displayError(error: String) {
                print(error)
                performUIUpdatesOnMain {
                    self.setUIEnabled(true)
                    self.debugTextLabel.text = "Request has failed"
                }
            }
            
            if response.result.error != nil {
                displayError("\(response.result.error)");
                return;
            }
            
            guard let JSON = response.result.value else {
                displayError("Cannot parse JSON data");
                return;
            }
            
            if let statusCode = JSON[Constants.TMDBResponseKeys.StatusCode] as? Int {
                if statusCode != 0 {
                    if let statusMessage = JSON[Constants.TMDBResponseKeys.StatusMessage] as? String {
                        displayError(statusMessage)
                    } else {
                        displayError("Unknown error with code \(statusCode)")
                    }
                    return
                }
            }
            
            guard let userID = JSON[Constants.TMDBResponseKeys.UserID] as? Int else {
                displayError("Cannot find userID in \(JSON)");
                return;
            }
            
            print("Got userID = \(userID)")
            self.appDelegate.userID = userID
            
            self.completeLogin()
        }
    }
}

// MARK: - LoginViewController: UITextFieldDelegate

extension LoginViewController: UITextFieldDelegate {
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: Show/Hide Keyboard
    
    func keyboardWillShow(notification: NSNotification) {
        if !keyboardOnScreen {
            view.frame.origin.y -= keyboardHeight(notification)
            movieImageView.hidden = true
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if keyboardOnScreen {
            view.frame.origin.y += keyboardHeight(notification)
            movieImageView.hidden = false
        }
    }
    
    func keyboardDidShow(notification: NSNotification) {
        keyboardOnScreen = true
    }
    
    func keyboardDidHide(notification: NSNotification) {
        keyboardOnScreen = false
    }
    
    private func keyboardHeight(notification: NSNotification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.CGRectValue().height
    }
    
    private func resignIfFirstResponder(textField: UITextField) {
        if textField.isFirstResponder() {
            textField.resignFirstResponder()
        }
    }
    
    @IBAction func userDidTapView(sender: AnyObject) {
        resignIfFirstResponder(usernameTextField)
        resignIfFirstResponder(passwordTextField)
    }
}

// MARK: - LoginViewController (Configure UI)

extension LoginViewController {
    
    private func setUIEnabled(enabled: Bool) {
        usernameTextField.enabled = enabled
        passwordTextField.enabled = enabled
        loginButton.enabled = enabled
        debugTextLabel.text = ""
        debugTextLabel.enabled = enabled
        
        // adjust login button alpha
        if enabled {
            loginButton.alpha = 1.0
        } else {
            loginButton.alpha = 0.5
        }
    }
    
    private func configureUI() {
        
        // configure background gradient
        let backgroundGradient = CAGradientLayer()
        backgroundGradient.colors = [Constants.UI.LoginColorTop, Constants.UI.LoginColorBottom]
        backgroundGradient.locations = [0.0, 1.0]
        backgroundGradient.frame = view.frame
        view.layer.insertSublayer(backgroundGradient, atIndex: 0)
        
        configureTextField(usernameTextField)
        configureTextField(passwordTextField)
    }
    
    private func configureTextField(textField: UITextField) {
        let textFieldPaddingViewFrame = CGRectMake(0.0, 0.0, 13.0, 0.0)
        let textFieldPaddingView = UIView(frame: textFieldPaddingViewFrame)
        textField.leftView = textFieldPaddingView
        textField.leftViewMode = .Always
        textField.backgroundColor = Constants.UI.GreyColor
        textField.textColor = Constants.UI.BlueColor
        textField.attributedPlaceholder = NSAttributedString(string: textField.placeholder!, attributes: [NSForegroundColorAttributeName: UIColor.whiteColor()])
        textField.tintColor = Constants.UI.BlueColor
        textField.delegate = self
    }
}

// MARK: - LoginViewController (Notifications)

extension LoginViewController {
    
    private func subscribeToNotification(notification: String, selector: Selector) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: selector, name: notification, object: nil)
    }
    
    private func unsubscribeFromAllNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}