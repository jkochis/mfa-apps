//
//  TourController.h
//  MFA Guide
//
//  Created by Robert Brecher on 9/15/10.
//  Copyright 2010 Genuine Interactive. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "BaseStop.h"
#import "TourMLUtils.h"

#define TOUR_WELCOME_STOP			@"103"
#define TOUR_HELP_STOP				@"105"
#define TOUR_MAP_STOP				@"109"

#define TAP_HELP_STOP				@"411"
#define TAP_HELP_VIDEO_CODE			@"41111"

#define TOUR_FILENAME				@"tour"

@interface TourController : UINavigationController <UINavigationControllerDelegate> {
	
	NSBundle *tourBundle; // The bundle holding the tour
	xmlDocPtr tourDoc; // The parsed tour document
	
	UIImageView *helpBg;
	UIButton *helpButton;
	BOOL showingHelp;
}

@property (nonatomic, retain) NSBundle *tourBundle;
@property xmlDocPtr tourDoc;

- (BOOL)loadBundle:(NSString *)bundleName;
- (BOOL)loadStop:(BaseStop *)stop;
- (BOOL)loadStop:(BaseStop *)stop animated:(BOOL)animated;
- (void)showHelpButtonAnimated:(BOOL)animated;
- (void)hideHelpButtonAnimated:(BOOL)animated;

@end
