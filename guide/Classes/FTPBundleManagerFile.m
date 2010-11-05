//
//  FTPBundleManagerFile.m
//  MFA Guide
//
//  Created by Robert Brecher on 9/22/10.
//  Copyright 2010 Genuine Interactive. All rights reserved.
//

#import "FTPBundleManagerFile.h"


@implementation FTPBundleManagerFile

@synthesize filename, path, size, modificationDate;

- (id)initWithFilename:(NSString *)theFilename path:(NSString *)thePath size:(NSNumber *)theSize modificationDate:(NSDate *)theModificationDate
{
	if ((self = [super init])) {
		[self setFilename:theFilename];
		[self setPath:thePath];
		[self setSize:theSize];
		[self setModificationDate:theModificationDate];
	}
	return self;
}

- (void)dealloc
{
	[filename release];
	[path release];
	[modificationDate release];
	[super dealloc];
}

@end
