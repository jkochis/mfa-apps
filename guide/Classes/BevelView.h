//
//  BevelView.h
//  MFA Guide
//
//  Created by Robert Brecher on 10/5/10.
//  Copyright 2010 Genuine Interactive. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface BevelView : UIView {
	UIColor *fill;
	UIColor *bevel;
	BOOL flipped;
}

@property (nonatomic, retain) UIColor *fill;
@property (nonatomic, retain) UIColor *bevel;
@property (nonatomic, assign) BOOL flipped;

@end
