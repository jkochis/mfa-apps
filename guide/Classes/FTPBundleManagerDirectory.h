//
//  FTPBundleManagerDirectory.h
//  MFA Guide
//
//  Created by Robert Brecher on 9/22/10.
//  Copyright 2010 Genuine Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface FTPBundleManagerDirectory : NSObject {
	NSString *directory;
	NSString *path;
}

@property (nonatomic, retain) NSString *directory;
@property (nonatomic, retain) NSString *path;

- (id)initWithDirectory:(NSString *)theDirectory path:(NSString *)thePath;

@end
