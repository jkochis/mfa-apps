//
//  MFAUpdaterViewController.h
//  MFAUpdater
//
//  Created by Robert Brecher on 10/21/10.
//  Copyright 2010 Genuine Interactive. All rights reserved.
//

#import <UIKit/UIKit.h>

#define UPDATER_URL @"http://mfa-newmedia/apps/tap/"

@interface MFAUpdaterViewController : UIViewController {
	IBOutlet UIWebView *webView;
}

@end

