//
//  UpdaterController.h
//  MFA Guide
//
//  Created by Robert Brecher on 9/20/10.
//  Copyright 2010 Genuine Interactive. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "RoundedRectangleView.h"
#import "Updater.h"

@interface UpdaterController : UIViewController <UpdaterDelegate, UIAlertViewDelegate, UITableViewDataSource, UITableViewDelegate> {
	
	IBOutlet UIBarButtonItem *backButton;
	IBOutlet UIBarButtonItem *utilityButton;
	
	IBOutlet UIBarButtonItem *toggleButton;
	IBOutlet UIView *currentViewContainer;
	UIView *currentView;
	
	IBOutlet UITableView *toursView;
	NSMutableArray *tours;
	NSMutableArray *availableTours;
	NSString *currentBundle;
	
	IBOutlet UITextView *consoleView;
	
	IBOutlet RoundedRectangleView *progress;
	IBOutlet UILabel *progressFilename;
	IBOutlet UILabel *progressAmount;
	IBOutlet UIProgressView *progressView;
	
	Updater *updater;
}

@property (nonatomic, retain) IBOutlet UIView *currentViewContainer;
@property (nonatomic, retain) UIView *currentView;

@property (nonatomic, retain) NSMutableArray *tours;
@property (nonatomic, retain) NSMutableArray *availableTours;
@property (nonatomic, retain) NSString *currentBundle;

@property (nonatomic, retain) Updater *updater;

- (IBAction)backSelected:(id)sender;
- (IBAction)utilityButtonSelected:(id)sender;
- (IBAction)toggleDisplay:(id)sender;

@end
