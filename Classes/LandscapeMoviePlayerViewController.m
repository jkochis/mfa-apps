//
//  LandscapeMoviePlayerViewController.m
//  MFA Guide
//
//  Created by Robert Brecher on 10/5/10.
//  Copyright 2010 Genuine Interactive. All rights reserved.
//

#import "LandscapeMoviePlayerViewController.h"


@implementation LandscapeMoviePlayerViewController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft ||
		toInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
		return YES;
	}
	return NO;
}

@end
