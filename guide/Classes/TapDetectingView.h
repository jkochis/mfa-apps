//
//  TapDetectingView.h
//  MFA Guide
//
//  Created by Robert Brecher on 10/22/10.
//  Copyright 2010 Genuine Interactive. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TapDetectingViewDelegate;

@interface TapDetectingView : UIView {
	
	id <TapDetectingViewDelegate> delegate;
	
	CGPoint tapLocation;
    BOOL multipleTouches;
    BOOL twoFingerTapIsPossible;
}

@property (nonatomic, retain) id <TapDetectingViewDelegate> delegate;

@end

@protocol TapDetectingViewDelegate <NSObject>

@optional

- (void)tapDetectingView:(TapDetectingView *)view gotSingleTapAtPoint:(CGPoint)tapPoint;
- (void)tapDetectingView:(TapDetectingView *)view gotDoubleTapAtPoint:(CGPoint)tapPoint;
- (void)tapDetectingView:(TapDetectingView *)view gotTwoFingerTapAtPoint:(CGPoint)tapPoint;

@end