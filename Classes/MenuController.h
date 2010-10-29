//
//  MenuController.h
//  MFA Guide
//
//  Created by Robert Brecher on 9/20/10.
//  Copyright 2010 Genuine Interactive. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MenuController : UIViewController {
	IBOutlet UINavigationBar *navigationBar;
	IBOutlet UITableView *toursView;
	NSArray *tours;
}

@property (nonatomic, retain) NSArray *tours;

- (void)refresh;

@end
