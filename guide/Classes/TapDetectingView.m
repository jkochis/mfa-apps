//
//  TapDetectingView.m
//  MFA Guide
//
//  Created by Robert Brecher on 10/22/10.
//  Copyright 2010 Genuine Interactive. All rights reserved.
//

#import "TapDetectingView.h"
#import "TapDetectingImageView.h"

#define DOUBLE_TAP_DELAY 0.35

@interface TapDetectingView (PrivateMethods)

- (void)handleSingleTap;
- (void)handleDoubleTap;
- (void)handleTwoFingerTap;
- (CGPoint)midpointBetweenPoint:(CGPoint)a andPoint:(CGPoint)b;

@end

@implementation TapDetectingView

@synthesize delegate;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
		[self setUserInteractionEnabled:YES];
        [self setMultipleTouchEnabled:YES];
        twoFingerTapIsPossible = YES;
        multipleTouches = NO;
    }
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    // cancel any pending handleSingleTap messages 
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(handleSingleTap) object:nil];
    
    // update our touch state
    if ([[event touchesForView:self] count] > 1)
        multipleTouches = YES;
    if ([[event touchesForView:self] count] > 2)
        twoFingerTapIsPossible = NO;
    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    BOOL allTouchesEnded = ([touches count] == [[event touchesForView:self] count]);
    
    // first check for plain single/double tap, which is only possible if we haven't seen multiple touches
    if (!multipleTouches) {
        UITouch *touch = [touches anyObject];
        tapLocation = [touch locationInView:self];
        
        if ([touch tapCount] == 1) {
            [self performSelector:@selector(handleSingleTap) withObject:nil afterDelay:DOUBLE_TAP_DELAY];
        } else if([touch tapCount] == 2) {
            [self handleDoubleTap];
        }
    }    
    
    // check for 2-finger tap if we've seen multiple touches and haven't yet ruled out that possibility
    else if (multipleTouches && twoFingerTapIsPossible) { 
        
        // case 1: this is the end of both touches at once 
        if ([touches count] == 2 && allTouchesEnded) {
            int i = 0; 
            int tapCounts[2]; CGPoint tapLocations[2];
            for (UITouch *touch in touches) {
                tapCounts[i]    = [touch tapCount];
                tapLocations[i] = [touch locationInView:self];
                i++;
            }
            if (tapCounts[0] == 1 && tapCounts[1] == 1) { // it's a two-finger tap if they're both single taps
				tapLocation = [self midpointBetweenPoint:tapLocations[0] andPoint:tapLocations[1]];
                [self handleTwoFingerTap];
            }
        }
        
        // case 2: this is the end of one touch, and the other hasn't ended yet
        else if ([touches count] == 1 && !allTouchesEnded) {
            UITouch *touch = [touches anyObject];
            if ([touch tapCount] == 1) {
                // if touch is a single tap, store its location so we can average it with the second touch location
                tapLocation = [touch locationInView:self];
            } else {
                twoFingerTapIsPossible = NO;
            }
        }
		
        // case 3: this is the end of the second of the two touches
        else if ([touches count] == 1 && allTouchesEnded) {
            UITouch *touch = [touches anyObject];
            if ([touch tapCount] == 1) {
                // if the last touch up is a single tap, this was a 2-finger tap
				tapLocation = [self midpointBetweenPoint:tapLocation andPoint:[touch locationInView:self]];
                [self handleTwoFingerTap];
            }
        }
    }
	
    // if all touches are up, reset touch monitoring state
    if (allTouchesEnded) {
        twoFingerTapIsPossible = YES;
        multipleTouches = NO;
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    twoFingerTapIsPossible = YES;
    multipleTouches = NO;
}

#pragma mark Private

- (void)handleSingleTap {
    if ([delegate respondsToSelector:@selector(tapDetectingView:gotSingleTapAtPoint:)])
        [delegate tapDetectingView:self gotSingleTapAtPoint:tapLocation];
}

- (void)handleDoubleTap {
    if ([delegate respondsToSelector:@selector(tapDetectingView:gotDoubleTapAtPoint:)])
        [delegate tapDetectingView:self gotDoubleTapAtPoint:tapLocation];
}

- (void)handleTwoFingerTap {
    if ([delegate respondsToSelector:@selector(tapDetectingView:gotTwoFingerTapAtPoint:)])
        [delegate tapDetectingView:self gotTwoFingerTapAtPoint:tapLocation];
}

- (CGPoint)midpointBetweenPoint:(CGPoint)a andPoint:(CGPoint)b
{
	CGFloat x = (a.x + b.x) / 2.0;
    CGFloat y = (a.y + b.y) / 2.0;
    return CGPointMake(x, y);
}

@end
