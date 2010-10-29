//
//  RoundedRectangleView.h
//  MFA Guide
//
//  Created by Robert Brecher on 10/5/10.
//  Copyright 2010 Genuine Interactive. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface RoundedRectangleView : UIView {
	int radius;
	UIColor *fill;
}

@property (nonatomic, assign) int radius;
@property (nonatomic, retain) UIColor *fill;

@end
