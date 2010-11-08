//
//  MFAUpdaterAppDelegate.h
//  MFAUpdater
//
//  Created by Robert Brecher on 10/21/10.
//  Copyright 2010 Genuine Interactive. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MFAUpdaterViewController;

@interface MFAUpdaterAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    MFAUpdaterViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet MFAUpdaterViewController *viewController;

@end

