//
//  LoadingView.m
//  MFA Guide
//
//  Created by Robert Brecher on 10/30/10.
//  Copyright 2010 Genuine Interactive. All rights reserved.
//

#import "LoadingView.h"


@implementation LoadingView


- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self setOpaque:NO];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
	CGContextRef c = UIGraphicsGetCurrentContext();
    if (c != nil) {
		CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
		CGFloat locations[2] = {0.0f, 0.75f};
		CGFloat components[8] = {0.0f, 0.0f, 0.0f, 0.125f,
			0.0f, 0.0f, 0.0f, 0.5f};
		CGGradientRef gradientRef = CGGradientCreateWithColorComponents(colorSpaceRef, components, locations, 2);
		CGPoint startPoint, endPoint;
		startPoint.x = rect.origin.x + rect.size.width / 2;
		startPoint.y = rect.origin.y + rect.size.height / 2;
		endPoint.x = rect.origin.x + rect.size.width / 2;
		endPoint.y = rect.origin.y + rect.size.height / 2;
		CGContextDrawRadialGradient(c, gradientRef, startPoint, 0.0f, endPoint, rect.size.width, 0);
		CGColorSpaceRelease(colorSpaceRef);
		CGGradientRelease(gradientRef);
	}
}

- (void)dealloc {
    [super dealloc];
}


@end
