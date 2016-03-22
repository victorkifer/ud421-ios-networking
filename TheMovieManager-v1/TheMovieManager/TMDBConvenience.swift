//
//  TMDBConvenience.swift
//  TheMovieManager
//
//  Created by Jarrod Parkes on 2/11/15.
//  Copyright (c) 2015 Jarrod Parkes. All rights reserved.
//

import UIKit
import Foundation

// MARK: - TMDBClient (Convenient Resource Methods)

extension TMDBClient {
    
    // MARK: Authentication (GET) Methods
    /*
        Steps for Authentication...
        https://www.themoviedb.org/documentation/api/sessions
        
        Step 1: Create a new request token
        Step 2a: Ask the user for permission via the website
        Step 3: Create a session ID
        Bonus Step: Go ahead and get the user id 😄!
    */
    func authenticateWithViewController(hostViewController: UIViewController, completionHandlerForAuth: (success: Bool, errorString: String?) -> Void) {
        
        // chain completion handlers for each request so that they run one after the other
        getRequestToken() { (success, requestToken, errorString) in
            
            if success {
                
                // success! we have the requestToken!
                print(requestToken)
                self.requestToken = requestToken
                
                self.loginWithToken(requestToken, hostViewController: hostViewController) { (success, errorString) in
                    
                    if success {
                        self.getSessionID(requestToken) { (success, sessionID, errorString) in
                            
                            if success {
                                
                                // success! we have the sessionID!
                                self.sessionID = sessionID
                                
                                self.getUserID() { (success, userID, errorString) in
                                    
                                    if success {
                                        
                                        if let userID = userID {
                                            
                                            // and the userID 😄!
                                            self.userID = userID
                                        }
                                    }
                                    
                                    completionHandlerForAuth(success: success, errorString: errorString)
                                }
                            } else {
                                completionHandlerForAuth(success: success, errorString: errorString)
                            }
                        }
                    } else {
                        completionHandlerForAuth(success: success, errorString: errorString)
                    }
                }
            } else {
                completionHandlerForAuth(success: success, errorString: errorString)
            }
        }
    }
    
    private func getRequestToken(completionHandlerForToken: (success: Bool, requestToken: String?, errorString: String?) -> Void) {
        
        let parameters : [String: AnyObject] = [:];
        
        TMDBClient.sharedInstance().taskForGETMethod(TMDBClient.Methods.AuthenticationTokenNew, parameters: parameters) {
            (result, error) in
            
            func sendError(error: String) {
                completionHandlerForToken(success: false, requestToken: nil, errorString: error);
                return
            }
            
            if error != nil {
                sendError("\(error)")
                return
            }
            
            /* GUARD: Did TheMovieDB return an error? */
            if let _ = result[TMDBClient.JSONResponseKeys.StatusCode] as? Int {
                sendError("TheMovieDB returned an error. See the '\(TMDBClient.JSONResponseKeys.StatusCode)' and '\(TMDBClient.JSONResponseKeys.StatusMessage)' in \(result)")
                return
            }
            
            /* GUARD: Is the "request_token" key in parsedResult? */
            guard let requestToken = result[TMDBClient.JSONResponseKeys.RequestToken] as? String else {
                sendError("Cannot find key '\(TMDBClient.JSONResponseKeys.RequestToken)' in \(result)")
                return
            }
            
            completionHandlerForToken(success: true, requestToken: requestToken, errorString: nil)
        };
    }
    
    private func loginWithToken(requestToken: String?, hostViewController: UIViewController, completionHandlerForLogin: (success: Bool, errorString: String?) -> Void) {
        
        let authorizationURL = NSURL(string: "\(TMDBClient.Constants.AuthorizationURL)\(requestToken!)")
        let request = NSURLRequest(URL: authorizationURL!)
        let webAuthViewController = hostViewController.storyboard!.instantiateViewControllerWithIdentifier("TMDBAuthViewController") as! TMDBAuthViewController
        webAuthViewController.urlRequest = request
        webAuthViewController.requestToken = requestToken
        webAuthViewController.completionHandlerForView = completionHandlerForLogin
        
        let webAuthNavigationController = UINavigationController()
        webAuthNavigationController.pushViewController(webAuthViewController, animated: false)
        
        performUIUpdatesOnMain {
            hostViewController.presentViewController(webAuthNavigationController, animated: true, completion: nil)
        }
    }
    
    private func getSessionID(requestToken: String?, completionHandlerForSession: (success: Bool, sessionID: String?, errorString: String?) -> Void) {
        
        let parameters : [ String: AnyObject ] = [
            TMDBClient.ParameterKeys.RequestToken: requestToken!
        ]
        
        TMDBClient.sharedInstance().taskForGETMethod(TMDBClient.Methods.AuthenticationSessionNew, parameters: parameters) {
            (result, error) in
            
            func sendError(error: String) {
                completionHandlerForSession(success: false, sessionID: nil, errorString: error);
                return
            }
            
            if error != nil {
                sendError("\(error)")
                return
            }
            
            /* GUARD: Did TheMovieDB return an error? */
            if let _ = result[TMDBClient.JSONResponseKeys.StatusCode] as? Int {
                sendError("TheMovieDB returned an error. See the '\(TMDBClient.JSONResponseKeys.StatusCode)' and '\(TMDBClient.JSONResponseKeys.StatusMessage)' in \(result)")
                return
            }
            
            /* GUARD: Is the "sessionID" key in parsedResult? */
            guard let sessionID = result[TMDBClient.JSONResponseKeys.SessionID] as? String else {
                sendError("Cannot find key '\(TMDBClient.JSONResponseKeys.SessionID)' in \(result)")
                return
            }
            
            completionHandlerForSession(success: true, sessionID: sessionID, errorString: nil)
        };
    }
    
    private func getUserID(completionHandlerForUserID: (success: Bool, userID: Int?, errorString: String?) -> Void) {
        
        let parameters : [ String: AnyObject ] = [
            TMDBClient.ParameterKeys.SessionID: TMDBClient.sharedInstance().sessionID!
        ]
        
        
        TMDBClient.sharedInstance().taskForGETMethod(TMDBClient.Methods.Account, parameters: parameters) {
            (result, error) in
            
            func sendError(error: String) {
                completionHandlerForUserID(success: false, userID: nil, errorString: error);
                return
            }
            
            if error != nil {
                sendError("\(error)")
                return
            }
            
            /* GUARD: Did TheMovieDB return an error? */
            if let _ = result[TMDBClient.JSONResponseKeys.StatusCode] as? Int {
                sendError("TheMovieDB returned an error. See the '\(TMDBClient.JSONResponseKeys.StatusCode)' and '\(TMDBClient.JSONResponseKeys.StatusMessage)' in \(result)")
                return
            }
            
            /* GUARD: Is the "sessionID" key in parsedResult? */
            guard let userID = result[TMDBClient.JSONResponseKeys.UserID] as? Int else {
                sendError("Cannot find key '\(TMDBClient.JSONResponseKeys.UserID)' in \(result)")
                return
            }
            
            completionHandlerForUserID(success: true, userID: userID, errorString: nil)
        };
    }
    
    // MARK: GET Convenience Methods
    
    func getFavoriteMovies(completionHandlerForFavMovies: (result: [TMDBMovie]?, error: NSError?) -> Void) {
        
        /* 1. Specify parameters, the API method, and the HTTP body (if POST) */
        /* 2. Make the request */
        /* 3. Send the desired value(s) to completion handler */
        
    }
    
    func getWatchlistMovies(completionHandlerForWatchlist: (result: [TMDBMovie]?, error: NSError?) -> Void) {
        
        /* 1. Specify parameters, the API method, and the HTTP body (if POST) */
        /* 2. Make the request */
        /* 3. Send the desired value(s) to completion handler */
        
    }
    
    func getMoviesForSearchString(searchString: String, completionHandlerForMovies: (result: [TMDBMovie]?, error: NSError?) -> Void) -> NSURLSessionDataTask? {
        
        /* 1. Specify parameters, the API method, and the HTTP body (if POST) */
        /* 2. Make the request */
        /* 3. Send the desired value(s) to completion handler */
        return nil
    }
    
    func getConfig(completionHandlerForConfig: (didSucceed: Bool, error: NSError?) -> Void) {
        
        /* 1. Specify parameters, the API method, and the HTTP body (if POST) */
        /* 2. Make the request */
        /* 3. Send the desired value(s) to completion handler */
        
    }
    
    // MARK: POST Convenience Methods
    
    func postToFavorites(movie: TMDBMovie, favorite: Bool, completionHandlerForFavorite: (result: Int?, error: NSError?) -> Void)  {
        
        /* 1. Specify parameters, the API method, and the HTTP body (if POST) */
        /* 2. Make the request */
        /* 3. Send the desired value(s) to completion handler */
        
    }
    
    func postToWatchlist(movie: TMDBMovie, watchlist: Bool, completionHandlerForWatchlist: (result: Int?, error: NSError?) -> Void) {
        
        /* 1. Specify parameters, the API method, and the HTTP body (if POST) */
        /* 2. Make the request */
        /* 3. Send the desired value(s) to completion handler */
        
    }
}