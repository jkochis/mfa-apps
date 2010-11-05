//
//  FTPBundleManagerDirectory.m
//  MFA Guide
//
//  Created by Robert Brecher on 9/22/10.
//  Copyright 2010 Genuine Interactive. All rights reserved.
//

#import "FTPBundleManagerDirectory.h"


@implementation FTPBundleManagerDirectory

@synthesize directory, path;

- (id)initWithDirectory:(NSString *)theDirectory path:(NSString *)thePath
{
	if ((self = [super init])) {
		[self setDirectory:theDirectory];
		[self setPath:thePath];
	}
	return self;
}

- (void)dealloc
{
	[directory release];
	[path release];
	[super dealloc];
}

@end
